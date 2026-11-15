import argparse
from pathlib import Path
import sys
from typing import Dict, List, Optional, Tuple
import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
import numpy as np
from PIL import ImageOps
import torch
import torch.nn as nn
import torch.nn.functional as F
from torchvision.datasets import EMNIST

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.append(str(PROJECT_ROOT))

from src.config import DIAGNOSTICS_DIR, EMNIST_MEAN, EMNIST_STD, RAW_EMNIST_DIR
from src.data.emnist import CHAR_TO_INDEX, CLASS_NAMES, fix_emnist_orientation
from src.experiments.degradation_sweep import build_degradation_fn
from src.training.runner import load_eval_model

DEFAULT_CONDITIONS: List[Tuple[str, str, Optional[float]]] = [
    ("Clean", "clean", 0.0),
    ("Blur s=1.5", "blur", 1.5),
    ("Blur s=2.5", "blur", 2.5),
    ("Noise std=0.20", "noise", 0.20),
    ("Persp s=0.25", "perspective", 0.25),
]


def disable_inplace_relu(model: nn.Module) -> None:
    """Wyłącza operacje inplace ReLU w pamięci przed rejestracją hooków wstecznych."""
    for module in model.modules():
        if isinstance(module, nn.ReLU):
            module.inplace = False


def compute_gradcam(
    model: nn.Module,
    input_tensor: torch.Tensor,
    target_layer: nn.Module,
    target_class: Optional[int] = None,
) -> Tuple[np.ndarray, int, float]:
    """Oblicza znormalizowaną mapę atrybucji Grad-CAM (32x32) dla pojedynczej próbki."""
    activations: List[torch.Tensor] = []
    gradients: List[torch.Tensor] = []

    def forward_hook(_module: nn.Module, _inputs: Tuple[torch.Tensor, ...], output: torch.Tensor) -> None:
        activations.append(output.detach())

    def backward_hook(
        _module: nn.Module,
        _grad_input: Tuple[Optional[torch.Tensor], ...],
        grad_output: Tuple[Optional[torch.Tensor], ...],
    ) -> None:
        if grad_output[0] is not None:
            gradients.append(grad_output[0].detach())

    fwd_handle = target_layer.register_forward_hook(forward_hook)
    bwd_handle = target_layer.register_full_backward_hook(backward_hook)

    try:
        model.zero_grad(set_to_none=True)
        inp = input_tensor.detach().requires_grad_(True)
        logits = model(inp)
        probs = torch.softmax(logits, dim=1)
        pred_idx = int(probs.argmax(dim=1).item())
        cls_idx = pred_idx if target_class is None else int(target_class)
        confidence = float(probs[0, pred_idx].item())

        score = logits[0, cls_idx]
        score.backward()

        act = activations[0]
        grad = gradients[0]
        weights = grad.mean(dim=(2, 3), keepdim=True)
        cam = F.relu((weights * act).sum(dim=1, keepdim=True))
        cam_up = F.interpolate(cam, size=inp.shape[-2:], mode="bilinear", align_corners=False)
        cam_np = cam_up.squeeze().cpu().numpy()
        max_val = float(cam_np.max())
        if max_val > 1e-8:
            cam_np = (cam_np - float(cam_np.min())) / (max_val - float(cam_np.min()) + 1e-8)
        else:
            cam_np = np.zeros_like(cam_np, dtype=np.float32)
        return cam_np.astype(np.float32), pred_idx, confidence
    finally:
        fwd_handle.remove()
        bwd_handle.remove()


def find_character_sample_indices(
    raw_dataset: EMNIST,
    chars: List[str],
    model_a: nn.Module,
    model_b: nn.Module,
    device: torch.device,
) -> Dict[str, int]:
    """Wybiera po jednej próbce testowej dla każdego znaku (preferując zgodną poprawną klasyfikację na Clean)."""
    target_labels = {CHAR_TO_INDEX[c]: c for c in chars}
    fallback: Dict[str, int] = {}
    selected: Dict[str, int] = {}

    for idx in range(len(raw_dataset)):
        img_pil, target = raw_dataset[idx]
        if target not in target_labels:
            continue
        char = target_labels[target]
        if char in selected:
            continue

        arr = prepare_clean_array(img_pil)
        tensor = array_to_tensor(arr, device=device)
        with torch.no_grad():
            pred_a = int(model_a(tensor).argmax(dim=1).item())
            pred_b = int(model_b(tensor).argmax(dim=1).item())

        if char not in fallback:
            fallback[char] = idx
        if pred_a == target and pred_b == target:
            selected[char] = idx
            if len(selected) == len(chars):
                break

    for char in chars:
        if char not in selected:
            if char not in fallback:
                raise ValueError(f"No sample found in dataset for character '{char}'.")
            selected[char] = fallback[char]
    return selected


def prepare_clean_array(img_pil) -> np.ndarray:
    fixed = ImageOps.expand(fix_emnist_orientation(img_pil), border=2, fill=0)
    return np.asarray(fixed, dtype=np.float32) / 255.0


def array_to_tensor(arr: np.ndarray, device: torch.device) -> torch.Tensor:
    tensor = torch.from_numpy(arr).unsqueeze(0).unsqueeze(0).to(device)
    return (tensor - EMNIST_MEAN) / EMNIST_STD


def generate_gradcam_figure(
    raw_dataset: EMNIST,
    model_a: nn.Module,
    model_b: nn.Module,
    sample_indices: Dict[str, int],
    layer_idx: int,
    eval_seed: int,
    device: torch.device,
    output_path: Path,
) -> None:
    """Tworzy zbiorczy wykres porównawczy map Grad-CAM dla Modelu A i Modelu B."""
    disable_inplace_relu(model_a)
    disable_inplace_relu(model_b)
    target_layer_a = model_a.features[layer_idx]
    target_layer_b = model_b.features[layer_idx]

    chars = list(sample_indices.keys())
    n_chars = len(chars)
    n_conds = len(DEFAULT_CONDITIONS)

    fig, axes = plt.subplots(
        n_chars * 3,
        n_conds,
        figsize=(2.3 * n_conds, 2.0 * n_chars * 3),
        squeeze=False,
    )

    for c_idx, char in enumerate(chars):
        ds_idx = sample_indices[char]
        img_pil, _ = raw_dataset[ds_idx]
        clean_arr = prepare_clean_array(img_pil)

        base_row = c_idx * 3
        for k_idx, (cond_label, deg_type, level) in enumerate(DEFAULT_CONDITIONS):
            deg_fn = build_degradation_fn(deg_type, level)
            if deg_fn is not None:
                sample_rng = np.random.default_rng([eval_seed, ds_idx])
                arr = deg_fn(clean_arr, sample_rng)
            else:
                arr = clean_arr

            tensor = array_to_tensor(arr, device=device)
            cam_a, pred_a, conf_a = compute_gradcam(model_a, tensor, target_layer_a)
            cam_b, pred_b, conf_b = compute_gradcam(model_b, tensor, target_layer_b)

            ax_in = axes[base_row, k_idx]
            ax_a = axes[base_row + 1, k_idx]
            ax_b = axes[base_row + 2, k_idx]

            ax_in.imshow(arr, cmap="gray", vmin=0.0, vmax=1.0)
            if c_idx == 0:
                ax_in.set_title(cond_label, fontsize=10, fontweight="bold")

            ax_a.imshow(arr, cmap="gray", vmin=0.0, vmax=1.0)
            ax_a.imshow(cam_a, cmap="jet", alpha=0.45, vmin=0.0, vmax=1.0)
            color_a = "#1b7837" if CLASS_NAMES[pred_a] == char else "#d73027"
            ax_a.set_xlabel(f"Pred: {CLASS_NAMES[pred_a]} ({conf_a * 100:.0f}%)", fontsize=8, color=color_a)

            ax_b.imshow(arr, cmap="gray", vmin=0.0, vmax=1.0)
            ax_b.imshow(cam_b, cmap="jet", alpha=0.45, vmin=0.0, vmax=1.0)
            color_b = "#1b7837" if CLASS_NAMES[pred_b] == char else "#d73027"
            ax_b.set_xlabel(f"Pred: {CLASS_NAMES[pred_b]} ({conf_b * 100:.0f}%)", fontsize=8, color=color_b)

            for ax in (ax_in, ax_a, ax_b):
                ax.set_xticks([])
                ax.set_yticks([])

        axes[base_row, 0].set_ylabel(f"'{char}' Wejście", fontsize=9, fontweight="bold")
        axes[base_row + 1, 0].set_ylabel(f"'{char}' Model A", fontsize=9)
        axes[base_row + 2, 0].set_ylabel(f"'{char}' Model B", fontsize=9)

    fig.suptitle(
        f"Porównanie atrybucji Grad-CAM (warstwa features[{layer_idx}]): Model A vs Model B",
        fontsize=12,
        fontweight="bold",
        y=0.995,
    )
    plt.tight_layout(rect=[0, 0, 1, 0.985])
    output_path.parent.mkdir(parents=True, exist_ok=True)
    plt.savefig(output_path, dpi=200)
    plt.close(fig)
    print(f"Zapisano mapy Grad-CAM do: {output_path}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="EXP-007: Grad-CAM attribution comparison.")
    parser.add_argument("--model-a", type=str, default="EXP-001_baseline_seed123")
    parser.add_argument("--model-b", type=str, default="EXP-002_robust_seed123")
    parser.add_argument("--chars", nargs="+", default=["A", "8", "B", "0"])
    parser.add_argument("--layer-idx", type=int, default=8, help="Conv layer index in AlphanumericCNN.features.")
    parser.add_argument("--eval-seed", type=int, default=123)
    parser.add_argument("--output", type=Path, default=DIAGNOSTICS_DIR / "gradcam_comparison.png")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    model_a = load_eval_model(args.model_a, device=device)
    model_b = load_eval_model(args.model_b, device=device)

    raw_test = EMNIST(root=str(RAW_EMNIST_DIR), split="byclass", train=False, download=False, transform=None)
    sample_indices = find_character_sample_indices(raw_test, args.chars, model_a, model_b, device=device)
    print(f"Wybrane indeksy próbek testowych: {sample_indices}")

    generate_gradcam_figure(
        raw_dataset=raw_test,
        model_a=model_a,
        model_b=model_b,
        sample_indices=sample_indices,
        layer_idx=args.layer_idx,
        eval_seed=args.eval_seed,
        device=device,
        output_path=args.output,
    )


if __name__ == "__main__":
    main()
