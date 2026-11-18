from pathlib import Path
from types import SimpleNamespace
import numpy as np
import pytest

from src.config import EXPERIMENTS_ROOT, resolve_checkpoint_path
from src.seed import make_worker_init_fn
from src.training.runner import (
    load_experiment_config,
    resolve_augmentation_kwargs,
    resolve_run_name,
)

CONFIGS_DIR = EXPERIMENTS_ROOT / "configs"


def test_config_augmentation_and_explicit_seed_naming() -> None:
    baseline_cfg = load_experiment_config(CONFIGS_DIR / "baseline.yaml")
    robust_cfg = load_experiment_config(CONFIGS_DIR / "robust.yaml")
    blur_cfg = load_experiment_config(CONFIGS_DIR / "ablation_blur.yaml")
    noise_cfg = load_experiment_config(CONFIGS_DIR / "ablation_noise.yaml")
    persp_cfg = load_experiment_config(CONFIGS_DIR / "ablation_perspective.yaml")
    ext_cfg = load_experiment_config(CONFIGS_DIR / "robust_extended.yaml")

    assert resolve_augmentation_kwargs(baseline_cfg["augmentation"]) is None

    robust_aug = resolve_augmentation_kwargs(robust_cfg["augmentation"])
    assert robust_aug == {
        "blur_prob": 0.5,
        "noise_prob": 0.5,
        "perspective_prob": 0.5,
        "max_sigma": 2.0,
        "max_noise_std": 0.15,
        "max_perspective_severity": 0.25,
    }

    assert resolve_augmentation_kwargs(blur_cfg["augmentation"]) == {
        "blur_prob": 0.5,
        "noise_prob": 0.0,
        "perspective_prob": 0.0,
        "max_sigma": 2.0,
    }
    assert resolve_augmentation_kwargs(noise_cfg["augmentation"]) == {
        "blur_prob": 0.0,
        "noise_prob": 0.5,
        "perspective_prob": 0.0,
        "max_noise_std": 0.15,
    }
    assert resolve_augmentation_kwargs(persp_cfg["augmentation"]) == {
        "blur_prob": 0.0,
        "noise_prob": 0.0,
        "perspective_prob": 0.5,
        "max_perspective_severity": 0.25,
    }
    assert resolve_augmentation_kwargs(ext_cfg["augmentation"]) == {
        "blur_prob": 0.5,
        "noise_prob": 0.5,
        "perspective_prob": 0.5,
        "motion_blur_prob": 0.5,
        "max_sigma": 2.0,
        "max_noise_std": 0.15,
        "max_perspective_severity": 0.25,
        "motion_blur_kernels": [3, 5, 7, 9],
    }

    for seed in (123, 456, 789):
        assert resolve_run_name(baseline_cfg, seed=seed, name_override=None) == f"EXP-001_baseline_seed{seed}"
        assert resolve_run_name(robust_cfg, seed=seed, name_override=None) == f"EXP-002_robust_seed{seed}"
        assert resolve_run_name(ext_cfg, seed=seed, name_override=None) == f"EXP-011_robust_extended_seed{seed}"

    assert resolve_run_name(blur_cfg, seed=123, name_override=None) == "EXP-003_ablation_blur_seed123"
    assert resolve_run_name(noise_cfg, seed=123, name_override=None) == "EXP-004_ablation_noise_seed123"
    assert resolve_run_name(persp_cfg, seed=123, name_override=None) == "EXP-005_ablation_perspective_seed123"
    assert resolve_run_name(baseline_cfg, seed=123, name_override="custom_run") == "custom_run"


def test_resolve_checkpoint_path_supports_run_name_and_direct_file(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    runs_dir = tmp_path / "runs"
    for run_name in ("EXP-001_baseline_seed123", "EXP-002_robust_seed123"):
        run_dir = runs_dir / run_name
        run_dir.mkdir(parents=True)
        (run_dir / "best.pt").write_bytes(b"stub")

    monkeypatch.setattr("src.config.RUNS_DIR", runs_dir)

    ckpt_a = resolve_checkpoint_path("EXP-001_baseline_seed123")
    ckpt_b = resolve_checkpoint_path("EXP-002_robust_seed123")
    assert ckpt_a == runs_dir / "EXP-001_baseline_seed123" / "best.pt"
    assert ckpt_b == runs_dir / "EXP-002_robust_seed123" / "best.pt"
    assert ckpt_a.is_file()
    assert ckpt_b.is_file()

    custom_ckpt = tmp_path / "model.pt"
    custom_ckpt.write_bytes(b"stub")
    assert resolve_checkpoint_path(custom_ckpt) == custom_ckpt

    with pytest.raises(FileNotFoundError):
        resolve_checkpoint_path("EXP-999_nonexistent_seed123")


def test_worker_init_fn_reseeds_pipeline_rng(monkeypatch: pytest.MonkeyPatch) -> None:
    sub_tf = SimpleNamespace(rng=np.random.default_rng(1))
    dummy_worker_info = SimpleNamespace(dataset=SimpleNamespace(transform=SimpleNamespace(transforms=[sub_tf])))
    monkeypatch.setattr("torch.utils.data.get_worker_info", lambda: dummy_worker_info)

    init_fn = make_worker_init_fn(123)
    init_fn(1)
    first_draw = sub_tf.rng.random()

    init_fn(1)
    repeat_draw = sub_tf.rng.random()

    init_fn(2)
    other_worker_draw = sub_tf.rng.random()

    assert first_draw == repeat_draw
    assert first_draw != other_worker_draw
