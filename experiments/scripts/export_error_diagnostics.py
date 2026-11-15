import argparse
import csv
import json
from pathlib import Path
import sys
from typing import Any, Dict, List, Tuple
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np
import torch
from torch.utils.data import DataLoader, Subset
from torchvision.datasets import EMNIST

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.config import DIAGNOSTICS_DIR, EMNIST_MEAN, EMNIST_STD, RAW_EMNIST_DIR, TABLES_DIR
from src.data.emnist import CHAR_TO_INDEX, CLASS_NAMES
from src.data.transforms import COMPOUND_STRESS_TIERS
from src.experiments.degradation_sweep import ControlledDegradationDataset, build_degradation_fn
from src.training.runner import load_eval_model
from src.utils.metrics import AMBIGUOUS_CASE_PAIRS

DIGIT_LETTER_HOMOGLYPH_GROUPS: Dict[str, List[str]] = {
    "0_O_o": ["0", "O", "o"],
    "1_I_l": ["1", "I", "l"],
    "2_Z_z": ["2", "Z", "z"],
    "5_S_s": ["5", "S", "s"],
    "8_B": ["8", "B"],
    "9_q_g": ["9", "q", "g"],
}

QUADRANT_ORDER = [
    ("a_fail_b_pass", "Model A błąd / Model B OK"),
    ("a_pass_b_fail", "Model A OK / Model B błąd"),
    ("both_fail", "Oba błędne"),
    ("both_pass", "Oba poprawne"),
]


def collect_predictions_and_confidence(
    model: torch.nn.Module,
    loader: DataLoader,
    device: torch.device,
) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
    """Zbiera etykiety rzeczywiste, predykcje i pewność (max softmax) modelu."""
    y_true_parts: List[np.ndarray] = []
    y_pred_parts: List[np.ndarray] = []
    conf_parts: List[np.ndarray] = []

    model.eval()
    with torch.no_grad():
        for images, targets in loader:
            images = images.to(device, non_blocking=True)
            logits = model(images)
            probs = torch.softmax(logits, dim=1)
            conf, preds = probs.max(dim=1)
            y_true_parts.append(targets.numpy())
            y_pred_parts.append(preds.cpu().numpy())
            conf_parts.append(conf.cpu().numpy())

    return np.concatenate(y_true_parts), np.concatenate(y_pred_parts), np.concatenate(conf_parts)


def stratify_quadrants(
    y_true: np.ndarray,
    pred_a: np.ndarray,
    pred_b: np.ndarray,
) -> Tuple[np.ndarray, Dict[str, int]]:
    """Przypisuje każdą próbkę do jednego z czterech kwadrantów porównawczych A vs B."""
    ok_a = pred_a == y_true
    ok_b = pred_b == y_true
    quadrants = np.empty(len(y_true), dtype=object)

    masks = {
        "a_fail_b_pass": (~ok_a) & ok_b,
        "a_pass_b_fail": ok_a & (~ok_b),
        "both_fail": (~ok_a) & (~ok_b),
        "both_pass": ok_a & ok_b,
    }
    counts: Dict[str, int] = {}
    for key, mask in masks.items():
        quadrants[mask] = key
        counts[key] = int(mask.sum())
    return quadrants, counts


def compute_homoglyph_breakdown(
    y_true: np.ndarray,
    pred_a: np.ndarray,
    pred_b: np.ndarray,
) -> Dict[str, Any]:
    """Wyznacza wskaźniki kolizji w 15 parach wielkościowych oraz grupach cyfra/litera."""
    case_pairs = []
    for upper, lower in AMBIGUOUS_CASE_PAIRS:
        u_idx = CHAR_TO_INDEX[upper]
        l_idx = CHAR_TO_INDEX[lower]
        mask = (y_true == u_idx) | (y_true == l_idx)
        total = int(mask.sum())
        if total == 0:
            continue
        conf_a = int((((y_true == u_idx) & (pred_a == l_idx)) | ((y_true == l_idx) & (pred_a == u_idx))).sum())
        conf_b = int((((y_true == u_idx) & (pred_b == l_idx)) | ((y_true == l_idx) & (pred_b == u_idx))).sum())
        case_pairs.append({
            "pair": f"{upper}/{lower}",
            "total_samples": total,
            "model_a_case_swap_pct": round((conf_a / total) * 100.0, 2),
            "model_b_case_swap_pct": round((conf_b / total) * 100.0, 2),
            "model_a_err_pct": round(float((pred_a[mask] != y_true[mask]).mean()) * 100.0, 2),
            "model_b_err_pct": round(float((pred_b[mask] != y_true[mask]).mean()) * 100.0, 2),
        })

    digit_letter_groups = []
    for group_name, chars in DIGIT_LETTER_HOMOGLYPH_GROUPS.items():
        idxs = [CHAR_TO_INDEX[c] for c in chars]
        idx_set = np.isin(y_true, idxs)
        total = int(idx_set.sum())
        if total == 0:
            continue
        err_a = float((pred_a[idx_set] != y_true[idx_set]).mean()) * 100.0
        err_b = float((pred_b[idx_set] != y_true[idx_set]).mean()) * 100.0
        in_group_a = float((np.isin(pred_a[idx_set], idxs) & (pred_a[idx_set] != y_true[idx_set])).mean()) * 100.0
        in_group_b = float((np.isin(pred_b[idx_set], idxs) & (pred_b[idx_set] != y_true[idx_set])).mean()) * 100.0
        digit_letter_groups.append({
            "group": "/".join(chars),
            "key": group_name,
            "total_samples": total,
            "model_a_total_err_pct": round(err_a, 2),
            "model_b_total_err_pct": round(err_b, 2),
            "model_a_in_group_confusion_pct": round(in_group_a, 2),
            "model_b_in_group_confusion_pct": round(in_group_b, 2),
        })

    return {
        "ambiguous_case_pairs": case_pairs,
        "digit_letter_groups": digit_letter_groups,
    }


def plot_error_quadrants(
    dataset: ControlledDegradationDataset,
    y_true: np.ndarray,
    pred_a: np.ndarray,
    conf_a: np.ndarray,
    pred_b: np.ndarray,
    conf_b: np.ndarray,
    quadrants: np.ndarray,
    save_path: Path,
) -> None:
    """Wizualizuje po 4 reprezentatywne próbki z każdego kwadrantu porównania A vs B."""
    fig, axes = plt.subplots(4, 4, figsize=(10.5, 11.0), squeeze=False)
    for row_idx, (q_key, q_title) in enumerate(QUADRANT_ORDER):
        indices = np.where(quadrants == q_key)[0]
        if q_key == "a_fail_b_pass":
            indices = indices[np.argsort(-(conf_b[indices] - conf_a[indices]))]
        elif q_key == "a_pass_b_fail":
            indices = indices[np.argsort(-(conf_a[indices] - conf_b[indices]))]
        elif len(indices) > 0:
            indices = indices[np.argsort(-(conf_b[indices] + conf_a[indices]))]

        for col_idx in range(4):
            ax = axes[row_idx, col_idx]
            ax.set_xticks([])
            ax.set_yticks([])
            if col_idx >= len(indices):
                ax.axis("off")
                continue

            s_idx = int(indices[col_idx])
            tensor, _ = dataset[s_idx]
            img = np.clip(tensor.squeeze(0).numpy() * EMNIST_STD + EMNIST_MEAN, 0.0, 1.0)
            ax.imshow(img, cmap="gray", vmin=0.0, vmax=1.0)
            t_char = CLASS_NAMES[int(y_true[s_idx])]
            a_char = CLASS_NAMES[int(pred_a[s_idx])]
            b_char = CLASS_NAMES[int(pred_b[s_idx])]
            ax.set_title(f"GT: {t_char}", fontsize=9, fontweight="bold")
            ax.set_xlabel(
                f"A: {a_char} ({conf_a[s_idx] * 100:.0f}%) | B: {b_char} ({conf_b[s_idx] * 100:.0f}%)",
                fontsize=8,
            )

        axes[row_idx, 0].set_ylabel(q_title, fontsize=9, fontweight="bold")

    fig.suptitle("Przykłady próbek w 4 kwadrantach błędów (Stres złożony Tier 2)", fontsize=11, fontweight="bold")
    plt.tight_layout(rect=[0, 0, 1, 0.96])
    save_path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(save_path, dpi=200)
    plt.close(fig)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="EXP-010: Error stratification and homoglyph breakdown.")
    parser.add_argument("--model-a", type=str, default="EXP-001_baseline_seed123")
    parser.add_argument("--model-b", type=str, default="EXP-002_robust_seed123")
    parser.add_argument("--eval-seed", type=int, default=123)
    parser.add_argument("--batch-size", type=int, default=512)
    parser.add_argument("--max-samples", type=int, default=None)
    parser.add_argument("--csv-output", type=Path, default=TABLES_DIR / "error_stratification.csv")
    parser.add_argument("--json-output", type=Path, default=TABLES_DIR / "homoglyph_breakdown.json")
    parser.add_argument("--plot-output", type=Path, default=DIAGNOSTICS_DIR / "error_quadrants.png")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model_a = load_eval_model(args.model_a, device=device)
    model_b = load_eval_model(args.model_b, device=device)

    raw_test = EMNIST(root=str(RAW_EMNIST_DIR), split="byclass", train=False, download=False, transform=None)
    if args.max_samples is None:
        dataset = raw_test
    else:
        dataset = Subset(raw_test, list(range(min(args.max_samples, len(raw_test)))))
    num_workers = 2 if torch.cuda.is_available() else 0
    pin_memory = torch.cuda.is_available()

    regimes = [
        ("clean", None),
        ("tier_2_moderate", build_degradation_fn("compound", COMPOUND_STRESS_TIERS["tier_2_moderate"])),
    ]

    args.csv_output.parent.mkdir(parents=True, exist_ok=True)
    summary: Dict[str, Any] = {
        "model_a": args.model_a,
        "model_b": args.model_b,
        "eval_seed": args.eval_seed,
        "num_samples": len(dataset),
        "regimes": {},
    }

    with open(args.csv_output, "w", newline="", encoding="utf-8") as csv_f:
        writer = csv.writer(csv_f)
        writer.writerow(["regime", "sample_idx", "true_char", "pred_a", "conf_a", "pred_b", "conf_b", "quadrant"])

        for regime_name, deg_fn in regimes:
            print(f"\n=== Analiza błędów A vs B ({regime_name}) ===")
            ctrl_ds = ControlledDegradationDataset(dataset, degradation_fn=deg_fn, seed=args.eval_seed)
            loader = DataLoader(
                ctrl_ds, batch_size=args.batch_size, shuffle=False, num_workers=num_workers, pin_memory=pin_memory
            )
            y_true, pred_a, conf_a = collect_predictions_and_confidence(model_a, loader, device=device)
            _, pred_b, conf_b = collect_predictions_and_confidence(model_b, loader, device=device)
            quadrants, counts = stratify_quadrants(y_true, pred_a, pred_b)

            for idx in range(len(y_true)):
                if quadrants[idx] == "both_pass":
                    continue
                writer.writerow([
                    regime_name,
                    idx,
                    CLASS_NAMES[int(y_true[idx])],
                    CLASS_NAMES[int(pred_a[idx])],
                    f"{conf_a[idx]:.4f}",
                    CLASS_NAMES[int(pred_b[idx])],
                    f"{conf_b[idx]:.4f}",
                    quadrants[idx],
                ])

            homoglyphs = compute_homoglyph_breakdown(y_true, pred_a, pred_b)
            summary["regimes"][regime_name] = {
                "quadrant_counts": counts,
                "quadrant_pct": {k: round((v / len(y_true)) * 100.0, 2) for k, v in counts.items()},
                **homoglyphs,
            }
            print(f"  Kwadranty: {counts}")

            if regime_name == "tier_2_moderate":
                plot_error_quadrants(
                    ctrl_ds, y_true, pred_a, conf_a, pred_b, conf_b, quadrants, args.plot_output
                )

    args.json_output.parent.mkdir(parents=True, exist_ok=True)
    with open(args.json_output, "w", encoding="utf-8") as json_f:
        json.dump(summary, json_f, indent=2)

    print(f"\nZapisano CSV stratyfikacji do: {args.csv_output}")
    print(f"Zapisano podsumowanie homoglifików do: {args.json_output}")
    print(f"Zapisano siatkę kwadrantów do: {args.plot_output}")


if __name__ == "__main__":
    main()
