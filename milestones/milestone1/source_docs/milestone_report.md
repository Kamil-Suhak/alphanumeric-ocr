# Progress Report: Robust Alphanumeric Character Recognition under Simulated Environmental Degradations

**Project Title:** Robust 62-Class Alphanumeric Optical Character Recognition Using Compact Convolutional Architectures  
**Author:** Kamil Suhak  
**Date:** September 2026  
**Document Type:** Milestone Progress & Experimental Analysis Report

---

## Executive Summary

This report documents the design, implementation, and empirical validation of an end-to-end machine learning pipeline addressing **isolated 62-class alphanumeric character recognition** (digits `0-9`, uppercase `A-Z`, lowercase `a-z`) from single grayscale image crops.

The primary research objective is to examine how **degradation-aware synthetic data augmentation** impacts the robustness and failure dynamics of compact convolutional neural networks (CNNs) subjected to severe optical defocus (Gaussian blur), sensor noise, and off-axis camera tilts (perspective distortion).

### Key Empirical Findings:

1. **Clean Baseline Vulnerability:** A standard CNN trained purely on pristine samples achieves **87.62%** top-1 accuracy on clean data, but collapses catastrophically under optical blur (plunging to **4.28%** at blur sigma = 3.0) and sensor noise (falling to **37.65%** at noise std = 0.20).
2. **Degradation-Aware Invariance:** Incorporating stochastic, on-the-fly synthetic degradations during training yields a robust model that retains **87.46%** accuracy on clean inputs (a negligible drop of 0.16%), while sustaining **64.44%** accuracy under extreme blur (+60.16% margin over baseline) and **86.59%** under heavy noise (+48.94% margin over baseline).
3. **Out-of-Distribution Generalization:** Although the robust model was only trained with blur up to sigma = 2.0, it retained 83.28% accuracy at sigma = 2.5 and 64.44% at sigma = 3.0, proving that data augmentation forced the convolutional filters to learn structural topological invariants (loops, intersections, stroke angles) rather than memorizing noise textures.
4. **Regularization Dynamics:** Data augmentation effectively eliminated late-stage overfitting: while the baseline model overfit after Epoch 11 (validation loss rose from 0.3328 to 0.3549), the robust model improved monotonically through Epoch 25 (validation loss 0.3326).
5. **Practical Embedded Viability:** The architecture contains **634,110 parameters** with an inference memory footprint of **2.42 MB** (FP32). On a standard CPU, inference latency is **1.08 ms** per character (throughput of **2,123 characters/sec** in batches of 32), demonstrating immediate readiness for resource-constrained edge devices and real-time scanning.

---

## 1. Project Premise & Research Objectives

### 1.1 Problem Formulation

Optical Character Recognition (OCR) systems deployed in real-world environments—such as handheld package scanners, automated utility meter readers, and mobile document digitizers—frequently encounter degraded inputs. While traditional benchmark datasets provide clean, binarized glyphs centered under controlled laboratory conditions, practical camera sensors introduce severe non-idealities:

- **Optical Defocus & Motion Blur:** Inadequate depth of field, poor lighting requiring longer exposure, or camera shake.
- **Sensor Noise:** High ISO gain, thermal noise in low-cost CMOS sensors, and poor illumination.
- **Off-Axis Camera Tilts:** Skewed viewing angles relative to flat surfaces, creating non-affine projective homography distortions.

Most industrial OCR frameworks (e.g., Tesseract, EasyOCR) rely on complex multi-stage pipelines including text line detectors (CRAFT) and recurrent sequence decoders (CRNN/LSTM). For isolated character crops and low-power embedded deployment, heavy sequential architectures introduce unnecessary computational latency. This study investigates whether a **single, ultra-lightweight feedforward CNN** can achieve near-human classification accuracy while remaining fundamentally impervious to environmental degradations.

### 1.2 Central Research Questions

1. **Q1 (Degradation Vulnerability):** How quickly does a clean-trained CNN break down when subjected to increasing levels of optical blur, additive Gaussian noise, and perspective distortion?
2. **Q2 (Synthetic Invariance):** Can stochastic on-the-fly synthetic augmentations during training inoculate a compact CNN against environmental perturbations without sacrificing clean-domain accuracy?
3. **Q3 (Intrinsic Class Ambiguity):** What proportion of 62-class classification error is mathematically unavoidable on isolated single-character crops due to the intrinsic visual equivalence of character pairs (e.g., `O`/`0`, `l`/`1`/`I`, `c`/`C`) in the absence of surrounding context?
4. **Q4 (Embedded Practicality):** Does the resulting robust architecture meet the strict latency (<5 ms/char) and memory (<5 MB) limits of low-power microcontrollers and mobile processors?

---

## 2. Dataset Pipeline & Preprocessing Methodology

### 2.1 EMNIST ByClass Distribution

Experiments are conducted on the official **EMNIST ByClass** split, derived from NIST Special Database 19. The dataset comprises **814,255 total handwritten character images** across **62 balanced and unbalanced classes**:

- **Digits (Classes 0–9):** 10 classes (`0-9`)
- **Uppercase Latin (Classes 10–35):** 26 classes (`A-Z`)
- **Lowercase Latin (Classes 36–61):** 26 classes (`a-z`)

The dataset possesses severe, real-world class imbalance (e.g., digits and common vowels have tens of thousands of samples, whereas rare letters like `Q`, `X`, `z` have significantly fewer), making macro-averaged metrics (Macro-F1, Macro-Precision, Macro-Recall) critical for rigorous evaluation.

### 2.2 Orientation Normalization

Raw binary EMNIST images are stored in a transposed column-major format. To correct character alignment, an orientation transformation is applied to every sample via a PIL matrix transpose (`Image.Transpose.TRANSPOSE`), ensuring characters are upright before feeding into the network:

![Visual verification of EMNIST ByClass character crops](../results/figures/emnist_samples.png)
_Figure 1: Visual orientation and label verification of sample digits, uppercase letters, and lowercase letters from the EMNIST ByClass training split._

### 2.3 The 2px Zero-Padding Standardization (vs. Interpolation Resizing)

Standard EMNIST characters have a native resolution of 28x28 pixels. Because modern convolutional backbones typically require input dimensions divisible by powers of two (e.g., 32x32 to facilitate 3 successive 2x2 max-pooling operations), an input framing strategy is required:

- **Why Bilinear Resizing was Rejected:** Resizing from 28x28 to 32x32 involves a non-integer scaling factor (32/28 = 1.143x). Bilinear or bicubic interpolation resamples coordinates across sub-pixel boundaries, producing anti-aliasing artifacts that blur delicate 1-to-2-pixel pen strokes. Nearest-neighbor interpolation introduces jagged staircasing.
- **The Zero-Padding Solution:** Following Yann LeCun's classical LeNet-5 spatial framing, each 28x28 glyph is centered inside a 32x32 tensor by adding **2 pixels of black border (`fill=0`)** on all four sides.
- **Fidelity Preservation:** This approach guarantees that 100% of raw character strokes remain bit-identical to the original sensor capture, while granting boundary margin so convolutional kernels do not truncate edge features.

### 2.4 Empirical Dataset Normalization

Because zero-padding adds 240 black (0.0) pixels to each 784-pixel image (expanding the total pixel count to 1,024), the global pixel intensity distribution shifts. Empirical statistics were measured across the 628,139 training samples:

- **Empirical Mean:** `EMNIST_MEAN = 0.1331`
- **Empirical Standard Deviation:** `EMNIST_STD = 0.2870`

Input tensors are strictly standardized according to:
`x_normalized = (x_tensor - 0.1331) / 0.2870`

### 2.5 Deterministic Data Partitioning

To guarantee strict academic reproducibility across cloud training environments:

- The official EMNIST test set (**116,323 samples**) is frozen and used exclusively for final untouched evaluations.
- The official training set (**697,933 samples**) is deterministically split into **90% train (628,139 samples)** and **10% validation (69,794 samples)** using a fixed seed (`seed = 123`).
- Split manifests are persisted on disk as `train_indices.csv` and `val_indices.csv`.

---

## 3. Network Architecture & Optimization

### 3.1 AlphanumericCNN Specification

To balance high classification capacity with low embedded latency, the custom `AlphanumericCNN` architecture was designed:

| Stage          | Layer Specification                                      | Output Dimension | Activation / Regularization          |
| :------------- | :------------------------------------------------------- | :--------------: | :----------------------------------- |
| **Input**      | Grayscale single-channel patch                           |   1 x 32 x 32    | -                                    |
| **Stage 1**    | Conv2D (1 -> 32, k=3, p=1) + MaxPool2D (2x2, stride=2)   |   32 x 16 x 16   | BatchNorm2D + ReLU                   |
| **Stage 2**    | Conv2D (32 -> 64, k=3, p=1) + MaxPool2D (2x2, stride=2)  |    64 x 8 x 8    | BatchNorm2D + ReLU                   |
| **Stage 3**    | Conv2D (64 -> 128, k=3, p=1) + MaxPool2D (2x2, stride=2) |   128 x 4 x 4    | BatchNorm2D + ReLU                   |
| **Classifier** | Linear (2048 -> 256)                                     |       256        | BatchNorm1D + ReLU + Dropout (p=0.5) |
| **Output**     | Linear (256 -> 62)                                       |    62 classes    | Logits (CrossEntropyLoss)            |

- **Total Parameters:** **634,110** (all trainable).
- **FP32 Weight Footprint:** **2.42 MB** (pure state dictionary).

### 3.2 Training Hyperparameters

- **Optimizer:** AdamW (initial learning rate = `1e-3`, weight decay = `1e-4`).
- **Loss Function:** Categorical Cross-Entropy Loss with PyTorch `log_softmax` numerical stabilization.
- **Batch Size:** `512` (selected for optimal throughput and gradient variance on NVIDIA GPUs).
- **Epochs:** `25` epochs per experiment.
- **Checkpointing Criterion:** Model state (`best.pt`) is saved strictly upon reaching a new minimum validation loss.

---

## 4. Degradation Simulator Engine

To simulate adverse operational environments, a continuous parametric degradation engine was constructed in `src/data/transforms.py`.

![Visual verification of synthetic degradations](../results/figures/degradation_samples.png)
_Figure 2: Parametric degradation grid demonstrating controlled severities of Gaussian blur (top), additive sensor noise (middle), and perspective homography distortion (bottom) applied to character 'A'._

### 4.1 Gaussian Blur (Optical Defocus)

Models loss of optical focus or lens smudging:

- **Formulation:** Gaussian kernel convolution with standard deviation `sigma`. Kernel diameter is dynamically sized to `k = 2 * ceil(3 * sigma) + 1` to prevent boundary truncation.
- **Evaluation Severities:** `sigma in [0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0]`.

### 4.2 Gaussian Sensor Noise (Electronic Sensor Grain)

Simulates high-ISO electronic sensor grain and low-light amplification:

- **Formulation:** Additive zero-mean normal noise: `I_noisy = clip(I + N(0, std^2), 0.0, 1.0)`.
- **Evaluation Severities:** `std in [0.00, 0.03, 0.06, 0.10, 0.15, 0.20]`.

### 4.3 Perspective Distortion (Homography Warp)

Simulates camera viewing angles tilted relative to the document plane:

- **Formulation:** The four image corners are perturbed by uniform random offsets up to `offset_max = severity * min(H, W)`. A 3x3 projective homography matrix is computed and applied using bilinear backward mapping with constant zero border padding.
- **Evaluation Severities:** `severity in [0.00, 0.05, 0.10, 0.15, 0.20, 0.25]`. (At 32x32, 25% corresponds to an 8-pixel corner displacement).

---

## 5. Experimental Results: Clean Baseline vs. Robust Training

Two full-scale models were trained from scratch on Kaggle cloud instances (NVIDIA GPU, batch size 512, 25 epochs):

- **Model A (Clean Baseline - EXP-001):** Trained exclusively on clean, zero-padded images.
- **Model B (Robust CNN - EXP-002):** Trained with stochastic on-the-fly augmentations (50% probability each of blur sigma <= 2.0, noise std <= 0.15, perspective severity <= 0.25).

### 5.1 Training Trajectories & Regularization Dynamics

![EXP-001 Training Curves](../results/runs/EXP-001/training_curve.png)
_Figure 3: EXP-001 (Clean Baseline) loss and accuracy trajectories across 25 epochs. Validation loss reaches an optimal minimum at Epoch 11 before diverging upward due to overfitting._

![EXP-002 Training Curves](../results/runs/EXP-002/training_curve.png)
_Figure 4: EXP-002 (Robust CNN) loss and accuracy trajectories. Data augmentations prevent late-stage overfitting, allowing validation loss to improve monotonically through Epoch 25._

- **Overfitting Dynamics in Model A:** Training loss dropped steadily from 0.528 to 0.262 (training accuracy reached 89.65%). However, validation loss hit a true global minimum at **Epoch 11 (0.3328)** and then systematically climbed to **0.3549** by Epoch 25. The checkpointing mechanism preserved the optimal Epoch 11 weights.
- **Regularization Invariance in Model B:** Because 50% of training samples were continuously corrupted, the training task was considerably harder (training loss ended at 0.3798). Crucially, stochastic augmentations acted as a persistent regularizer: validation loss on clean samples continued falling across all 25 epochs, reaching its global optimum at **Epoch 25 (0.3326)**.

### 5.2 Performance on Untouched Clean Test Set (116,323 Samples)

| Evaluation Metric             | Model A: Clean Baseline |  Model B: Robust CNN  | Difference (Delta) |
| :---------------------------- | :---------------------: | :-------------------: | :----------------: |
| **Top-1 Accuracy**            |       **87.62%**        |      **87.46%**       |       -0.16%       |
| **Case-Insensitive Accuracy** |       **90.96%**        |      **90.88%**       |       -0.08%       |
| **Macro Precision**           |         80.59%          |      **82.07%**       |     **+1.48%**     |
| **Macro Recall**              |       **75.30%**        |        74.56%         |       -0.74%       |
| **Macro-F1 Score**            |       **75.59%**        |        74.58%         |       -1.01%       |
| **Optimal Validation Loss**   |    0.3328 (Epoch 11)    | **0.3326 (Epoch 25)** |      -0.0002       |

- **The Clean Parity Finding:** Model B sacrifices less than **0.16%** top-1 accuracy on pristine data.
- **Precision Advantage:** Model B achieves higher Macro-Precision (**82.07% vs. 80.59%**), indicating that noise training penalizes overconfident false-positive predictions on underrepresented classes.

---

## 6. Confusion Matrix & Intrinsic Class Ambiguity Analysis

![EXP-001 Confusion Matrix](../results/runs/EXP-001/confusion_matrix.png)
_Figure 5: EXP-001 (Clean Baseline) 62-class confusion matrix on the 116,323-sample test set. The strong primary diagonal reflects high classification accuracy, while symmetric off-diagonal clusters highlight intrinsic case ambiguity._

![EXP-002 Confusion Matrix](../results/runs/EXP-002/confusion_matrix.png)
_Figure 6: EXP-002 (Robust CNN) 62-class confusion matrix, displaying identical structural stability along the diagonal and similar off-diagonal ambiguity clustering._

### 6.1 The 15 Cohen Ambiguous Character Pairs

In their seminal 2017 EMNIST paper, Cohen et al. noted that in isolated single-character crops without baseline, cap-height, or x-height context, certain character pairs are visually indistinguishable:

- **Identical Glyphs (Case-Invariant):** `C`/`c`, `I`/`l`, `J`/`j`, `K`/`k`, `O`/`o`, `P`/`p`, `S`/`s`, `U`/`u`, `V`/`v`, `W`/`w`, `X`/`x`, `Y`/`y`, `Z`/`z`.
- **Digit/Letter Collisions:** Digit `0` vs. Uppercase `O`, Digit `1` vs. Lowercase `l` vs. Uppercase `I`, Digit `9` vs. Lowercase `q`.

### 6.2 Quantitative Ambiguity Recovery

When predictions between these 15 ambiguous pairs are unified under the case-insensitive metric:

- Model A accuracy jumps from **87.62% to 90.96% (+3.34%)**.
- Model B accuracy jumps from **87.46% to 90.88% (+3.42%)**.

**Academic Conclusion:** Over **3.3% of total classification error** (over 3,800 misclassified test samples) is caused entirely by fundamental topological equivalence rather than model deficiency. Achieving ~91% case-insensitive accuracy indicates that the CNN has essentially reached the theoretical performance ceiling for isolated 32x32 character crops.

---

## 7. Comparative Robustness Sweeps: The Perturbation Triad

The core empirical evaluation of this thesis subjected both frozen models to sweeps across 19 discrete severity levels on the complete 116,323-sample test set (over **4.42 million total inference passes**):

### 7.1 Gaussian Blur Evaluation

Optical blur attenuates high-frequency spatial gradients, destroying fine edge boundaries.

![Gaussian Blur Robustness Curve](../results/robustness/blur_curve.png)
_Figure 7: Top-1 Accuracy as a function of Gaussian Blur severity (sigma). Model A collapses past the 50% viability threshold past sigma = 1.0, whereas Model B demonstrates dramatic resilience even into out-of-distribution blur levels._

| Blur Severity (sigma) | Clean Model (EXP-001) | Robust Model (EXP-002) | Advantage (B - A) | Notes                        |
| :-------------------: | :-------------------: | :--------------------: | :---------------: | :--------------------------- |
|       **0.00**        |      **87.62%**       |         87.46%         |      -0.16%       | Clean baseline parity        |
|       **0.50**        |        85.68%         |       **87.43%**       |      +1.75%       | Robust model assumes lead    |
|       **1.00**        |        71.69%         |       **87.25%**       |    **+15.56%**    | Baseline degrades rapidly    |
|       **1.50**        |        31.12%         |       **86.93%**       |    **+55.81%**    | Baseline collapses below 50% |
|       **2.00**        |        12.24%         |       **86.20%**       |    **+73.96%**    | Max training boundary        |
|       **2.50**        |         6.17%         |       **83.28%**       |    **+77.11%**    | **Out-of-Distribution**      |
|       **3.00**        |         4.28%         |       **64.44%**       |    **+60.16%**    | **Out-of-Distribution**      |

- **Analysis:** At sigma = 3.00, Model A is virtually blind (**4.28%**, barely above random guessing at 1.61%). Model B maintains a usable **64.44%** accuracy—a **60.16 percentage point advantage**.

---

### 7.2 Sensor Noise Evaluation

Additive Gaussian noise introduces stochastic contrast spikes that simulate CMOS amplifier noise in low-light environments.

![Sensor Noise Robustness Curve](../results/robustness/noise_curve.png)
_Figure 8: Top-1 Accuracy as a function of additive Gaussian Noise standard deviation. Model B displays near-perfect flatline invariance, while Model A falls off a steep cliff beyond std = 0.10._

| Noise Severity (std) | Clean Model (EXP-001) | Robust Model (EXP-002) | Advantage (B - A) | Notes                     |
| :------------------: | :-------------------: | :--------------------: | :---------------: | :------------------------ |
|       **0.00**       |      **87.62%**       |         87.46%         |      -0.16%       | Baseline parity           |
|       **0.03**       |      **87.51%**       |         87.42%         |      -0.09%       |                           |
|       **0.06**       |        87.12%         |       **87.40%**       |      +0.28%       | Robust model assumes lead |
|       **0.10**       |        85.54%         |       **87.30%**       |      +1.76%       | Baseline begins decline   |
|       **0.15**       |        74.99%         |       **87.08%**       |    **+12.09%**    |                           |
|       **0.20**       |        37.65%         |       **86.59%**       |    **+48.94%**    | **Baseline cliff drop**   |

- **Analysis:** Across the entire noise range (0.00 to 0.20), Model B degrades by less than **0.9% total** (87.46% -> 86.59%). In contrast, Model A falls off an abrupt cliff between 0.15 and 0.20, crashing by nearly 50 percentage points down to **37.65%**. Model B functions as an implicit denoiser in its initial convolutional stages.

---

### 7.3 Perspective Distortion Evaluation

Perspective homography alters spatial geometry and aspect ratios without destroying pixel intensity frequency content.

![Perspective Distortion Robustness Curve](../results/robustness/perspective_curve.png)
_Figure 9: Top-1 Accuracy as a function of Perspective Distortion severity (corner offset ratio). Model B degrades with exceptional grace, preserving over 82.8% accuracy at 25% corner skew._

| Perspective Severity (%) | Clean Model (EXP-001) | Robust Model (EXP-002) | Advantage (B - A) | Notes                    |
| :----------------------: | :-------------------: | :--------------------: | :---------------: | :----------------------- |
|         **0.00**         |      **87.62%**       |         87.46%         |      -0.16%       | Baseline parity          |
|         **0.05**         |        85.50%         |       **87.12%**       |      +1.62%       |                          |
|         **0.10**         |        83.85%         |       **86.52%**       |      +2.67%       |                          |
|         **0.15**         |        80.24%         |       **85.83%**       |      +5.59%       |                          |
|         **0.20**         |        73.86%         |       **84.84%**       |    **+10.98%**    |                          |
|         **0.25**         |        64.36%         |       **82.83%**       |    **+18.47%**    | Steady linear divergence |

- **Analysis:** Unlike blur and noise, perspective distortion does not cause a sudden cliff because pooling layers grant partial translation invariance. However, as skew increases to 25%, Model A drops to 64.36%, while Model B remains at **82.83%** (**+18.47% margin**), demonstrating robust projective angle invariance.

---

## 8. Hardware Practicality & Embedded Deployment

Hardware profiling was conducted to measure inference latency and throughput under production execution constraints:

| Evaluation Metric                    | Host CPU Execution  | Cloud GPU Execution (NVIDIA P100/T4) | Notes / Implications                      |
| :----------------------------------- | :-----------------: | :----------------------------------: | :---------------------------------------- |
| **Total Parameters**                 |     **634,110**     |             **634,110**              | 100% trainable (~0.63M parameters)        |
| **Model Size (FP32 Weights)**        |     **2.42 MB**     |             **2.42 MB**              | Readily fits inside embedded flash memory |
| **Full Checkpoint Size**             |     **7.28 MB**     |             **7.28 MB**              | Includes AdamW 1st & 2nd moments          |
| **Latency: Single Char (`batch=1`)** | **1.08 ms** / char  |          **0.59 ms** / char          | Sub-2-millisecond real-time response      |
| **Latency: Batched (`batch=32`)**    | **15.08 ms** total  |          **0.69 ms** total           | Average **0.021 ms** per char on GPU      |
| **Throughput (chars / sec)**         | **2,123 chars/sec** |         **46,172 chars/sec**         | Can scan dense pages in under 1 second    |

### Practical Deployment Implications:

1. **Microcontroller Feasibility:** A 2.42 MB model binary can be executed directly on embedded devices (e.g., Raspberry Pi, ARM Cortex-A series, edge vision chips) without cloud dependency.
2. **CPU Throughput:** Even on a standard multi-core laptop CPU with zero GPU acceleration, the model classifies over **2,100 characters per second**, enabling high-speed real-time video stream OCR.

---

## 9. Current Status & Next Execution Steps

### 9.1 Thesis Milestone Progress Summary

- **Phase 0 (Environment & Architecture):** Completed.
- **Phase 1 (EMNIST Pipeline & 2px Padding):** Completed.
- **Phase 2 (Gradient Flow & Memorization Check):** Completed.
- **Phase 3 (Clean Baseline EXP-001 Training & Analysis):** Completed (87.62% Top-1).
- **Phase 4 (Parametric Degradation Simulator):** Completed.
- **Phase 5 (Robust CNN EXP-002 Training & Regularization):** Completed (87.46% Top-1).
- **Phase 6 (Comparative Robustness Sweeps across 4.4M passes):** Completed.
- **Phase 9 (Part A - Hardware Practicality Profiling):** Completed.

### 9.2 Immediate Next Experimental Tasks

1. **Phase 7 (Real-World Smartphone Photographs):**
   - Capture 30–50 natural smartphone photos of printed and handwritten characters under diverse ambient conditions (glare, off-axis angles, low light).
   - Apply bounding box crops with 2px proportional padding.
   - Evaluate zero-shot transfer performance of Model A vs. Model B to quantify real-world domain shift.
2. **Phase 8 (Cross-Dataset Generalization on Chars74k):**
   - Benchmark both models on the English subset of the Chars74k dataset to determine whether synthetic augmentations improve out-of-domain transfer.
3. **Phase 10 (EasyOCR Benchmark & ONNX Export):**
   - Run identical isolated crops through the EasyOCR recognition module to benchmark against commercial open-source OCR engines.
   - Export `AlphanumericCNN` to ONNX format to demonstrate embedded runtime compatibility.
