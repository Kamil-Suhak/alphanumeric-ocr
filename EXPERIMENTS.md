# Experiments

All experiments in this repository use **Python 3.14** managed through `uv` (`.python-version` and `pyproject.toml`).

## 1. Environment Setup

1. Install Python dependencies into `.venv`:
   ```bash
   uv sync
   ```
2. Run every script with `uv run python ...` from the repository root (`alphanumeric-ocr/`).

## 2. Shared Data Splits and Seed Rules

- **Dataset:** EMNIST ByClass (`62` classes: digits `0-9`, uppercase `A-Z`, lowercase `a-z`).
- **Fixed training split:** `628,139` indices stored in `experiments/manifests/train_indices.csv`.
- **Fixed validation split:** `69,793` indices stored in `experiments/manifests/val_indices.csv`.
- **Fixed test split:** `116,323` samples from the EMNIST ByClass test partition (never used during training, validation, normalization fitting, or quantization calibration).
- **Training seeds:** `123`, `456`, and `789`.
- **Run directory naming:** Every training directory includes its seed suffix explicitly (`_seed123`, `_seed456`, or `_seed789`).
- **Test-time degradation determinism:** Evaluation transforms generate random parameters from `np.random.default_rng([eval_seed, sample_idx])`, where `eval_seed` defaults to `123`.

---

## 3. Experiment Catalog

### EXP-000: Data Setup, Normalization Statistics, Sample Grids, and Overfit Check

This group of scripts prepares the dataset files, locks the train/validation split, measures normalization constants, writes diagnostic sample grids, and checks training gradient flow on a small subset.

**Steps:**
1. Download the EMNIST ByClass raw IDX files to `data/raw/emnist/`:
   ```bash
   uv run python experiments/scripts/download_emnist_byclass.py
   ```
2. Generate the stratified 90/10 train/validation split manifests (`seed=123`):
   ```bash
   uv run python experiments/scripts/generate_manifests.py
   ```
3. Compute pixel mean and standard deviation on the training manifest:
   ```bash
   uv run python experiments/scripts/compute_normalization.py
   ```
   Output constants recorded in `experiments/src/config.py`: `EMNIST_MEAN = 0.1331`, `EMNIST_STD = 0.2870`.
4. Save visual grids of clean EMNIST orientation correction and synthetic degradations:
   ```bash
   uv run python experiments/scripts/inspect_emnist.py
   uv run python experiments/scripts/inspect_degradations.py
   ```
5. Train `AlphanumericCNN` for `40` epochs on `256` samples (`seed=123`) as a gradient-flow check:
   ```bash
   uv run python experiments/scripts/overfit_tiny_subset.py
   ```

**Outputs:**
- `experiments/manifests/train_indices.csv`, `experiments/manifests/val_indices.csv`
- `experiments/outputs/diagnostics/emnist_samples.png`, `experiments/outputs/diagnostics/degradation_samples.png`

---

### EXP-001: Clean Baseline CNN (`seed123`, `seed456`, `seed789`)

Trains `AlphanumericCNN` (`634,110` parameters) on `2px` zero-padded (`32x32`), normalized EMNIST images with no synthetic degradations applied during training, validation, or final clean test evaluation.

**Configuration:** `experiments/configs/baseline.yaml` (`batch_size=512`, `epochs=25`, `learning_rate=0.001`, `weight_decay=0.0001`, `dropout=0.5`, `blur=false`, `noise=false`, `perspective=false`).

**Steps:**
1. Run training and clean test evaluation for each seed:
   ```bash
   uv run python experiments/scripts/train_baseline.py --seed 123
   uv run python experiments/scripts/train_baseline.py --seed 456
   uv run python experiments/scripts/train_baseline.py --seed 789
   ```
2. Each run initializes all RNGs via `set_seed(<seed>)`, trains for `25` epochs, saves the checkpoint with the lowest validation loss as `best.pt`, plots `training_curve.png`, evaluates `best.pt` on the `116,323` clean test samples, and writes `confusion_matrix.png` and `test_results.json`.

**Outputs:**
- `experiments/outputs/runs/EXP-001_baseline_seed123/` (completed)
- `experiments/outputs/runs/EXP-001_baseline_seed456/` (planned)
- `experiments/outputs/runs/EXP-001_baseline_seed789/` (planned)

---

### EXP-002: Multi-Degradation CNN (`seed123`, `seed456`, `seed789`)

Trains `AlphanumericCNN` with on-the-fly random degradations applied per training sample in the order Perspective -> Gaussian Blur -> Gaussian Noise. Validation and test sets stay clean during this run.

**Configuration:** `experiments/configs/robust.yaml` (`batch_size=512`, `epochs=25`, `learning_rate=0.001`, `weight_decay=0.0001`, `dropout=0.5`, `perspective_prob=0.5` up to `0.25`, `blur_prob=0.5` up to `sigma=2.0`, `noise_prob=0.5` up to `std=0.15`).

**Steps:**
1. Run training and clean test evaluation for each seed:
   ```bash
   uv run python experiments/scripts/train_robust.py --seed 123
   uv run python experiments/scripts/train_robust.py --seed 456
   uv run python experiments/scripts/train_robust.py --seed 789
   ```
2. Each run saves the lowest validation-loss weights to `best.pt` and evaluates on the `116,323` clean test samples.

**Outputs:**
- `experiments/outputs/runs/EXP-002_robust_seed123/` (completed)
- `experiments/outputs/runs/EXP-002_robust_seed456/` (planned)
- `experiments/outputs/runs/EXP-002_robust_seed789/` (planned)

---

### EXP-003: Single-Degradation Ablation — Gaussian Blur (`seed123`)

Trains `AlphanumericCNN` with only Gaussian blur enabled during training, using the same blur probability and upper bound as `EXP-002`.

**Configuration:** `experiments/configs/ablation_blur.yaml` (`seed=123`, `blur_prob=0.5`, `max_sigma=2.0`, `noise_prob=0.0`, `perspective_prob=0.0`).

**Steps:**
1. Run training and clean test evaluation:
   ```bash
   uv run python experiments/scripts/train_robust.py --config experiments/configs/ablation_blur.yaml --seed 123
   ```

**Output:**
- `experiments/outputs/runs/EXP-003_ablation_blur_seed123/` (planned)

---

### EXP-004: Single-Degradation Ablation — Gaussian Noise (`seed123`)

Trains `AlphanumericCNN` with only additive Gaussian noise enabled during training, using the same noise probability and upper bound as `EXP-002`.

**Configuration:** `experiments/configs/ablation_noise.yaml` (`seed=123`, `blur_prob=0.0`, `noise_prob=0.5`, `max_noise_std=0.15`, `perspective_prob=0.0`).

**Steps:**
1. Run training and clean test evaluation:
   ```bash
   uv run python experiments/scripts/train_robust.py --config experiments/configs/ablation_noise.yaml --seed 123
   ```

**Output:**
- `experiments/outputs/runs/EXP-004_ablation_noise_seed123/` (planned)

---

### EXP-005: Single-Degradation Ablation — Perspective Distortion (`seed123`)

Trains `AlphanumericCNN` with only random perspective warping enabled during training, using the same perspective probability and upper bound as `EXP-002`.

**Configuration:** `experiments/configs/ablation_perspective.yaml` (`seed=123`, `blur_prob=0.0`, `noise_prob=0.0`, `perspective_prob=0.5`, `max_perspective_severity=0.25`).

**Steps:**
1. Run training and clean test evaluation:
   ```bash
   uv run python experiments/scripts/train_robust.py --config experiments/configs/ablation_perspective.yaml --seed 123
   ```

**Output:**
- `experiments/outputs/runs/EXP-005_ablation_perspective_seed123/` (planned)

---

### EXP-006: Single-Degradation Parameter Sweeps and Multi-Run Aggregation

Evaluates trained checkpoints across `19` deterministic degradation levels on the `116,323` test images (`eval_seed=123`) and aggregates multi-seed statistics plus the 5-model ablation cross-matrix:
- Gaussian blur (`sigma`): `[0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]`
- Gaussian noise (`std`): `[0.0, 0.05, 0.10, 0.15, 0.20, 0.25]`
- Perspective distortion (`severity`): `[0.0, 0.05, 0.10, 0.15, 0.20, 0.25]`

**Steps:**
1. Run pairwise Seed 123 sweep (`EXP-001_baseline_seed123` vs `EXP-002_robust_seed123`) and write comparative CSVs and plots:
   ```bash
   uv run python experiments/scripts/evaluate.py --clean-run EXP-001_baseline_seed123 --robust-run EXP-002_robust_seed123 --eval-seed 123
   ```
2. Once all `EXP-001`..`EXP-005` checkpoints exist, evaluate per-run sweep CSVs for every checkpoint:
   ```bash
   uv run python experiments/scripts/evaluate.py --runs EXP-001_baseline_seed123 EXP-001_baseline_seed456 EXP-001_baseline_seed789 EXP-002_robust_seed123 EXP-002_robust_seed456 EXP-002_robust_seed789 EXP-003_ablation_blur_seed123 EXP-004_ablation_noise_seed123 EXP-005_ablation_perspective_seed123 --eval-seed 123
   ```
3. Compute mean and sample standard deviation across seeds `[123, 456, 789]` and assemble the 5-model ablation cross-matrix:
   ```bash
   uv run python experiments/scripts/summarize_sweeps.py
   ```

**Outputs:**
- `experiments/outputs/sweeps/by_run/<run_name>/{blur,noise,perspective}.csv`
- `experiments/outputs/sweeps/{blur,noise,perspective}/{blur,noise,perspective}.csv` and `_curve.png`
- `experiments/outputs/tables/multi_seed_summary.json`, `experiments/outputs/tables/ablation_cross_matrix.json` (generated by `summarize_sweeps.py`)

---

### EXP-007: Grad-CAM Spatial Feature Attribution

Generates Grad-CAM heatmaps from layer `features[8]` (`Conv2d(64, 128)`) for four test characters (`A`, `8`, `B`, `0`) under five deterministic inputs (`Clean`, `Blur s=1.5`, `Blur s=2.5`, `Noise std=0.20`, `Persp s=0.25`) comparing `EXP-001_baseline_seed123` and `EXP-002_robust_seed123`.

**Steps:**
1. Run Grad-CAM visualization script:
   ```bash
   uv run python experiments/scripts/generate_gradcam.py --model-a EXP-001_baseline_seed123 --model-b EXP-002_robust_seed123 --eval-seed 123
   ```

**Output:**
- `experiments/outputs/diagnostics/gradcam_comparison.png`

---

### EXP-008: Native FP32 Hardware Profiling and ONNX Static INT8 Benchmark

Measures parameter counts, weight sizes, CPU/GPU latency (`batch=1` and `batch=32`), and throughput for PyTorch FP32, then exports `EXP-002_robust_seed123` to ONNX FP32 and runs ONNX Runtime static QDQ INT8 quantization calibrated on `1,000` samples from `experiments/manifests/val_indices.csv`, measuring latency, model size, and test accuracy on `clean`, `blur=2.0`, `noise=0.20`, and `perspective=0.25`.

**Steps:**
1. Measure native PyTorch FP32 parameters, file sizes, and batch latency:
   ```bash
   uv run python experiments/scripts/benchmark_practicality.py --run EXP-001_baseline_seed123
   ```
2. Export ONNX FP32 and ONNX INT8 models, benchmark CPU inference (`100` warmup runs, `1,000` timed iterations), and evaluate quantized accuracy:
   ```bash
   uv run python experiments/scripts/benchmark_edge_optimization.py --run EXP-002_robust_seed123 --calib-samples 1000 --eval-seed 123
   ```

**Outputs:**
- `experiments/outputs/tables/practicality.json` (completed for `EXP-001_baseline_seed123`)
- `experiments/outputs/tables/edge_practicality.json`
- `experiments/outputs/runs/EXP-002_robust_seed123/onnx/model_fp32.onnx`, `model_int8.onnx`

---

### EXP-009: Compounded Multi-Degradation Tiers and Horizontal Motion Blur OOD

Evaluates frozen checkpoints on two test-only benchmarks (`eval_seed=123`):
1. Simultaneous `Perspective -> Blur -> Noise` across three severity tiers:
   - `tier_1_mild`: `perspective=0.08`, `blur=0.8`, `noise=0.04`
   - `tier_2_moderate`: `perspective=0.15`, `blur=1.5`, `noise=0.08`
   - `tier_3_harsh`: `perspective=0.22`, `blur=2.2`, `noise=0.14`
2. Horizontal motion blur (`angle=0.0` degrees) across kernel lengths `[3, 5, 7, 9, 11]` pixels (a blur distribution not used during training).

**Steps:**
1. Run compounded multi-degradation benchmark:
   ```bash
   uv run python experiments/scripts/evaluate_compounded_stress.py --runs EXP-001_baseline_seed123 EXP-002_robust_seed123 --eval-seed 123
   ```
2. Run horizontal motion blur benchmark (add `EXP-003_ablation_blur_seed123` once trained):
   ```bash
   uv run python experiments/scripts/evaluate_motion_blur_ood.py --runs EXP-001_baseline_seed123 EXP-002_robust_seed123 EXP-003_ablation_blur_seed123 --eval-seed 123
   ```

**Outputs:**
- `experiments/outputs/tables/compounded_stress.json`
- `experiments/outputs/tables/motion_blur_ood.json`
- `experiments/outputs/sweeps/motion_blur/motion_blur_curve.png`
- `experiments/outputs/sweeps/by_run/<run_name>/motion_blur.csv`

---

### EXP-010: Error Stratification Quadrants and Homoglyph Breakdown

Compares per-sample predictions of `EXP-001_baseline_seed123` and `EXP-002_robust_seed123` on the `clean` and `tier_2_moderate` test sets, groups every sample into four agreement/error quadrants (`a_fail_b_pass`, `a_pass_b_fail`, `both_fail`, `both_pass`), computes error shares for the `15` case-ambiguous pairs and digit/letter lookalike groups (`0/O/o`, `1/I/l`, `2/Z/z`, `5/S/s`, `8/B`, `9/q/g`), and plots `16` quadrant examples (`4` per quadrant).

**Steps:**
1. Run error stratification and homoglyph analysis:
   ```bash
   uv run python experiments/scripts/export_error_diagnostics.py --model-a EXP-001_baseline_seed123 --model-b EXP-002_robust_seed123 --eval-seed 123
   ```

**Outputs:**
- `experiments/outputs/tables/error_stratification.csv`
- `experiments/outputs/tables/homoglyph_breakdown.json`
- `experiments/outputs/diagnostics/error_quadrants.png`
