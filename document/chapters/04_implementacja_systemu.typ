#import "../metadata.typ": *

= Implementacja systemu

== Środowisko programistyczne i wykorzystane narzędzia
// [Section Guide]: Document the software stack (Python, PyTorch, Torchvision, OpenCV, NumPy, Pillow, Matplotlib, uv package manager) and the dual execution environment (local workstation for development/profiling and NVIDIA T4/P100 GPU cloud instances for full-scale training and 4.42M-sample sweep evaluations). Describe the modular package architecture under `experiments/src/` and `experiments/scripts/`.
// Recommended citations: @paszke2019pytorch

== Potok przetwarzania danych i generator degradacji
// [Section Guide]: Detail the implementation of `src/data/emnist.py` (selective binary IDX archive download, `fix_emnist_orientation`, `T.Pad(padding=2, fill=0)`, `TransformedDataset`, and CSV manifest loading) alongside `src/data/transforms.py` (`apply_gaussian_blur`, `apply_gaussian_noise`, `apply_perspective_distortion`, and the stateful `DegradationPipeline` class with isolated NumPy `default_rng` generators).
// Recommended citations: @paszke2019pytorch, @cohen2017emnist, @gonzalez2018digital

== Implementacja modelu klasyfikacyjnego
// [Section Guide]: Describe the programmatic realization of `AlphanumericCNN` in `src/models/cnn.py` as a `torch.nn.Module` subclass separating `self.features` and `self.classifier`, including `inplace=True` ReLU memory optimizations and the `count_parameters()` utility. Mention the preliminary sanity check (`scripts/overfit_tiny_subset.py` reaching >98% accuracy on 256 samples) used to verify gradient flow before full training.
// Recommended citations: @paszke2019pytorch, @ioffe2015batchnorm, @srivastava2014dropout

== Implementacja procesu uczenia
// [Section Guide]: Explain the training loop architecture in `src/training/train.py` (`train_epoch`, `validate_epoch`, and `fit`), highlighting `optimizer.zero_grad(set_to_none=True)`, `torch.no_grad()` validation context, real-time epoch telemetry to `metrics.csv`, and state-dict serialization (`best.pt`) triggered exclusively when validation loss improves.
// Recommended citations: @paszke2019pytorch, @loshchilov2017adamw

== Implementacja procesu ewaluacji i profilowania
// [Section Guide]: Document the evaluation engine (`src/training/evaluate.py`, `src/utils/metrics.py`, and `src/experiments/degradation_sweep.py` with `ControlledDegradationDataset`) that automates the 19-point degradation sweeps and computes macro metrics and case-insensitive accuracy. Also describe `scripts/benchmark_practicality.py`, explaining the CUDA synchronization (`torch.cuda.synchronize()`) and 30-iteration warm-up protocol for accurate latency measurement.
// Recommended citations: @paszke2019pytorch

== Organizacja eksperymentów i zarządzanie artefaktami
// [Section Guide]: Describe the declarative YAML configuration system (`configs/baseline.yaml`, `configs/robust.yaml`) and the structured artifact hierarchy under `experiments/outputs/` (`runs/`, `sweeps/`, `diagnostics/`, `tables/`). Explain how exporting aggregated JSON/CSV tables (`accuracy_summary.json`, `practicality.json`) enables direct dynamic data binding into the Typst thesis document without manual number copying.
// Recommended citations: @paszke2019pytorch
