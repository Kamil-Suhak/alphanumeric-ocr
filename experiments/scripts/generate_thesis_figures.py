import json
from pathlib import Path
import sys
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np  # noqa: E402
import torch  # noqa: E402
import torchvision.transforms as T  # noqa: E402
from torchvision.datasets import EMNIST  # noqa: E402

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.config import DIAGNOSTICS_DIR, RAW_EMNIST_DIR, TABLES_DIR
from src.data.emnist import CLASS_NAMES, CHAR_TO_INDEX, fix_emnist_orientation, get_raw_emnist_datasets
from src.data.transforms import (
    COMPOUND_STRESS_TIERS,
    MOTION_BLUR_KERNEL_SIZES,
    apply_compound_degradation,
    apply_gaussian_blur,
    apply_gaussian_noise,
    apply_motion_blur,
    apply_perspective_distortion,
)
from src.training.runner import load_eval_model


def find_first_char(dataset, target_char: str) -> np.ndarray:
    target_idx = CHAR_TO_INDEX[target_char]
    for img, label in dataset:
        if int(label) == target_idx:
            if isinstance(img, torch.Tensor):
                return img.squeeze(0).numpy()
            return np.asarray(img, dtype=np.float32) / 255.0
    raise ValueError(f"Character '{target_char}' not found in dataset.")


def generate_motion_blur_samples(viz_train, out_dir: Path) -> Path:
    """1-row grid matching degradation_samples.png style for horizontal motion blur."""
    sample_img = find_first_char(viz_train, "A")
    levels = [1] + list(MOTION_BLUR_KERNEL_SIZES)

    fig, axes = plt.subplots(1, len(levels), figsize=(14, 2.8))
    for idx, ksize in enumerate(levels):
        ax = axes[idx]
        if ksize == 1:
            degraded = sample_img
            title = "Clean (k=1)"
        else:
            degraded = apply_motion_blur(sample_img, kernel_size=ksize, angle_deg=0.0)
            title = f"Motion k={ksize} px"
        ax.imshow(degraded, cmap="gray", vmin=0.0, vmax=1.0)
        ax.set_title(title, fontsize=10)
        ax.axis("off")

    plt.suptitle("Poziome rozmycie ruchowe (OOD, kąt 0°) dla znaku 'A'", fontsize=13)
    plt.tight_layout()
    out_path = out_dir / "motion_blur_samples.png"
    plt.savefig(out_path, dpi=200)
    plt.close(fig)
    return out_path


def generate_compounded_stress_samples(viz_train, out_dir: Path) -> Path:
    """Grid showing Clean vs Tier 1/2/3 simultaneous degradations across 4 characters."""
    chars = ["A", "8", "B", "4"]
    tiers = [("Clean", None)] + [(k, v) for k, v in COMPOUND_STRESS_TIERS.items()]

    fig, axes = plt.subplots(len(chars), len(tiers), figsize=(10.5, 9.5))
    for r, ch in enumerate(chars):
        img = find_first_char(viz_train, ch)
        for c, (tier_name, params) in enumerate(tiers):
            ax = axes[r, c]
            if params is None:
                out = img
            else:
                rng = np.random.default_rng([123, r * 100 + c])
                out = apply_compound_degradation(
                    img,
                    perspective=params["perspective"],
                    blur_sigma=params["blur"],
                    noise_std=params["noise"],
                    rng=rng,
                )
            ax.imshow(out, cmap="gray", vmin=0.0, vmax=1.0)
            if r == 0:
                label = tier_name.replace("_", " ")
                ax.set_title(label, fontsize=10, fontweight="bold")
            if c == 0:
                ax.set_ylabel(f"Znak '{ch}'", fontsize=10, fontweight="bold")
            ax.set_xticks([])
            ax.set_yticks([])

    plt.suptitle("Złożone scenariusze zakłóceń (Perspektywa → Rozmycie → Szum)", fontsize=13)
    plt.tight_layout()
    out_path = out_dir / "compounded_stress_samples.png"
    plt.savefig(out_path, dpi=200)
    plt.close(fig)
    return out_path


def generate_preprocessing_pipeline(raw_train, out_dir: Path) -> Path:
    """Visualizes Raw EMNIST (28x28) -> Orientation Fix -> Zero-Pad (32x32) -> Augmented."""
    chars = ["A", "R", "5"]
    pad_tf = T.Pad(padding=2, fill=0)
    rng = np.random.default_rng(123)

    fig, axes = plt.subplots(len(chars), 4, figsize=(10.5, 7.8))
    col_titles = [
        "1. Surowy EMNIST (28×28)",
        "2. Korekta orientacji (28×28)",
        "3. Dopełnienie zerami (32×32)",
        "4. Augmentacja treningowa",
    ]

    for r, ch in enumerate(chars):
        target_idx = CHAR_TO_INDEX[ch]
        raw_pil = None
        for img_pil, lbl in raw_train:
            if int(lbl) == target_idx:
                raw_pil = img_pil
                break

        raw_arr = np.asarray(raw_pil, dtype=np.float32) / 255.0
        fixed_pil = fix_emnist_orientation(raw_pil)
        fixed_arr = np.asarray(fixed_pil, dtype=np.float32) / 255.0
        padded_pil = pad_tf(fixed_pil)
        padded_arr = np.asarray(padded_pil, dtype=np.float32) / 255.0

        aug_arr = apply_perspective_distortion(padded_arr, severity=0.18, rng=rng)
        aug_arr = apply_gaussian_blur(aug_arr, sigma=1.2)
        aug_arr = apply_gaussian_noise(aug_arr, std=0.10, rng=rng)

        stages = [raw_arr, fixed_arr, padded_arr, aug_arr]
        for c, stage_arr in enumerate(stages):
            ax = axes[r, c]
            ax.imshow(stage_arr, cmap="gray", vmin=0.0, vmax=1.0)
            if c == 2:
                # Subtle dashed frame marking the 28x28 active region inside 32x32
                rect = plt.Rectangle((1.5, 1.5), 28, 28, fill=False, edgecolor="#ff7f0e", linestyle="--", lw=1.2)
                ax.add_patch(rect)
            if r == 0:
                ax.set_title(col_titles[c], fontsize=9.5, fontweight="bold")
            if c == 0:
                ax.set_ylabel(f"Klasa '{ch}'", fontsize=10, fontweight="bold")
            ax.set_xticks([])
            ax.set_yticks([])

    plt.suptitle("Etapy potoku przetwarzania wstępnego i augmentacji danych", fontsize=13)
    plt.tight_layout()
    out_path = out_dir / "preprocessing_pipeline.png"
    plt.savefig(out_path, dpi=200)
    plt.close(fig)
    return out_path


def generate_class_imbalance_and_homoglyphs(raw_train, viz_train, out_dir: Path) -> Path:
    """Top: 62-class sample count bar chart showing imbalance. Bottom: classic homoglyph pairs."""
    targets = np.array(raw_train.targets, dtype=np.int64)
    counts = np.bincount(targets, minlength=len(CLASS_NAMES))

    fig = plt.figure(figsize=(15, 7.5))
    gs = fig.add_gridspec(2, 1, height_ratios=[1.4, 1.0], hspace=0.38)

    ax_bar = fig.add_subplot(gs[0])
    colors = ["#1f77b4"] * 10 + ["#2ca02c"] * 26 + ["#ff7f0e"] * 26
    ax_bar.bar(range(len(CLASS_NAMES)), counts, color=colors, width=0.8)
    ax_bar.set_xticks(range(len(CLASS_NAMES)))
    ax_bar.set_xticklabels(CLASS_NAMES, fontsize=7.5)
    ax_bar.set_ylabel("Liczba próbek uczących")
    ax_bar.set_title("Niezrównoważenie klas w zbiorze EMNIST ByClass (niebieski: 0–9, zielony: A–Z, pomarańczowy: a–z)", fontsize=11)
    ax_bar.grid(axis="y", linestyle=":", alpha=0.5)

    homoglyph_groups = [
        ("0 / O / o", ["0", "O", "o"]),
        ("1 / I / l", ["1", "I", "l"]),
        ("C / c", ["C", "c"]),
        ("S / s / 5", ["S", "s", "5"]),
        ("Z / z / 2", ["Z", "z", "2"]),
    ]
    sub_gs = gs[1].subgridspec(1, len(homoglyph_groups), wspace=0.25)
    for g_idx, (group_title, chars) in enumerate(homoglyph_groups):
        inner_gs = sub_gs[g_idx].subgridspec(1, len(chars), wspace=0.08)
        for c_idx, ch in enumerate(chars):
            ax = fig.add_subplot(inner_gs[c_idx])
            ax.imshow(find_first_char(viz_train, ch), cmap="gray", vmin=0.0, vmax=1.0)
            ax.set_title(f"'{ch}'", fontsize=9.5)
            ax.set_xticks([])
            ax.set_yticks([])
        # Group label via invisible container title
        grp_ax = fig.add_subplot(sub_gs[g_idx], frameon=False)
        grp_ax.set_xticks([])
        grp_ax.set_yticks([])
        grp_ax.set_xlabel(group_title, fontsize=9.5, fontweight="bold", labelpad=14)

    plt.suptitle("Charakterystyka zbioru EMNIST ByClass: niezrównoważenie klas i pary homoglificzne", fontsize=13)
    out_path = out_dir / "class_imbalance_and_homoglyphs.png"
    plt.savefig(out_path, dpi=200, bbox_inches="tight")
    plt.close(fig)
    return out_path


def generate_multi_seed_band_curves(out_dir: Path) -> Path:
    """Plots mean ± std shaded bands from multi_seed_summary.json across blur, noise, perspective."""
    with open(TABLES_DIR / "multi_seed_summary.json", "r", encoding="utf-8") as f:
        ms = json.load(f)

    specs = [
        ("blur", "Rozmycie gaussowskie (σ)", "Rozmycie Gaussa"),
        ("noise", "Szum addytywny (std)", "Szum sensora CMOS"),
        ("perspective", "Zniekształcenie perspektywiczne", "Perspektywa"),
    ]

    fig, axes = plt.subplots(1, 3, figsize=(15.5, 4.6), sharey=True)
    for ax, (key, xlabel, title) in zip(axes, specs):
        rows = ms["sweeps"][key]
        x = np.array([r["severity"] for r in rows])
        a_mean = np.array([r["model_a_acc_mean"] for r in rows])
        a_std = np.array([r["model_a_acc_std"] for r in rows])
        b_mean = np.array([r["model_b_acc_mean"] for r in rows])
        b_std = np.array([r["model_b_acc_std"] for r in rows])

        ax.plot(x, a_mean, "o-", color="#d62728", lw=2, label="Model A (Baseline)")
        ax.fill_between(x, a_mean - a_std, a_mean + a_std, color="#d62728", alpha=0.2)

        ax.plot(x, b_mean, "s-", color="#2ca02c", lw=2, label="Model B (Odporny)")
        ax.fill_between(x, b_mean - b_std, b_mean + b_std, color="#2ca02c", alpha=0.2)

        ax.axhline(50.0, color="gray", linestyle=":", lw=1.2)
        ax.set_title(title, fontsize=11, fontweight="bold")
        ax.set_xlabel(xlabel, fontsize=9.5)
        ax.set_ylim(0, 100)
        ax.grid(True, linestyle=":", alpha=0.6)

    axes[0].set_ylabel("Dokładność Top-1 (%)", fontsize=10)
    axes[0].legend(loc="lower left", fontsize=8.5)
    plt.suptitle("Powtarzalność wieloziarnowa (średnia ± odch. std., ziarna 123, 456, 789)", fontsize=13)
    plt.tight_layout()
    out_path = out_dir / "multi_seed_band_curves.png"
    plt.savefig(out_path, dpi=200)
    plt.close(fig)
    return out_path


def generate_ablation_and_compounded_chart(out_dir: Path) -> Path:
    """Left: 5x4 heatmap from ablation_cross_matrix.json. Right: compounded_stress.json grouped bars."""
    with open(TABLES_DIR / "ablation_cross_matrix.json", "r", encoding="utf-8") as f:
        abl = json.load(f)
    with open(TABLES_DIR / "compounded_stress.json", "r", encoding="utf-8") as f:
        comp = json.load(f)

    run_order = [
        ("EXP-001_baseline_seed123", "Baseline (A)"),
        ("EXP-003_ablation_blur_seed123", "Tylko rozmycie"),
        ("EXP-004_ablation_noise_seed123", "Tylko szum"),
        ("EXP-005_ablation_perspective_seed123", "Tylko perspektywa"),
        ("EXP-002_robust_seed123", "Wszystkie (B)"),
    ]

    matrix = np.zeros((len(run_order), 4), dtype=np.float32)
    for r, (run_id, _) in enumerate(run_order):
        m = abl["models"][run_id]
        matrix[r, 0] = m["clean_accuracy"]
        matrix[r, 1] = m["degradations"]["blur"]["points"]["2.0"]
        matrix[r, 2] = m["degradations"]["noise"]["points"]["0.2"]
        matrix[r, 3] = m["degradations"]["perspective"]["points"]["0.25"]

    fig, (ax_hm, ax_bar) = plt.subplots(1, 2, figsize=(15.5, 5.4), gridspec_kw={"width_ratios": [1.0, 1.15]})

    im = ax_hm.imshow(matrix, cmap="YlGn", vmin=0.0, vmax=95.0, aspect="auto")
    ax_hm.set_xticks(range(4))
    ax_hm.set_xticklabels(["Clean", "Blur σ=2.0", "Noise 0.20", "Persp 0.25"], fontsize=9.5)
    ax_hm.set_yticks(range(len(run_order)))
    ax_hm.set_yticklabels([lbl for _, lbl in run_order], fontsize=9.5)
    ax_hm.set_title("Macierz transferu ablacji (%)", fontsize=11, fontweight="bold")
    for r in range(matrix.shape[0]):
        for c in range(matrix.shape[1]):
            val = matrix[r, c]
            txt_color = "white" if val > 58.0 else "black"
            ax_hm.text(c, r, f"{val:.1f}%", ha="center", va="center", color=txt_color, fontsize=9, fontweight="bold")
    plt.colorbar(im, ax=ax_hm, fraction=0.046, pad=0.04)

    tiers = ["clean", "tier_1_mild", "tier_2_moderate", "tier_3_harsh"]
    tier_labels = ["Clean", "Tier 1\n(Łagodny)", "Tier 2\n(Umiarkowany)", "Tier 3\n(Ciężki)"]
    x = np.arange(len(tiers))
    width = 0.15
    bar_colors = ["#d62728", "#1f77b4", "#ff7f0e", "#9467bd", "#2ca02c"]

    for idx, (run_id, label) in enumerate(run_order):
        vals = [comp["runs"][run_id][t]["accuracy_pct"] for t in tiers]
        offset = (idx - 2) * width
        ax_bar.bar(x + offset, vals, width=width, label=label, color=bar_colors[idx])

    ax_bar.set_xticks(x)
    ax_bar.set_xticklabels(tier_labels, fontsize=9.5)
    ax_bar.set_ylabel("Dokładność Top-1 (%)", fontsize=10)
    ax_bar.set_ylim(0, 100)
    ax_bar.set_title("Odporność na stres złożony (Persp → Blur → Noise)", fontsize=11, fontweight="bold")
    ax_bar.grid(axis="y", linestyle=":", alpha=0.5)
    ax_bar.legend(loc="upper right", fontsize=8.5)

    plt.suptitle("Porównanie wariantów ablacyjnych i synergii augmentacji złożonej", fontsize=13)
    plt.tight_layout()
    out_path = out_dir / "ablation_and_compounded_summary.png"
    plt.savefig(out_path, dpi=200)
    plt.close(fig)
    return out_path


def generate_conv1_filters_comparison(out_dir: Path) -> Path:
    """Visualizes the 32 learned 3x3 conv1 kernels for Model A vs Model B."""
    cpu = torch.device("cpu")
    model_a = load_eval_model("EXP-001_baseline_seed123", device=cpu)
    model_b = load_eval_model("EXP-002_robust_seed123", device=cpu)

    w_a = model_a.features[0].weight.detach().squeeze(1).numpy()
    w_b = model_b.features[0].weight.detach().squeeze(1).numpy()
    vmax = float(max(np.abs(w_a).max(), np.abs(w_b).max()))

    fig = plt.figure(figsize=(13, 6.2))
    outer = fig.add_gridspec(1, 2, wspace=0.12)

    for m_idx, (weights, title) in enumerate([
        (w_a, "Model A (Baseline): 32 filtry Conv1 (3×3)"),
        (w_b, "Model B (Odporny): 32 filtry Conv1 (3×3)"),
    ]):
        inner = outer[m_idx].subgridspec(4, 8, wspace=0.1, hspace=0.1)
        for f_idx in range(32):
            ax = fig.add_subplot(inner[f_idx // 8, f_idx % 8])
            ax.imshow(weights[f_idx], cmap="RdBu_r", vmin=-vmax, vmax=vmax)
            ax.set_xticks([])
            ax.set_yticks([])
        title_ax = fig.add_subplot(outer[m_idx], frameon=False)
        title_ax.set_xticks([])
        title_ax.set_yticks([])
        title_ax.set_title(title, fontsize=11, fontweight="bold", pad=12)

    plt.suptitle("Porównanie wag pierwszej warstwy konwolucyjnej (EXP-001 vs EXP-002)", fontsize=13)
    out_path = out_dir / "conv1_filters_comparison.png"
    plt.savefig(out_path, dpi=200, bbox_inches="tight")
    plt.close(fig)
    return out_path


def main() -> None:
    DIAGNOSTICS_DIR.mkdir(parents=True, exist_ok=True)
    raw_train = EMNIST(root=str(RAW_EMNIST_DIR), split="byclass", train=True, download=False, transform=None)
    viz_transform = T.Compose([
        T.Lambda(fix_emnist_orientation),
        T.Pad(padding=2, fill=0),
        T.ToTensor(),
    ])
    viz_train, _, _ = get_raw_emnist_datasets(transform=viz_transform)

    generated = [
        generate_motion_blur_samples(viz_train, DIAGNOSTICS_DIR),
        generate_compounded_stress_samples(viz_train, DIAGNOSTICS_DIR),
        generate_preprocessing_pipeline(raw_train, DIAGNOSTICS_DIR),
        generate_class_imbalance_and_homoglyphs(raw_train, viz_train, DIAGNOSTICS_DIR),
        generate_multi_seed_band_curves(DIAGNOSTICS_DIR),
        generate_ablation_and_compounded_chart(DIAGNOSTICS_DIR),
        generate_conv1_filters_comparison(DIAGNOSTICS_DIR),
    ]
    for path in generated:
        print(f"Wygenerowano: {path}")


if __name__ == "__main__":
    main()
