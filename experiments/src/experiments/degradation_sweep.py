import csv
from pathlib import Path
from typing import Any, Callable, Dict, List, Optional
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np
from PIL import ImageOps
import torch
import torch.nn as nn
from torch.utils.data import DataLoader, Dataset

from src.data.emnist import EMNIST_MEAN, EMNIST_STD, fix_emnist_orientation
from src.data.transforms import (
    apply_compound_degradation,
    apply_gaussian_blur,
    apply_gaussian_noise,
    apply_motion_blur,
    apply_perspective_distortion,
)
from src.training.evaluate import evaluate_model

DegradationFn = Callable[[np.ndarray, np.random.Generator], np.ndarray]


def build_degradation_fn(degradation_type: str, level: Any) -> Optional[DegradationFn]:
    """Zwraca funkcję degradacji przyjmującą (obraz, generator) dla zadanego typu i poziomu."""
    if degradation_type == "clean" or (degradation_type not in ("motion_blur", "compound") and float(level) == 0.0):
        return None
    if degradation_type == "blur":
        sigma = float(level)
        return lambda arr, _rng, s=sigma: apply_gaussian_blur(arr, sigma=s)
    if degradation_type == "noise":
        std = float(level)
        return lambda arr, rng, s=std: apply_gaussian_noise(arr, std=s, rng=rng)
    if degradation_type == "perspective":
        sev = float(level)
        return lambda arr, rng, s=sev: apply_perspective_distortion(arr, severity=s, rng=rng)
    if degradation_type == "motion_blur":
        ksize = int(level)
        return lambda arr, _rng, k=ksize: apply_motion_blur(arr, kernel_size=k, angle_deg=0.0)
    if degradation_type == "compound":
        params = dict(level)
        return lambda arr, rng, p=params: apply_compound_degradation(
            arr,
            perspective=float(p["perspective"]),
            blur_sigma=float(p["blur"]),
            noise_std=float(p["noise"]),
            rng=rng,
        )
    raise ValueError(f"Unsupported degradation_type: {degradation_type}")


class ControlledDegradationDataset(Dataset):
    """Zbiór danych nakładający deterministyczną degradację per próbka i ziarno."""

    def __init__(
        self,
        base_dataset: Dataset,
        degradation_fn: Optional[DegradationFn],
        seed: int = 123,
        mean: float = EMNIST_MEAN,
        std: float = EMNIST_STD,
    ):
        self.base_dataset = base_dataset
        self.degradation_fn = degradation_fn
        self.seed = seed
        self.mean = mean
        self.std = std

    def __len__(self) -> int:
        return len(self.base_dataset)

    def __getitem__(self, idx: int):
        img_pil, target = self.base_dataset[idx]
        img_pil = ImageOps.expand(fix_emnist_orientation(img_pil), border=2, fill=0)
        arr = np.asarray(img_pil, dtype=np.float32) / 255.0

        if self.degradation_fn is not None:
            # Niezależne deterministyczne ziarno per indeks próbki gwarantuje identyczne zakłócenia między modelami
            sample_rng = np.random.default_rng([self.seed, idx])
            arr = self.degradation_fn(arr, sample_rng)

        tensor = torch.from_numpy(arr).unsqueeze(0)
        norm_tensor = (tensor - self.mean) / self.std
        return norm_tensor, target


def run_single_sweep(
    model: nn.Module,
    raw_test_dataset: Dataset,
    degradation_type: str,
    levels: List[float] | List[int],
    device: torch.device,
    batch_size: int = 512,
    eval_seed: int = 123,
) -> List[Dict[str, float]]:
    """Ewaluacja modelu na zbiorze testowym wzdłuż zadanych poziomów degradacji."""
    results = []
    num_workers = 2 if torch.cuda.is_available() else 0
    pin_memory = torch.cuda.is_available()

    for val in levels:
        deg_fn = build_degradation_fn(degradation_type, val)
        sweep_ds = ControlledDegradationDataset(
            raw_test_dataset,
            degradation_fn=deg_fn,
            seed=eval_seed,
        )
        loader = DataLoader(
            sweep_ds,
            batch_size=batch_size,
            shuffle=False,
            num_workers=num_workers,
            pin_memory=pin_memory,
        )

        metrics, _, _ = evaluate_model(model, loader, device=device)
        results.append({
            "severity": float(val),
            "accuracy": metrics["accuracy"],
            "macro_f1": metrics["macro_f1"],
            "case_insensitive_accuracy": metrics["case_insensitive_accuracy"],
        })
        print(f"  {degradation_type} severity={float(val):5.2f} | Dokładność={metrics['accuracy'] * 100:5.2f}%")

    return results


def plot_robustness_curve(
    clean_results: List[Dict[str, float]],
    robust_results: List[Dict[str, float]],
    xlabel: str,
    title: str,
    save_path: Path | str,
) -> None:
    """Wykres porównawczy odporności: Model A (Czysty) vs Model B (Odporny)."""
    severities = [r["severity"] for r in clean_results]
    clean_acc = [r["accuracy"] * 100 for r in clean_results]
    robust_acc = [r["accuracy"] * 100 for r in robust_results]

    plt.figure(figsize=(8, 5))
    plt.plot(severities, clean_acc, marker="o", color="#d62728", lw=2, label="Model A (Czysty - Clean CNN)")
    plt.plot(severities, robust_acc, marker="s", color="#2ca02c", lw=2, label="Model B (Odporny - Robust CNN)")
    plt.axhline(50.0, color="gray", linestyle=":", label="Próg krytyczny (50%)")

    plt.xlabel(xlabel)
    plt.ylabel("Dokładność Top-1 (%)")
    plt.title(title)
    plt.ylim(0, 100)
    plt.grid(True, linestyle=":", alpha=0.6)
    plt.legend()
    plt.tight_layout()

    Path(save_path).parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(save_path, dpi=200)
    plt.close()


def save_sweep_csv(
    clean_results: List[Dict[str, float]],
    robust_results: List[Dict[str, float]],
    save_path: Path | str,
) -> None:
    """Zapis porównawczy wyników sweepów dwóch modeli do pliku CSV."""
    Path(save_path).parent.mkdir(parents=True, exist_ok=True)
    with open(save_path, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow([
            "severity",
            "clean_acc",
            "clean_case_insensitive_acc",
            "clean_macro_f1",
            "robust_acc",
            "robust_case_insensitive_acc",
            "robust_macro_f1",
        ])
        for c, r in zip(clean_results, robust_results):
            writer.writerow([
                f"{c['severity']:.2f}",
                f"{c['accuracy'] * 100:.2f}",
                f"{c['case_insensitive_accuracy'] * 100:.2f}",
                f"{c['macro_f1'] * 100:.2f}",
                f"{r['accuracy'] * 100:.2f}",
                f"{r['case_insensitive_accuracy'] * 100:.2f}",
                f"{r['macro_f1'] * 100:.2f}",
            ])


def save_single_run_sweep_csv(
    results: List[Dict[str, float]],
    save_path: Path | str,
) -> None:
    """Zapis wyników sweepa pojedynczego uruchomienia do pliku CSV."""
    Path(save_path).parent.mkdir(parents=True, exist_ok=True)
    with open(save_path, mode="w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["severity", "accuracy", "case_insensitive_accuracy", "macro_f1"])
        for row in results:
            writer.writerow([
                f"{row['severity']:.2f}",
                f"{row['accuracy'] * 100:.2f}",
                f"{row['case_insensitive_accuracy'] * 100:.2f}",
                f"{row['macro_f1'] * 100:.2f}",
            ])
