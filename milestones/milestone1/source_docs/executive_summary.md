# Executive Briefing: Robust Alphanumeric OCR under Environmental Degradations

**Project:** Robust 62-Class Alphanumeric Character Recognition Using Compact CNNs  
**Author:** Kamil Suhak | Engineering Thesis Progress Briefing | September 2026  

---

### 1. Research Premise & Core Question
* **Problem:** Real-world OCR on mobile and edge devices frequently suffers from optical defocus (blur), sensor grain (noise), and off-axis camera angles (perspective skew). Traditional multi-stage OCR pipelines (e.g., CRAFT + CRNN) are too resource-heavy for low-power microcontrollers.
* **Core Question:** Can a compact convolutional neural network (~630k parameters) trained with stochastic, synthetic degradations achieve near-human accuracy on clean data while remaining fundamentally immune to severe environmental degradations?
* **Dataset:** Official EMNIST ByClass (62 classes: digits `0-9`, uppercase `A-Z`, lowercase `a-z`, 814,255 samples), framed with 2px black zero-padding to 32x32 to preserve native stroke geometry without interpolation artifacts.

---

### 2. Experimental Setup
* **Model A (Clean Baseline):** Trained exclusively on clean, zero-padded characters for 25 epochs (AdamW, batch 512).
* **Model B (Robust CNN):** Trained with on-the-fly random degradations: Gaussian blur (sigma <= 2.0), sensor noise (std <= 0.15), and perspective homography tilt (severity <= 25%).
* **Architecture (`AlphanumericCNN`):** 3 Conv-BatchNorm-ReLU-MaxPool blocks (32 -> 64 -> 128 channels) + Dense head (256 units, Dropout 0.5) -> 62 classes. **634,110 parameters**; **2.42 MB** FP32 footprint.

---

### 3. Empirical Results: Clean vs. Degraded Performance

#### A. Baseline Parity on Pristine Test Set (116,323 Samples)
* **Top-1 Accuracy:** Model A = **87.62%** vs. Model B = **87.46%** (negligible delta of **-0.16%**).
* **Case-Insensitive Accuracy:** Model A = **90.96%** vs. Model B = **90.88%**.
* **Ambiguity Ceiling:** ~3.3% of classification error is caused by the 15 visually identical Cohen character pairs (`C/c`, `O/o/0`, `I/l/1`, `S/s`) that are indistinguishable without surrounding font context.

#### B. Robustness Sweeps across 4.42 Million Inferences (The Degradation Triad)

| Perturbation Type | Clean Model (A) | Robust Model (B) | Margin (B - A) | Key Takeaway |
| :--- | :---: | :---: | :---: | :--- |
| **Pristine Data (Clean)** | **87.62%** | 87.46% | -0.16% | Zero cost to clean accuracy. |
| **Moderate Blur (sigma = 1.0)** | 71.69% | **87.25%** | **+15.56%** | Baseline degrades rapidly. |
| **Severe Blur (sigma = 2.0)** | 12.24% | **86.20%** | **+73.96%** | Baseline suffers catastrophic edge loss. |
| **Extreme Blur (sigma = 3.0)\*** | 4.28% | **64.44%** | **+60.16%** | **Out-of-distribution generalisation!** |
| **Moderate Noise (std = 0.10)** | 85.54% | **87.30%** | **+1.76%** | Robust model remains flat. |
| **Severe Noise (std = 0.20)** | 37.65% | **86.59%** | **+48.94%** | Baseline crashes; Robust drops <0.9% total. |
| **Moderate Perspective (15%)** | 80.24% | **85.83%** | **+5.59%** | Consistent projective resilience. |
| **Severe Perspective (25%)** | 64.36% | **82.83%** | **+18.47%** | Handles extreme 8px off-axis tilts. |

*\*Note: Model B was only trained up to blur sigma = 2.0, demonstrating genuine topological invariance on out-of-distribution blur (sigma = 3.0).*

---

### 4. Hardware Practicality & Deployment Viability
* **Model Footprint:** **2.42 MB** (FP32 weights) — fits directly inside embedded microcontroller flash.
* **CPU Latency (Laptop/Standard Host):** **1.08 ms** per character (batch = 1); **2,123 characters/sec** (batch = 32).
* **GPU Latency (Edge/Server Accelerator):** **0.59 ms** per character (batch = 1); **46,172 characters/sec** (batch = 32).
* **Training Dynamics:** Augmentations acted as an optimal regularizer—Model A overfit past Epoch 11, whereas Model B improved monotonically through Epoch 25.

---

### 5. Current Progress & Immediate Roadmap
* **Completed Milestones:** Data pipeline, zero-padding standardization, baseline and robust training, ambiguity resolution, 4.4M-pass degradation sweeps, and hardware profiling.
* **Next Steps:**
  1. **Phase 7:** Zero-shot validation on smartphone photos of real-world physical characters.
  2. **Phase 8:** Cross-dataset transfer benchmarking on Chars74k.
  3. **Phase 10:** Performance and latency benchmark against commercial Open-Source EasyOCR + ONNX export.
