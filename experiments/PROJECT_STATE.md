# Project State: Alphanumeric Character Classification & CNN Robustness Benchmark

Comprehensive reference document for AI agents and project contributors detailing research objectives, architecture, experimental progress, and upcoming phases.

---

## 1. Project Purpose & Central Research Question

This project addresses the problem of **isolated 62-class alphanumeric character classification** (digits 0-9, uppercase A-Z, lowercase a-z) from single grayscale image patches of size 32x32 pixels.

### Central Research Question:
> *How does training a compact convolutional neural network (CNN) with simulated environmental degradations affect alphanumeric character recognition accuracy under degraded image conditions?*

### Core Hypotheses:
1. **Clean Baseline Vulnerability (Model A - Clean):** A model trained solely on clean EMNIST data achieves high accuracy under ideal conditions, but its recognition collapses sharply under increasing levels of blur, sensor noise, and perspective distortion.
2. **Degradation-Aware Invariance (Model B - Robust):** Augmenting training data with synthetic degradations shifts the model's feature representations, significantly improving robustness and raising the degradation threshold before catastrophic accuracy collapse occurs.
3. **Intrinsic Class Ambiguity:** A non-trivial fraction of classification error (~3-4%) is mathematically unavoidable on isolated 32x32 crops due to the intrinsic visual equivalence of 15 character pairs (e.g., C/c, O/o, S/s, 0/O, 1/l) without x-height or baseline reference context.

---

## 2. Project Standards & Conventions

* **Codebase Language:** All function names, variable names, classes, methods, filenames, and directory paths are in English.
* **In-Code Comments & Docstrings:** Concise, academic Polish (as specified in project guidelines, avoiding slang).
* **AI Agent / Project Documentation:** English (as maintained in this document).
* **Determinism:** All pseudorandom generators (PyTorch, NumPy, Python, CuDNN) are seeded via `set_seed(123)` in `src/seed.py`.
* **Test Set Isolation:** The official EMNIST test set (116,323 samples) is strictly frozen and used exclusively for final, untouched evaluation.
* **Persistent Dataset Manifests:** The 90/10 train/validation split of the official NIST training set is permanently stored on disk:
  - `data/manifests/train_indices.csv` (628,139 samples)
  - `data/manifests/val_indices.csv` (69,794 samples)
* **Model Checkpointing:** Only the model achieving the minimum validation loss is saved to disk as `best.pt`, protecting test results from late-stage overfitting.

---

## 3. Directory Structure & Module Responsibilities

```text
alphanumeric-ocr/
│
├── configs/
│   ├── baseline.yaml             # Model A configuration (Clean Baseline, EXP-001)
│   └── robust.yaml               # Model B configuration (Robust CNN, EXP-002)
│
├── data/
│   ├── manifests/                # Persistent split indices (train_indices.csv, val_indices.csv)
│   ├── raw/emnist/EMNIST/raw/    # Extracted EMNIST ByClass binary files
│   ├── raw/chars74k/             # Cross-dataset generalization data (upcoming)
│   └── raw/photos/               # Real-world smartphone character crops (upcoming)
│
├── src/
│   ├── config.py                 # Global filesystem paths and empirical normalization constants
│   ├── seed.py                   # Multi-framework random seed initialization
│   ├── data/
│   │   ├── emnist.py             # 62-class mapping, orientation fix, dataset wrappers, manifest loader
│   │   └── transforms.py         # Degradation engine: Gaussian blur, Gaussian noise, perspective distortion
│   ├── models/
│   │   └── cnn.py                # AlphanumericCNN architecture definition
│   ├── training/
│   │   ├── train.py              # Epoch training routines and metrics.csv logging
│   │   └── evaluate.py           # Evaluation runner returning metrics, confusion matrix, and predictions
│   ├── experiments/
│   │   └── degradation_sweep.py  # Automated evaluation sweeps across discrete degradation severities
│   └── utils/
│       ├── metrics.py            # Accuracy, Macro-F1, Confusion Matrix, and Case-Insensitive Accuracy
│       ├── plotting.py           # Matplotlib generators for loss/acc curves and confusion matrices
│       └── checkpoint.py         # PyTorch model state saving and loading helpers
│
├── scripts/
│   ├── download_emnist_byclass.py   # Selective download and decompression of ByClass files (~120 MB)
│   ├── compute_normalization.py     # Measures empirical mean and std on 90% training split
│   ├── generate_manifests.py        # Generates train/validation split manifest CSV files
│   ├── inspect_emnist.py            # Generates visual orientation check grid (emnist_samples.png)
│   ├── overfit_tiny_subset.py       # Memorization test on 256 samples (>98% acc smoke test)
│   ├── inspect_degradations.py      # Generates visual degradation grid (degradation_samples.png)
│   ├── train_baseline.py            # Driver script for clean baseline model (EXP-001)
│   ├── train_robust.py              # Driver script for robust degraded model (EXP-002)
│   ├── evaluate.py                  # Comparative sweep runner between Model A and Model B
│   ├── benchmark_practicality.py    # Hardware profiling script (latency, params, model file size)
│   └── zip_project.py               # Bundles project for cloud training (Google Colab / Kaggle)
│
└── results/
    ├── figures/                     # Verification plots (emnist_samples.png, degradation_samples.png)
    ├── runs/
    │   ├── EXP-001/                 # Clean baseline run artifacts (best.pt, training_curve.png, confusion_matrix.png, metrics.csv, test_results.json)
    │   └── EXP-002/                 # Robust model run artifacts (upcoming)
    └── robustness/                  # Comparative sweep curves and tables (blur_curve.png, etc.)
```

---

## 4. Model Architecture (AlphanumericCNN)

A compact convolutional neural network designed for high throughput and embedded deployment:

* **Input:** Grayscale single-channel image tensor: `1 x 32 x 32`
* **Stage 1:** Conv2D (1 -> 32, k=3, p=1) + BatchNorm2D + ReLU + MaxPool2D (stride=2) -> `32 x 16 x 16`
* **Stage 2:** Conv2D (32 -> 64, k=3, p=1) + BatchNorm2D + ReLU + MaxPool2D (stride=2) -> `64 x 8 x 8`
* **Stage 3:** Conv2D (64 -> 128, k=3, p=1) + BatchNorm2D + ReLU + MaxPool2D (stride=2) -> `128 x 4 x 4`
* **Classifier Head:**
  - Flatten: `128 * 4 * 4 = 2048` features
  - Linear (2048 -> 256) + BatchNorm1D + ReLU + Dropout (p = 0.5)
  - Linear (256 -> 62 classes)
* **Total Parameters:** 200,030 parameters (~7.6 MB on disk with optimizer states in float32).

---

## 5. Phase Completion & Experimental Findings

### Phase 0: Environment & Repository Structure
* Modular directory hierarchy established matching academic reporting guidelines.
* Reproducibility locked with `seed.py` (seed = 123).
* Comprehensive `.gitignore` configured to exclude raw datasets, virtual environments, archives, and model weights.

### Phase 1: EMNIST ByClass Loader & Data Verification
* Selective download implemented: downloaded only 5 ByClass binary files (~120 MB) instead of the full 535 MB NIST archive.
* Solved the raw EMNIST storage orientation quirk via `Image.Transpose.TRANSPOSE`.
* **Zero-Padding (28x28 -> 32x32):** Standardized on `T.Pad(padding=2, fill=0)` (2px black padding on all sides) rather than bilinear interpolation resizing (`Resize((32, 32))`). This preserves 100% of raw stroke fidelity without anti-aliasing blur and replicates the classical LeNet-5 spatial framing.
* Empirical normalization computed on the 90% training split with 2px zero padding:
  - Mean: `0.1331`
  - Standard Deviation: `0.2870`
  (Avoiding blindly copying standard MNIST constants 0.1307 / 0.3081).
* Generated `results/figures/emnist_samples.png` visually confirming upright characters and correct labels across digits, uppercase, and lowercase characters.

### Phase 2: CNN Architecture & Memorization Check
* Implemented `AlphanumericCNN` in `src/models/cnn.py`.
* Executed `scripts/overfit_tiny_subset.py` on 256 samples: achieved >98% accuracy in 40 epochs, confirming correct gradient flow and backward pass before running full training.

### Phase 3: Clean Baseline Model (EXP-001) — COMPLETED
Trained on Kaggle (GPU, batch_size=512, AdamW lr=1e-3, weight_decay=1e-4, 25 epochs, 2px zero padding):
* **Best Validation Epoch:** Reached at **Epoch 11** (Validation Loss: **0.3328**, Validation Accuracy: **87.46%**).
* **Final Evaluation on Untouched Clean Test Set (116,323 samples):**
  - **Top-1 Accuracy:** **87.62%**
  - **Case-Insensitive Accuracy:** **90.96%** (+3.34% improvement when unifying the 15 ambiguous case pairs)
  - **Macro Precision:** 80.59%
  - **Macro Recall:** 75.30%
  - **Macro-F1:** **75.59%**
* **Artifacts:** Checkpoint and plots saved in `results/runs/EXP-001/`.

### Phase 4: Degradation Simulator Engine
Implemented in `src/data/transforms.py`:
* **Gaussian Blur:** Continuous sigma parameter (`BLUR_SEVERITY_LEVELS`: 0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0).
* **Sensor Noise:** Additive Gaussian noise (`NOISE_SEVERITY_LEVELS`: 0.00, 0.03, 0.06, 0.10, 0.15, 0.20).
* **Perspective Distortion:** Homography corner displacement (`PERSPECTIVE_SEVERITY_LEVELS`: 0%, 5%, 10%, 15%, 20%, 25%).
* Visual verification plot saved at `results/figures/degradation_samples.png`.

### Phase 5: Robust CNN Model (EXP-002) — COMPLETED
Trained on Kaggle with synthetic degradations applied on-the-fly (blur sigma<=2.0, noise std<=0.15, perspective severity<=0.25):
* **Training Dynamics:** Data augmentations acted as a powerful regularizer, preventing late-stage overfitting. Validation loss continued improving through **Epoch 25** (Validation Loss: **0.3326**, Validation Accuracy: **87.43%**).
* **Clean Test Set Performance (116,323 samples):**
  - **Top-1 Accuracy:** **87.46%** (-0.16% vs clean baseline on pristine data)
  - **Case-Insensitive Accuracy:** **90.88%** (-0.08% vs clean baseline)
  - **Macro Precision:** 82.07%
  - **Macro Recall:** 74.56%
  - **Macro-F1:** **74.58%**
* **Artifacts:** Checkpoint and plots saved in `results/runs/EXP-002/`.

### Phase 6: Comparative Robustness Sweeps — COMPLETED
Executed across all 116,323 test samples across 19 severity points (Blur: 7, Noise: 6, Perspective: 6):
* **Gaussian Blur:** Model A collapsed below 50% at $\sigma \approx 1.25$ and crashed to **4.28%** at $\sigma=3.00$. Model B retained **64.44%** at $\sigma=3.00$ (a **+60.16%** advantage) and never dropped below 50%.
* **Sensor Noise:** Model B maintained near-complete invariance (**87.46% -> 86.59%**, a drop of <0.9%). Model A plunged to **37.65%** at std=0.20 (Model B advantage: **+48.94%**).
* **Perspective Distortion:** Model B degraded gracefully (**87.46% -> 82.83%**), outperforming Model A (64.36%) by **+18.47%** at 25% displacement.
* **Artifacts:** Saved in `results/robustness/` (`blur_curve.png`, `noise_curve.png`, `perspective_curve.png`, `blur.csv`, `noise.csv`, `perspective.csv`).

### Phase 9: Hardware Practicality Profiling — COMPLETED
Measured across batch=1 and batch=32 on CPU and GPU:
* **Model Parameters:** 634,110 (all trainable).
* **Memory Footprint:** FP32 inference weights: **2.42 MB**; full checkpoint with optimizer state: **7.28 MB**.
* **CPU Latency & Throughput:**
  - Batch = 1: **1.08 ms** / char (~927 chars/sec).
  - Batch = 32: **15.08 ms** (~0.47 ms / char, **2,123 chars/sec**).
* **GPU Latency & Throughput (NVIDIA T4 / P100):**
  - Batch = 1: **0.59 ms** / char.
  - Batch = 32: **0.69 ms** (~0.02 ms / char, **46,172 chars/sec**).
* **Artifacts:** Saved in `results/tables/practicality.json`.

---

## 6. Current Status & Next Execution Steps

### In Progress:
* **Milestone Report Authoring:** Structuring the comprehensive 6-page milestone report for the thesis supervisor summarizing theoretical motivation, model architecture, baseline vs. robust training curves, ambiguity analysis, and practical embedded viability.

### Immediate Next Tasks:
1. **Draft Milestone Report:** Create structured outline and LaTeX / Markdown draft synthesizing empirical metrics, confusion matrices, and the robustness triad.
2. **Phase 7 (Real-World Photographs):** Prepare pipeline for smartphone photo character crops and evaluation under real-world domain shifts.
3. **Phase 8 (Chars74k Generalization):** Benchmark cross-dataset transfer on the Chars74k dataset.
4. **Phase 10 (EasyOCR Benchmark & Deployment):** Execute isolated character comparison against EasyOCR and test ONNX export.
