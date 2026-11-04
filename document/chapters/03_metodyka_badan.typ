#import "../metadata.typ": *

= Metodyka badań

== Zbiór danych
// [Section Guide]: Characterize the EMNIST ByClass benchmark (814,255 grayscale glyphs across 62 classes: 10 digits, 26 uppercase, 26 lowercase) and its derivation from NIST Special Database 19. Highlight the natural class imbalance and introduce the intrinsic morphological ambiguity of 15 homoglyph/case pairs (e.g., C/c, O/o, S/s, 0/O, 1/l/I) in isolated character crops lacking baseline context.
// Recommended citations: @cohen2017emnist, @grother2016nist

== Przygotowanie danych
// [Section Guide]: Document the deterministic preprocessing pipeline: correcting the transposed column-major storage orientation of raw EMNIST matrices, framing 28x28 glyphs into 32x32 tensors via 2-pixel black zero-padding (explaining why bilinear interpolation resizing was rejected to avoid anti-aliasing blur on thin strokes), and standardizing pixel intensities with empirical training-split statistics (mean = 0.1331, std = 0.2870).
// Recommended citations: @cohen2017emnist, @lecun1998lenet

== Architektura modelu
// [Section Guide]: Present the complete specification of the custom AlphanumericCNN architecture (three 3x3 Conv2d + BatchNorm2d + ReLU + 2x2 MaxPool2d blocks scaling channels 1->32->64->128, followed by a 2048->256->62 classifier head with BatchNorm1d and Dropout p=0.5). Provide the exact parameter breakdown (634,110 trainable parameters; 2.42 MB in FP32) and justify why a compact feedforward backbone was chosen over heavy ResNet or sequential CRNN architectures.
// Recommended citations: @lecun1998lenet, @ioffe2015batchnorm, @srivastava2014dropout, @he2015delving

== Scenariusze degradacji obrazów
// [Section Guide]: Introduce the parametric degradation simulator designed to emulate three physical acquisition imperfections encountered in real-world optical scanning. Define the discrete severity grids used for evaluation sweeps (19 total evaluation points across blur, noise, and perspective) and refer to the visual verification grid.
// Recommended citations: @hendrycks2019benchmarking, @dodge2016understanding, @gonzalez2018digital

=== Rozmycie gaussowskie
// [Section Guide]: Formulate optical defocus and motion blur as convolution with a 2D isotropic Gaussian kernel parameterized by standard deviation sigma in [0.0, 3.0], with dynamic window sizing k = 2 * ceil(3 * sigma) + 1 to prevent kernel truncation. Explain how increasing sigma attenuates high-frequency stroke boundaries and closes small topological loops.
// Recommended citations: @gonzalez2018digital, @vasiljevic2016examining

=== Szum addytywny matrycy
// [Section Guide]: Formulate electronic CMOS sensor grain under low illumination / high ISO gain as zero-mean additive white Gaussian noise N(0, s^2) for s in [0.00, 0.20], followed by intensity clamping to the [0, 1] dynamic range. Discuss how stochastic pixel perturbations degrade local contrast and create false edge gradients.
// Recommended citations: @gonzalez2018digital, @dodge2016understanding

=== Zniekształcenia perspektywiczne
// [Section Guide]: Formulate off-axis camera tilt via a 3x3 planar projective homography matrix computed from random uniform perturbations of the four image corners within [-p * min(H,W), +p * min(H,W)] for severity p in [0.00, 0.25]. Describe the backward bilinear resampling with constant zero border padding.
// Recommended citations: @hartley2004multiple, @chen2021text

== Strategie uczenia modeli
// [Section Guide]: Establish the controlled experimental comparison between two models sharing the exact same AlphanumericCNN architecture, initialization seed, and optimization hyperparameters (AdamW, lr = 1e-3, weight_decay = 1e-4, batch_size = 512, 25 epochs), differing solely in their training data distribution.
// Recommended citations: @loshchilov2017adamw, @shorten2019survey

=== Model bazowy
// [Section Guide]: Specify the training regime of Model A (Clean Baseline, EXP-001), trained exclusively on pristine, zero-padded EMNIST training samples without synthetic corruptions. Explain its role as the control benchmark for measuring both upper-bound clean accuracy and natural vulnerability to distribution shifts.
// Recommended citations: @cohen2017emnist

=== Model uczony z uwzględnieniem degradacji
// [Section Guide]: Specify the stochastic on-the-fly augmentation regime of Model B (Robust CNN, EXP-002), where each training image independently undergoes perspective distortion (p <= 0.25), Gaussian blur (sigma <= 2.0), and Gaussian noise (s <= 0.15), each with 0.5 probability. Note intentionally that training blur is capped at sigma = 2.0 so that evaluation at sigma in {2.5, 3.0} tests true out-of-distribution (OOD) generalization.
// Recommended citations: @shorten2019survey, @hendrycks2019benchmarking, @vasiljevic2016examining

== Metody oceny modeli
// [Section Guide]: Define all quantitative evaluation metrics: Top-1 Accuracy, Macro-Precision, Macro-Recall, and Macro-F1 (explaining why macro-averaging is essential under EMNIST ByClass imbalance), the 50% accuracy collapse threshold, and Case-Insensitive Accuracy unifying the 15 ambiguous upper/lowercase character pairs to isolate intrinsic homoglyph error.
// Recommended citations: @cohen2017emnist, @grother2016nist, @hendrycks2019benchmarking

== Protokół eksperymentalny i reprodukowalność badań
// [Section Guide]: Consolidate the experimental execution protocol and reproducibility safeguards: strict isolation of the frozen 116,323-sample test set, persistent 90/10 train/validation split manifests (628,139 train / 69,794 val samples), checkpointing strictly at minimum validation loss, deterministic seeding across Python/NumPy/PyTorch/CUDA, and the hardware latency profiling procedure (warm-up passes + 1,000 timed iterations at batch=1 and batch=32).
// Recommended citations: @paszke2019pytorch, @cohen2017emnist
