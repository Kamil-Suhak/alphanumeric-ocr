import argparse
import json
from pathlib import Path
from typing import Any, Dict, Optional
import torch
import torch.nn as nn
from torch.utils.data import DataLoader
import yaml

from src.config import RUNS_DIR, resolve_checkpoint_path
from src.data.emnist import (
    CLASS_NAMES,
    get_base_transform,
    get_raw_emnist_datasets,
    get_robust_transform,
)
from src.models.cnn import AlphanumericCNN
from src.seed import make_worker_init_fn, set_seed
from src.training.evaluate import evaluate_model
from src.training.train import fit
from src.utils.checkpoint import load_checkpoint
from src.utils.plotting import plot_confusion_matrix, plot_training_curves


def load_experiment_config(path: Path | str) -> Dict[str, Any]:
    """Wczytanie pliku konfiguracyjnego YAML eksperymentu."""
    with open(path, "r", encoding="utf-8") as f:
        data = yaml.safe_load(f)
    if not isinstance(data, dict):
        raise ValueError(f"Expected YAML mapping in config file: {path}")
    return data


def resolve_augmentation_kwargs(aug_cfg: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Wyznaczenie argumentów potoku degradacji lub None dla modelu bazowego."""
    probs = {}
    for modality in ("blur", "noise", "perspective"):
        prob_key = f"{modality}_prob"
        if prob_key in aug_cfg:
            probs[prob_key] = float(aug_cfg[prob_key])
        else:
            probs[prob_key] = 0.5 if bool(aug_cfg.get(modality, False)) else 0.0

    if "motion_blur_prob" in aug_cfg:
        probs["motion_blur_prob"] = float(aug_cfg["motion_blur_prob"])
    elif bool(aug_cfg.get("motion_blur", False)):
        probs["motion_blur_prob"] = 0.5

    if not any(prob > 0.0 for prob in probs.values()):
        return None

    kwargs: Dict[str, Any] = dict(probs)
    for limit_key in ("max_sigma", "max_noise_std", "max_perspective_severity"):
        if limit_key in aug_cfg:
            kwargs[limit_key] = float(aug_cfg[limit_key])
    if "motion_blur_kernels" in aug_cfg:
        kwargs["motion_blur_kernels"] = [int(k) for k in aug_cfg["motion_blur_kernels"]]
    return kwargs


def resolve_run_name(cfg: Dict[str, Any], seed: int, name_override: Optional[str]) -> str:
    """Jawne wyznaczenie nazwy katalogu eksperymentu z sufiksem ziarna."""
    if name_override:
        return name_override
    base_name = str(cfg.get("experiment", {}).get("name", "EXP"))
    seed_suffix = f"_seed{seed}"
    return base_name if base_name.endswith(seed_suffix) else f"{base_name}{seed_suffix}"


def run_training_experiment(
    config_path: Path | str,
    seed_override: Optional[int] = None,
    name_override: Optional[str] = None,
    epochs_override: Optional[int] = None,
) -> Path:
    """Ujednolicona procedura treningu i ewaluacji dla konfiguracji bazowej, odpornej i ablacyjnej."""
    cfg_path = Path(config_path)
    cfg = load_experiment_config(cfg_path)

    seed = int(seed_override if seed_override is not None else cfg.get("seed", 123))
    set_seed(seed)

    exp_name = resolve_run_name(cfg, seed=seed, name_override=name_override)
    run_dir = RUNS_DIR / exp_name
    run_dir.mkdir(parents=True, exist_ok=True)

    resolved_cfg = dict(cfg)
    resolved_cfg["seed"] = seed
    resolved_cfg.setdefault("experiment", {})
    resolved_cfg["experiment"] = dict(resolved_cfg["experiment"], name=exp_name)

    training_cfg = dict(cfg.get("training", {}))
    batch_size = int(training_cfg.get("batch_size", 512))
    epochs = int(epochs_override if epochs_override is not None else training_cfg.get("epochs", 25))
    lr = float(training_cfg.get("learning_rate", 0.001))
    weight_decay = float(training_cfg.get("weight_decay", 0.0001))
    dropout = float(cfg.get("model", {}).get("dropout", 0.5))

    resolved_cfg["training"] = dict(training_cfg, epochs=epochs)
    with open(run_dir / "config.yaml", "w", encoding="utf-8") as f:
        yaml.safe_dump(resolved_cfg, f, sort_keys=False, allow_unicode=True)

    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Rozpoczęcie eksperymentu {exp_name} (seed={seed}) na urządzeniu: {device}")

    aug_kwargs = resolve_augmentation_kwargs(cfg.get("augmentation", {}))
    if aug_kwargs is None:
        train_set, val_set, test_set = get_raw_emnist_datasets(seed=seed)
    else:
        train_tf = get_robust_transform(seed=seed, **aug_kwargs)
        eval_tf = get_base_transform()
        train_set, val_set, test_set = get_raw_emnist_datasets(
            seed=seed,
            train_transform=train_tf,
            eval_transform=eval_tf,
        )

    num_workers = 2 if torch.cuda.is_available() else 0
    pin_memory = torch.cuda.is_available()
    worker_init = make_worker_init_fn(seed) if num_workers > 0 else None

    train_loader = DataLoader(
        train_set,
        batch_size=batch_size,
        shuffle=True,
        num_workers=num_workers,
        pin_memory=pin_memory,
        worker_init_fn=worker_init,
    )
    val_loader = DataLoader(
        val_set,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=pin_memory,
    )
    test_loader = DataLoader(
        test_set,
        batch_size=batch_size,
        shuffle=False,
        num_workers=num_workers,
        pin_memory=pin_memory,
    )

    model = AlphanumericCNN(num_classes=len(CLASS_NAMES), dropout=dropout).to(device)
    optimizer = torch.optim.AdamW(model.parameters(), lr=lr, weight_decay=weight_decay)
    criterion = nn.CrossEntropyLoss()

    print(f"Liczba parametrów modelu: {model.count_parameters():,}")
    print(f"Próbki: uczące={len(train_set):,}, walidacyjne={len(val_set):,}, testowe={len(test_set):,}")

    history = fit(
        model=model,
        train_loader=train_loader,
        val_loader=val_loader,
        criterion=criterion,
        optimizer=optimizer,
        epochs=epochs,
        device=device,
        run_dir=run_dir,
    )

    plot_training_curves(history, run_dir / "training_curve.png")

    best_checkpoint_path = run_dir / "best.pt"
    print(f"\nWczytywanie najlepszego punktu kontrolnego z {best_checkpoint_path}...")
    load_checkpoint(best_checkpoint_path, model, device=device)

    print("Ewaluacja ostateczna na czystym zbiorze testowym...")
    test_metrics, _, _ = evaluate_model(model, test_loader, device=device)

    cm = test_metrics.pop("confusion_matrix")
    plot_confusion_matrix(cm, CLASS_NAMES, run_dir / "confusion_matrix.png")

    test_results_path = run_dir / "test_results.json"
    with open(test_results_path, "w", encoding="utf-8") as f:
        json.dump(test_metrics, f, indent=2)

    print("\n" + "=" * 50)
    print(f"Wyniki ostateczne eksperymentu {exp_name}:")
    print(f"  Dokładność (Top-1):           {test_metrics['accuracy'] * 100:.2f}%")
    print(f"  Makro-F1:                      {test_metrics['macro_f1'] * 100:.2f}%")
    print(f"  Dokładność (case-insensitive): {test_metrics['case_insensitive_accuracy'] * 100:.2f}%")
    print(f"Kompletne artefakty zapisano w: {run_dir.resolve()}")
    print("=" * 50)
    return run_dir


def load_eval_model(run_name: str, device: torch.device) -> AlphanumericCNN:
    """Wczytanie wytrenowanego modelu AlphanumericCNN w trybie ewaluacji."""
    ckpt_path = resolve_checkpoint_path(run_name)
    model = AlphanumericCNN(num_classes=len(CLASS_NAMES)).to(device)
    load_checkpoint(ckpt_path, model, device=device)
    model.eval()
    return model


def run_train_cli(default_config: Optional[Path] = None, description: str = "Train AlphanumericCNN.") -> Path:
    """Wspólny parser argumentów i uruchomienie treningu z pliku YAML."""
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument(
        "--config",
        type=Path,
        default=default_config,
        required=default_config is None,
        help="Path to the experiment YAML config.",
    )
    parser.add_argument("--seed", type=int, default=None, help="Override random seed from YAML.")
    parser.add_argument("--name", type=str, default=None, help="Override output run folder name.")
    parser.add_argument("--epochs", type=int, default=None, help="Override epoch count from YAML.")
    args = parser.parse_args()
    return run_training_experiment(
        config_path=args.config,
        seed_override=args.seed,
        name_override=args.name,
        epochs_override=args.epochs,
    )
