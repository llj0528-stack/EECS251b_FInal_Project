import csv
import math

import matplotlib.pyplot as plt
import numpy as np
from scipy import signal
from scipy.special import erfc

from ffe_golden_model import FFEGoldenModel

#Standard driven constraints. 
PAM5_LEVELS = np.array([-2, -1, 0, 1, 2], dtype=float)
SYMBOL_RATE_HZ = 125e6
BITS_PER_125_OCTET_FRAME = 125 * 8
IEEE_BER_TARGET = 1e-10
IEEE_FER_125_OCTET_TARGET = 1.0 - (1.0 - IEEE_BER_TARGET) ** BITS_PER_125_OCTET_FRAME

#Levers
SEED = 251 
SYMBOLS_PER_SNR = 500_000
SNR_START_DB = 8.0
SNR_STOP_DB = 40.0
SNR_STEP_DB = 2.0
CHANNEL_TAPS = 17
FFE_TAPS = 8
MMSE_DESIGN_SNR_DB = 24.0
INPUT_SCALE = 96.0
RESIDUAL_NOISE_DB = None
RESULTS_DIR = "EECS251b_FInal_Project_project_folder/reference_model/ffe/results"

FIELD_NAMES = [
    "scenario",
    "channel",
    "receiver",
    "equalizer",
    "requested_input_snr_db",
    "measured_input_snr_db",
    "measured_output_snr_db",
    "lane_symbol_error_rate",
    "vector_symbol_error_rate",
    "ber_proxy_empirical",
    "ber_proxy_analytic",
    "fer_125octet_proxy_empirical",
    "fer_125octet_proxy_analytic",
    "frame_4d_error_proxy_empirical",
    "residual_sigma",
    "slicer_gain",
    "alignment_delay_symbols",
    "aligned_symbols",
]

def clause40_insertion_loss_db(freq_hz):
    """insertion-loss limit, with f in MHz and valid 1-100 MHz."""
    freq_mhz = np.asarray(freq_hz, dtype=float) / 1e6
    freq_mhz = np.clip(np.abs(freq_mhz), 1.0, 100.0)
    return 2.1 * np.power(freq_mhz, 0.529) + 0.4 / freq_mhz

def build_clause40_channel(num_taps=CHANNEL_TAPS, sample_rate_hz=SYMBOL_RATE_HZ):
    """Build a one-sample-per-symbol minimum-phase FIR channel from the insertion-loss shape. Low-frequency gain is normalized to model AGC."""
    nyquist_hz = sample_rate_hz / 2.0
    freqs = np.linspace(0.0, nyquist_hz, 256)
    loss_db = clause40_insertion_loss_db(freqs)
    loss_db -= clause40_insertion_loss_db(np.array([1e6]))[0]
    gains = np.power(10.0, -loss_db / 20.0)
    gains[0] = 1.0

    linear_phase = signal.firwin2(num_taps, freqs, gains, fs=sample_rate_hz, window="hann")
    impulse = signal.minimum_phase(linear_phase, method="homomorphic")
    impulse = np.real_if_close(impulse).astype(float)
    impulse[np.abs(impulse) < 1e-15] = 0.0
    impulse /= np.sum(impulse)
    return impulse

def build_ideal_channel():
    return np.array([1.0], dtype=float)

def convolution_matrix(channel, taps):
    rows = len(channel) + taps - 1
    matrix = np.zeros((rows, taps), dtype=float)
    for tap in range(taps):
        matrix[tap : tap + len(channel), tap] = channel
    return matrix

def design_mmse_ffe(channel, taps=FFE_TAPS, design_snr_db=MMSE_DESIGN_SNR_DB):
    """Solve for an FFE that makes channel * FFE close to a delayed impulse"""
    matrix = convolution_matrix(channel, taps)
    regularizer = 1.0 / (10.0 ** (design_snr_db / 10.0))
    lhs = matrix.T @ matrix + regularizer * np.eye(taps)

    best_coeffs = None
    best_delay = 0
    best_mse = float("inf")
    for delay in range(matrix.shape[0]):
        target = np.zeros(matrix.shape[0], dtype=float)
        target[delay] = 1.0
        coeffs = np.linalg.solve(lhs, matrix.T @ target)
        residual = matrix @ coeffs - target
        mse = float(np.mean(residual**2) + regularizer * np.sum(coeffs**2))
        if mse < best_mse:
            best_mse = mse
            best_delay = delay
            best_coeffs = coeffs

    return best_coeffs, best_delay, best_mse

def quantize_coefficients(coeffs, coef_width=8):
    max_code = (1 << (coef_width - 1)) - 1
    min_code = -(1 << (coef_width - 1))
    max_abs = float(np.max(np.abs(coeffs)))
    scale = max(1, int(math.floor(max_code / max_abs))) if max_abs > 0.0 else 1
    quantized = np.rint(coeffs * scale).astype(int)
    quantized = np.clip(quantized, min_code, max_code)

    return quantized, scale

def pack_coefficients(coeffs, coef_width=8):
    mask = (1 << coef_width) - 1
    coeff_bus = 0
    for index, coeff in enumerate(coeffs):
        coeff_bus |= (int(coeff) & mask) << (index * coef_width)
    return coeff_bus

def generate_pam5_symbols(rng, n_symbols):
    return rng.choice(PAM5_LEVELS, size=(n_symbols, 4)).astype(float)

def apply_channel(symbols, channel):
    return signal.lfilter(channel, [1.0], symbols, axis=0)

def add_awgn(rng, clean_signal, snr_db, settle_symbols=128):
    active = clean_signal[settle_symbols:] if clean_signal.shape[0] > settle_symbols else clean_signal
    signal_power = float(np.mean(active**2))
    noise_power = signal_power / (10.0 ** (snr_db / 10.0))
    noise = rng.normal(0.0, math.sqrt(noise_power), size=clean_signal.shape)
    measured_snr = 10.0 * math.log10(signal_power / float(np.mean(noise[settle_symbols:] ** 2)))
    return clean_signal + noise, noise, measured_snr

def add_residual_crosstalk(rng, rx, symbols, residual_db):
    if residual_db is None:
        return rx
    signal_rms = math.sqrt(float(np.mean(rx[128:] ** 2)))
    residual_rms = signal_rms * (10.0 ** (-residual_db / 20.0))
    delayed = np.roll(symbols, shift=3, axis=0)
    mixed = np.empty_like(delayed)
    mixed[:, 0] = delayed[:, 1] - delayed[:, 2]
    mixed[:, 1] = delayed[:, 2] - delayed[:, 3]
    mixed[:, 2] = delayed[:, 3] - delayed[:, 0]
    mixed[:, 3] = delayed[:, 0] - delayed[:, 1]
    mixed /= max(math.sqrt(float(np.mean(mixed[128:] ** 2))), 1e-12)
    jitter = rng.normal(0.0, residual_rms * 0.05, size=rx.shape)
    return rx + residual_rms * mixed + jitter

def run_fixed_ffe(samples, coeff_ints, input_scale=INPUT_SCALE, din_width=10):
    gm = FFEGoldenModel(din_w=din_width, coef_w=8, taps=len(coeff_ints))
    coeff_bus = pack_coefficients(coeff_ints)
    max_code = (1 << (din_width - 1)) - 1
    min_code = -(1 << (din_width - 1))
    quantized = np.rint(samples * input_scale).astype(int)
    quantized = np.clip(quantized, min_code, max_code)
    #print("input min/max:", np.min(samples), np.max(samples))
    #print("quantized min/max:", np.min(quantized), np.max(quantized))
    #print("num clipped high:", np.sum(quantized == max_code))
    #print("num clipped low:", np.sum(quantized == min_code))
    
    gm.step(True, 0, 1, 0, 0, 0, 0, 0, coeff_bus)
    outputs = np.zeros_like(samples, dtype=float)
    for row_index, row in enumerate(quantized):
        o0, o1, o2, o3, _ovalid = gm.step(
            True,
            1,
            1,
            int(row[0]),
            int(row[1]),
            int(row[2]),
            int(row[3]),
            1,
            coeff_bus,
        )
        outputs[row_index] = (o0, o1, o2, o3)
    return outputs

def apply_float_ffe(samples, coeffs):
    return signal.lfilter(coeffs, [1.0], samples, axis=0)

def fit_gain(observed, reference):
    denom = float(np.sum(reference**2))
    if denom <= 0.0:
        return 1.0
    return float(np.sum(observed * reference) / denom)

def align_and_score(observed, reference, max_delay=80, settle_symbols=160):
    best_delay = 0
    best_gain = 1.0
    best_mse = float("inf")

    for delay in range(max_delay + 1):
        n = min(reference.shape[0], observed.shape[0] - delay)
        if n <= settle_symbols + 1:
            continue
        ref_slice = reference[:n]
        obs_slice = observed[delay : delay + n]
        ref_active = ref_slice[settle_symbols:]
        obs_active = obs_slice[settle_symbols:]
        gain = fit_gain(obs_active, ref_active)
        if abs(gain) < 1e-12:
            continue
        residual = obs_active / gain - ref_active
        mse = float(np.mean(residual**2))
        if mse < best_mse:
            best_mse = mse
            best_delay = delay
            best_gain = gain

    n = min(reference.shape[0], observed.shape[0] - best_delay)
    ref_aligned = reference[:n][settle_symbols:]
    obs_aligned = observed[best_delay : best_delay + n][settle_symbols:]
    normalized = obs_aligned / best_gain
    residual = normalized - ref_aligned

    level_distance = np.abs(normalized[..., None] - PAM5_LEVELS)
    decisions = PAM5_LEVELS[np.argmin(level_distance, axis=-1)]
    errors = decisions != ref_aligned

    lane_ser = float(np.mean(errors))
    vector_ser = float(np.mean(np.any(errors, axis=1)))
    ber_proxy = lane_ser
    fer_proxy = 1.0 - (1.0 - ber_proxy) ** BITS_PER_125_OCTET_FRAME
    frame_4d_proxy = 1.0 - (1.0 - vector_ser) ** 125
    residual_sigma = math.sqrt(float(np.mean(residual**2)))

    if residual_sigma <= 0.0:
        analytic_lane_ser = 0.0
    else:
        q_arg = 0.5 / residual_sigma
        q_val = 0.5 * float(erfc(q_arg / math.sqrt(2.0)))
        analytic_lane_ser = min(1.0, 1.6 * q_val)
        #print(f"q_arg={q_arg:.6g}, q_val={q_val:.6e}")
    analytic_ber = analytic_lane_ser
    analytic_fer = 1.0 - (1.0 - analytic_ber) ** BITS_PER_125_OCTET_FRAME

    signal_power = float(np.mean(ref_aligned**2))
    residual_power = max(float(np.mean(residual**2)), 1e-300)
    output_snr_db = 10.0 * math.log10(signal_power / residual_power)

    metrics = {
        "measured_output_snr_db": output_snr_db,
        "lane_symbol_error_rate": lane_ser,
        "vector_symbol_error_rate": vector_ser,
        "ber_proxy_empirical": ber_proxy,
        "ber_proxy_analytic": analytic_ber,
        "fer_125octet_proxy_empirical": fer_proxy,
        "fer_125octet_proxy_analytic": analytic_fer,
        "frame_4d_error_proxy_empirical": frame_4d_proxy,
        "residual_sigma": residual_sigma,
        "slicer_gain": best_gain,
        "alignment_delay_symbols": best_delay,
        "aligned_symbols": int(ref_aligned.shape[0]),
    }
    return metrics, ref_aligned, normalized, decisions

def evaluate_receiver(
    spec,
    symbols,
    channel,
    snr_db,
    rng,
    coeffs_float,
    coeffs_int,
    input_scale=INPUT_SCALE,
    residual_noise_db=RESIDUAL_NOISE_DB,
):
    rx_clean = apply_channel(symbols, channel)
    rx_noisy, _noise, measured_input_snr_db = add_awgn(rng, rx_clean, snr_db)
    rx_noisy = add_residual_crosstalk(rng, rx_noisy, symbols, residual_noise_db)

    if spec["equalizer"] == "none":
        observed = rx_noisy
    elif spec["equalizer"] == "float-mmse":
        observed = apply_float_ffe(rx_noisy, coeffs_float)
    elif spec["equalizer"] == "fixed-rtl-model":
        observed = run_fixed_ffe(rx_noisy, coeffs_int, input_scale=input_scale)
    else:
        raise ValueError(f"Unknown equalizer: {spec['equalizer']}")

    metrics, _ref, _norm, _dec = align_and_score(observed, symbols)
    return {
        "scenario": spec["scenario"],
        "channel": spec["channel"],
        "receiver": spec["receiver"],
        "equalizer": spec["equalizer"],
        "requested_input_snr_db": float(snr_db),
        "measured_input_snr_db": float(measured_input_snr_db),
        "measured_output_snr_db": float(metrics["measured_output_snr_db"]),
        "lane_symbol_error_rate": float(metrics["lane_symbol_error_rate"]),
        "vector_symbol_error_rate": float(metrics["vector_symbol_error_rate"]),
        "ber_proxy_empirical": float(metrics["ber_proxy_empirical"]),
        "ber_proxy_analytic": float(metrics["ber_proxy_analytic"]),
        "fer_125octet_proxy_empirical": float(metrics["fer_125octet_proxy_empirical"]),
        "fer_125octet_proxy_analytic": float(metrics["fer_125octet_proxy_analytic"]),
        "frame_4d_error_proxy_empirical": float(metrics["frame_4d_error_proxy_empirical"]),
        "residual_sigma": float(metrics["residual_sigma"]),
        "slicer_gain": float(metrics["slicer_gain"]),
        "alignment_delay_symbols": int(metrics["alignment_delay_symbols"]),
        "aligned_symbols": int(metrics["aligned_symbols"]),
    }

def snr_values(start=SNR_START_DB, stop=SNR_STOP_DB, step=SNR_STEP_DB):
    values = []
    value = start
    while value <= stop + 1e-9:
        values.append(round(value, 10))
        value += step
    return values

def estimate_crossing(rows, scenario, metric, target):
    group = [row for row in rows if row["scenario"] == scenario]
    group.sort(key=lambda row: row["requested_input_snr_db"])
    if not group:
        return {"status": "missing", "requested_input_snr_db": None, "measured_output_snr_db": None}

    previous = None
    for row in group:
        value = float(row[metric])
        if value <= target:
            if previous is None:
                return {
                    "status": "met_at_lowest_snr",
                    "requested_input_snr_db": row["requested_input_snr_db"],
                    "measured_output_snr_db": row["measured_output_snr_db"],
                }
            prev_value = max(float(previous[metric]), 1e-300)
            cur_value = max(value, 1e-300)
            log_target = math.log10(target)
            log_prev = math.log10(prev_value)
            log_cur = math.log10(cur_value)
            frac = 1.0 if abs(log_cur - log_prev) < 1e-12 else (log_target - log_prev) / (log_cur - log_prev)
            requested = previous["requested_input_snr_db"] + frac * (
                row["requested_input_snr_db"] - previous["requested_input_snr_db"]
            )
            measured = previous["measured_output_snr_db"] + frac * (
                row["measured_output_snr_db"] - previous["measured_output_snr_db"]
            )
            return {
                "status": "interpolated",
                "requested_input_snr_db": requested,
                "measured_output_snr_db": measured,
            }
        previous = row

    return {"status": "not_reached", "requested_input_snr_db": None, "measured_output_snr_db": None}

def write_csv(rows, output_path):
    with open(output_path, "w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELD_NAMES)
        writer.writeheader()
        for row in rows:
            writer.writerow(row)


def write_summary(rows, output_path, channel, coeffs_float, coeffs_int, coeff_scale, equalizer_delay, equalizer_mse):
    scenarios = sorted({row["scenario"] for row in rows})
    with open(output_path, "w") as handle:
        handle.write("BER/SNR performance proxy for standalone 1000BASE-T FFE\n")
        handle.write("Scope: not a full IEEE 802.3 PHY conformance test\n")
        handle.write(f"Seed: {SEED}\n")
        handle.write(f"Symbols per SNR: {SYMBOLS_PER_SNR}\n")
        handle.write(f"SNR sweep dB: {snr_values()}\n")
        handle.write(f"BER target: {IEEE_BER_TARGET:.3e}\n")
        handle.write(f"125-octet FER proxy target: {IEEE_FER_125_OCTET_TARGET:.3e}\n")
        handle.write(f"Channel impulse: {[float(x) for x in channel]}\n")
        handle.write(f"Floating MMSE coefficients: {[float(x) for x in coeffs_float]}\n")
        handle.write(f"Fixed FFE coefficients: {[int(x) for x in coeffs_int]}\n")
        handle.write(f"Fixed coefficient scale: {coeff_scale}\n")
        handle.write(f"MMSE selected delay symbols: {equalizer_delay}\n")
        handle.write(f"MMSE training MSE: {equalizer_mse:.12e}\n")
        handle.write("\nRequired SNR estimates:\n")
        for scenario in scenarios:
            ber = estimate_crossing(rows, scenario, "ber_proxy_analytic", IEEE_BER_TARGET)
            fer = estimate_crossing(rows, scenario, "fer_125octet_proxy_analytic", IEEE_FER_125_OCTET_TARGET)
            handle.write(f"{scenario} BER target: {ber}\n")
            handle.write(f"{scenario} FER target: {fer}\n")

def plot_results(rows, output_path):
    scenario_order = [
        "ideal_no_ffe",
        "clause40_float_mmse",
        "clause40_fixed_ffe",
        "clause40_no_ffe",
    ]
    labels = {
        "ideal_no_ffe": "Ideal channel",
        "clause40_no_ffe": "Clause 40-like channel, no FFE",
        "clause40_float_mmse": "Clause 40-like channel, floating MMSE FFE",
        "clause40_fixed_ffe": "Clause 40-like channel, fixed RTL-model FFE",
    }
    colors = {
        "ideal_no_ffe": "#002467",
        "clause40_no_ffe": "#e27304",
        "clause40_float_mmse": "#00d00e",
        "clause40_fixed_ffe": "#26A5EE",
    }
    markers = {
        "ideal_no_ffe": "o",
        "clause40_no_ffe": "s",
        "clause40_float_mmse": "^",
        "clause40_fixed_ffe": "D",
    }
    linewidths = {
        "ideal_no_ffe": 1.5,
        "clause40_no_ffe": 2.4,
        "clause40_float_mmse": 1.6,
        "clause40_fixed_ffe": 2.0,
    }

    fig, axes = plt.subplots(2, 1, figsize=(7.2, 6.2), sharex=True)
    for scenario in scenario_order:
        group = [row for row in rows if row["scenario"] == scenario]
        if not group:
            continue
        group.sort(key=lambda row: row["measured_output_snr_db"])
        x = [row["measured_output_snr_db"] for row in group]
        ber = [max(row["ber_proxy_analytic"], 1e-300) for row in group]
        fer = [max(row["fer_125octet_proxy_analytic"], 1e-300) for row in group]
        zorder = 4 if scenario == "clause40_no_ffe" else 2
        axes[0].semilogy(
            x,
            ber,
            marker=markers[scenario],
            linestyle="-",
            linewidth=linewidths[scenario],
            markersize=4.2,
            label=labels[scenario],
            color=colors[scenario],
            markerfacecolor="none" if scenario == "clause40_float_mmse" else colors[scenario],
            zorder=zorder,
        )
        axes[1].semilogy(
            x,
            fer,
            marker=markers[scenario],
            linestyle="-",
            linewidth=linewidths[scenario],
            markersize=4.2,
            label=labels[scenario],
            color=colors[scenario],
            markerfacecolor="none" if scenario == "clause40_float_mmse" else colors[scenario],
            zorder=zorder,
        )

    axes[0].axhline(IEEE_BER_TARGET, color="#cf0505", linestyle="--", linewidth=1.1, label="IEEE BER target 1e-10")
    axes[1].axhline(
        IEEE_FER_125_OCTET_TARGET,
        color="#cf0505",
        linestyle="--",
        linewidth=1.1,
        label="125-octet FER proxy 1e-7",
    )
    axes[0].set_ylabel("BER proxy")
    axes[1].set_ylabel("125-octet FER proxy")
    axes[1].set_xlabel("Measured slicer/equalizer output SNR (dB)")
    for axis in axes:
        axis.grid(True, which="both", linewidth=0.35, alpha=0.5)
        axis.set_ylim(1e-13, 1.2)
        axis.set_xlim(right=33.0)
    axes[0].legend(loc="lower left", fontsize=7.2)
    axes[1].legend(loc="lower left", fontsize=7.2)
    fig.suptitle("1000BASE-T FFE BER/SNR Performance Proxy", fontsize=12)
    fig.tight_layout(rect=(0, 0, 1, 0.97))
    fig.savefig(output_path, dpi=220)
    plt.close(fig)


def run_sweep(settings=None):
    if settings is None:
        settings = {
            "symbols": SYMBOLS_PER_SNR,
            "seed": SEED,
            "snr_start": SNR_START_DB,
            "snr_stop": SNR_STOP_DB,
            "snr_step": SNR_STEP_DB,
            "channel_taps": CHANNEL_TAPS,
            "ffe_taps": FFE_TAPS,
            "mmse_design_snr_db": MMSE_DESIGN_SNR_DB,
            "input_scale": INPUT_SCALE,
            "residual_noise_db": RESIDUAL_NOISE_DB,
        }

    rng = np.random.default_rng(settings["seed"])
    symbols = generate_pam5_symbols(rng, settings["symbols"])
    ideal_channel = build_ideal_channel()
    clause40_channel = build_clause40_channel(settings["channel_taps"])
    coeffs_float, eq_delay, eq_mse = design_mmse_ffe(
        clause40_channel,
        taps=settings["ffe_taps"],
        design_snr_db=settings["mmse_design_snr_db"],
    )
    coeffs_int, coeff_scale = quantize_coefficients(coeffs_float)

    specs = [
        {"scenario": "ideal_no_ffe", "channel": "ideal", "receiver": "no FFE", "equalizer": "none"},
        {
            "scenario": "clause40_no_ffe",
            "channel": "clause40 insertion-loss-shaped",
            "receiver": "no FFE",
            "equalizer": "none",
        },
        {
            "scenario": "clause40_float_mmse",
            "channel": "clause40 insertion-loss-shaped",
            "receiver": "floating MMSE FFE",
            "equalizer": "float-mmse",
        },
        {
            "scenario": "clause40_fixed_ffe",
            "channel": "clause40 insertion-loss-shaped",
            "receiver": "fixed RTL-model FFE",
            "equalizer": "fixed-rtl-model",
        },
    ]

    rows = []
    for snr_db in snr_values(settings["snr_start"], settings["snr_stop"], settings["snr_step"]):
        for spec in specs:
            channel = ideal_channel if spec["channel"] == "ideal" else clause40_channel
            row_rng = np.random.default_rng(rng.integers(0, 2**63 - 1))
            row = evaluate_receiver(
                spec,
                symbols,
                channel,
                snr_db,
                row_rng,
                coeffs_float,
                coeffs_int,
                input_scale=settings["input_scale"],
                residual_noise_db=settings["residual_noise_db"],
            )
            rows.append(row)
            print(
                f"{spec['scenario']:20s} input_snr={snr_db:5.1f} dB "
                f"output_snr={row['measured_output_snr_db']:6.2f} dB "
                f"BER_proxy={row['ber_proxy_analytic']:.3e}"
            )

    return rows, clause40_channel, coeffs_float, coeffs_int, coeff_scale, eq_delay, eq_mse

def main():
    rows, channel, coeffs_float, coeffs_int, coeff_scale, eq_delay, eq_mse = run_sweep()
    write_csv(rows, f"{RESULTS_DIR}/ber_snr_sweep.csv")
    write_summary(
        rows,
        f"{RESULTS_DIR}/ber_snr_summary.txt",
        channel,
        coeffs_float,
        coeffs_int,
        coeff_scale,
        eq_delay,
        eq_mse,
    )
    plot_results(rows, f"{RESULTS_DIR}/ber_snr_sweep.png")
    print(f"CSV:        {RESULTS_DIR}/ber_snr_sweep.csv")
    print(f"Summary:    {RESULTS_DIR}/ber_snr_summary.txt")
    print(f"Plot:       {RESULTS_DIR}/ber_snr_sweep.png")


if __name__ == "__main__":
    main()
