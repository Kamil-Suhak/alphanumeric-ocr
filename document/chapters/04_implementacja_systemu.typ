#import "../metadata.typ": *

= Implementacja systemu

== Środowisko programistyczne i wykorzystane narzędzia
// [Wskazówki autorskie]: Udokumentować stos technologiczny (Python 3.14, PyTorch, Torchvision, OpenCV, NumPy, Pillow, Matplotlib, ONNX, ONNX Runtime, menedżer pakietów uv, framework testowy pytest) oraz podwójne środowisko obliczeniowe (stacja robocza do prac implementacyjnych, testów jednostkowych i profilowania CPU/ONNX oraz instancje chmurowe GPU do pełnego treningu i ewaluacji). Przedstawić strukturę modułową pakietu badawczego z podziałem na bibliotekę źródłową (experiments/src/), skrypty wykonawcze CLI (experiments/scripts/) oraz zestaw testów (experiments/tests/).
// Rekomendowana literatura: @paszke2019pytorch
#lorem(140)

#lorem(140)

== Potok przetwarzania danych i generator degradacji
// [Wskazówki autorskie]: Przedstawić implementację modułu wczytywania danych (src/data/emnist.py: selektywne pobieranie archiwów binarnych IDX, funkcja fix_emnist_orientation, transformacja T.Pad, klasa TransformedDataset oraz ładowanie manifestów podziału) w połączeniu z silnikiem degradacji (src/data/transforms.py: apply_gaussian_blur, apply_gaussian_noise, apply_perspective_distortion, apply_motion_blur, apply_compound_degradation oraz parametryczna klasa DegradationPipeline z niezależnymi generatorami default_rng i ponownym zasiewaniem w worker_init_fn).
// Rekomendowana literatura: @paszke2019pytorch, @cohen2017emnist, @gonzalez2018digital
#lorem(140)

#lorem(140)

#lorem(140)

== Implementacja modelu klasyfikacyjnego
// [Wskazówki autorskie]: Opisać realizację programową klasy AlphanumericCNN w src/models/cnn.py jako modułu torch.nn.Module z czytelnym podziałem na sekcje features i classifier, wykorzystaniem inplace=True w aktywacjach ReLU dla oszczędności pamięci oraz metodą count_parameters(). Wspomnieć o teście zapamiętywania małego podzbioru (overfit_tiny_subset.py: >98% dokładności na 256 próbkach w 40 epokach), który posłużył do walidacji przepływu gradientów przed pełnym treningiem.
// Rekomendowana literatura: @paszke2019pytorch, @ioffe2015batchnorm, @srivastava2014dropout
#lorem(130)

#lorem(130)

#lorem(120)

== Implementacja procesu uczenia
// [Wskazówki autorskie]: Wyjaśnić strukturę pętli treningowej w src/training/train.py (train_epoch, validate_epoch, fit) oraz sparametryzowanego modułu uruchomieniowego w src/training/runner.py wraz ze skryptami train.py, train_baseline.py i train_robust.py (obsługa flag --config i --seed, nadawanie nazw RUN_ID z sufiksem _seed<SEED>). Podkreślić zerowanie gradientów z opcją set_to_none=True, blok ewaluacji torch.no_grad(), telemetrię do metrics.csv oraz zapis checkpointu (best.pt) wyłącznie dla nowego minimum straty walidacyjnej.
// Rekomendowana literatura: @paszke2019pytorch, @loshchilov2017adamw
#lorem(130)

#lorem(130)

#lorem(120)

== Implementacja procesu ewaluacji, wyjaśnialności i optymalizacji brzegowej
// [Wskazówki autorskie]: Przedstawić architekturę modułów ewaluacji (src/training/evaluate.py, src/utils/metrics.py, src/experiments/degradation_sweep.py z deterministycznym ControlledDegradationDataset) oraz skrypty analityczne: summarize_sweeps.py (agregacja wieloziarnowa i ablacyjna), generate_gradcam.py (haki gradientowe na warstwie features[8] w AlphanumericCNN), benchmark_practicality.py (PyTorch FP32, torch.cuda.synchronize()), benchmark_edge_optimization.py (eksport ONNX FP32 i statyczna kwantyzacja QDQ INT8 w ONNX Runtime), evaluate_compounded_stress.py, evaluate_motion_blur_ood.py oraz export_error_diagnostics.py.
// Rekomendowana literatura: @paszke2019pytorch
#lorem(130)

#lorem(130)

#lorem(120)

== Organizacja eksperymentów i zarządzanie artefaktami
// [Wskazówki autorskie]: Opisać deklaratywny system konfiguracji oparty na plikach YAML (baseline.yaml, robust.yaml, ablation_blur.yaml, ablation_noise.yaml, ablation_perspective.yaml), testy jednostkowe i syntetyczne w experiments/tests/ (pytest) oraz ustrukturyzowane repozytorium wyników w experiments/outputs/ (runs/, sweeps/, diagnostics/, tables/). Wyjaśnić, w jaki sposób eksport zagregowanych tabel do formatów JSON i CSV umożliwia dynamiczne wiązanie danych w dokumencie pracy w Typst bez ręcznego przepisywania wartości liczbowych.
// Rekomendowana literatura: @paszke2019pytorch
#lorem(150)

#lorem(150)
