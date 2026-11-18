import numpy as np
from PIL import Image
import pytest
import torch

from src.data.transforms import (
    COMPOUND_STRESS_TIERS,
    MOTION_BLUR_KERNEL_SIZES,
    DegradationPipeline,
    apply_compound_degradation,
    apply_motion_blur,
)
from src.experiments.degradation_sweep import ControlledDegradationDataset, build_degradation_fn


class DummyPilDataset:
    """Minimalny zbiór testowy PIL 28x28 dla testów jednostkowych degradacji."""

    def __init__(self, count: int = 8):
        rng = np.random.default_rng(999)
        self.samples = []
        for idx in range(count):
            arr = rng.integers(0, 255, size=(28, 28), dtype=np.uint8)
            self.samples.append((Image.fromarray(arr, mode="L"), idx % 62))

    def __len__(self) -> int:
        return len(self.samples)

    def __getitem__(self, idx: int):
        return self.samples[idx]


def test_apply_motion_blur_horizontal_direction_and_bounds() -> None:
    impulse = np.zeros((32, 32), dtype=np.float32)
    impulse[16, 16] = 1.0

    for ksize in MOTION_BLUR_KERNEL_SIZES:
        blurred = apply_motion_blur(impulse, kernel_size=ksize, angle_deg=0.0)
        assert blurred.shape == (32, 32)
        assert float(blurred.min()) >= 0.0
        assert float(blurred.max()) <= 1.0
        # Horizontal kernel spreads along row 16 only
        assert np.allclose(blurred[15, :], 0.0, atol=1e-6)
        assert np.allclose(blurred[17, :], 0.0, atol=1e-6)
        assert float(blurred[16, :].sum()) == pytest.approx(1.0, abs=1e-4)
        assert int(np.count_nonzero(blurred[16, :] > 1e-4)) == ksize


def test_apply_compound_degradation_is_seeded_and_bounded() -> None:
    rng_data = np.random.default_rng(7)
    img = rng_data.uniform(0.0, 1.0, size=(32, 32)).astype(np.float32)
    tier = COMPOUND_STRESS_TIERS["tier_2_moderate"]

    out_a = apply_compound_degradation(
        img,
        perspective=tier["perspective"],
        blur_sigma=tier["blur"],
        noise_std=tier["noise"],
        rng=np.random.default_rng([123, 4]),
    )
    out_b = apply_compound_degradation(
        img,
        perspective=tier["perspective"],
        blur_sigma=tier["blur"],
        noise_std=tier["noise"],
        rng=np.random.default_rng([123, 4]),
    )
    out_c = apply_compound_degradation(
        img,
        perspective=tier["perspective"],
        blur_sigma=tier["blur"],
        noise_std=tier["noise"],
        rng=np.random.default_rng([456, 4]),
    )

    assert out_a.shape == (32, 32)
    assert out_a.dtype == np.float32
    assert 0.0 <= float(out_a.min()) <= float(out_a.max()) <= 1.0
    assert np.array_equal(out_a, out_b)
    assert not np.array_equal(out_a, out_c)


def test_controlled_degradation_dataset_is_pixel_deterministic() -> None:
    raw = DummyPilDataset(count=4)
    compound_fn = build_degradation_fn("compound", COMPOUND_STRESS_TIERS["tier_3_harsh"])
    assert compound_fn is not None

    ds_first = ControlledDegradationDataset(raw, degradation_fn=compound_fn, seed=123)
    ds_second = ControlledDegradationDataset(raw, degradation_fn=compound_fn, seed=123)
    ds_other_seed = ControlledDegradationDataset(raw, degradation_fn=compound_fn, seed=789)

    for idx in range(len(raw)):
        t1, y1 = ds_first[idx]
        t2, y2 = ds_second[idx]
        t3, _ = ds_other_seed[idx]
        assert y1 == y2
        assert t1.shape == (1, 32, 32)
        assert torch.equal(t1, t2)
        assert not torch.equal(t1, t3)


def test_build_degradation_fn_variants_and_invalid_type() -> None:
    assert build_degradation_fn("clean", 0.0) is None
    assert build_degradation_fn("blur", 0.0) is None
    assert build_degradation_fn("blur", 1.5) is not None
    assert build_degradation_fn("noise", 0.15) is not None
    assert build_degradation_fn("perspective", 0.25) is not None
    assert build_degradation_fn("motion_blur", 5) is not None
    assert build_degradation_fn("compound", COMPOUND_STRESS_TIERS["tier_1_mild"]) is not None

    with pytest.raises(ValueError, match="Unsupported degradation_type"):
        build_degradation_fn("glare", 0.5)


def test_degradation_pipeline_preserves_model_b_rng_and_supports_motion_blur() -> None:
    arr = np.zeros((32, 32), dtype=np.uint8)
    arr[12:20, 12:20] = 255
    img = Image.fromarray(arr)

    pipe_default = DegradationPipeline(seed=123)
    pipe_explicit_zero = DegradationPipeline(motion_blur_prob=0.0, seed=123)
    out_default = np.asarray(pipe_default(img))
    out_zero = np.asarray(pipe_explicit_zero(img))
    assert np.array_equal(out_default, out_zero)
    assert pipe_default.rng.bit_generator.state == pipe_explicit_zero.rng.bit_generator.state

    # With motion_blur_prob=1.0 and other probs=0.0, horizontal blur spreads center row into adjacent columns
    pipe_motion = DegradationPipeline(
        blur_prob=0.0,
        noise_prob=0.0,
        perspective_prob=0.0,
        motion_blur_prob=1.0,
        motion_blur_kernels=(5,),
        seed=123,
    )
    out_motion = np.asarray(pipe_motion(img))
    assert out_motion.shape == (32, 32)
    assert out_motion.dtype == np.uint8
    assert out_motion[16, 10] > 0
    assert not np.array_equal(out_motion, arr)
