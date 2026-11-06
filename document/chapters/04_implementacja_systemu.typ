#import "../metadata.typ": *

= Implementacja systemu

== Środowisko programistyczne i wykorzystane narzędzia
// [Wskazówki autorskie]: Udokumentować stos technologiczny (Python, PyTorch, Torchvision, OpenCV, NumPy, Pillow, Matplotlib, menedżer pakietów uv) oraz podwójne środowisko obliczeniowe (stacja robocza do prac implementacyjnych i profilowania CPU oraz instancje chmurowe z akceleratorami NVIDIA T4/P100 do pełnego treningu i ewaluacji 4,42 mln prób). Przedstawić strukturę modułową pakietu badawczego z podziałem na bibliotekę źródłową (experiments/src/) oraz skrypty wykonawcze CLI (experiments/scripts/).
// Rekomendowana literatura: @paszke2019pytorch
#lorem(140)

#lorem(140)

== Potok przetwarzania danych i generator degradacji
// [Wskazówki autorskie]: Przedstawić implementację modułu wczytywania danych (src/data/emnist.py: selektywne pobieranie archiwów binarnych IDX, funkcja fix_emnist_orientation, transformacja T.Pad, klasa TransformedDataset oraz ładowanie manifestów podziału) w połączeniu z silnikiem degradacji (src/data/transforms.py: apply_gaussian_blur, apply_gaussian_noise, apply_perspective_distortion oraz klasa DegradationPipeline z niezależnymi generatorami default_rng).
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
// [Wskazówki autorskie]: Wyjaśnić strukturę pętli treningowej w src/training/train.py (funkcje train_epoch, validate_epoch oraz funkcja nadrzędna fit), podkreślając zerowanie gradientów z opcją set_to_none=True, blok ewaluacji torch.no_grad(), telemetrię metryk do pliku metrics.csv w czasie rzeczywistym oraz serializację stanu wag (best.pt) wyłącznie w momencie osiągnięcia nowego minimum straty walidacyjnej.
// Rekomendowana literatura: @paszke2019pytorch, @loshchilov2017adamw
#lorem(130)

#lorem(130)

#lorem(120)

== Implementacja procesu ewaluacji i profilowania
// [Wskazówki autorskie]: Przedstawić architekturę modułu ewaluacji (src/training/evaluate.py, src/utils/metrics.py oraz moduł testów odpornościowych src/experiments/degradation_sweep.py z klasą ControlledDegradationDataset), który automatyzuje analizę wrażliwości na 19 poziomach zaburzeń i wyznacza metryki makro oraz wariant case-insensitive. Opisać skrypt benchmark_practicality.py, wyjaśniając konieczność synchronizacji akceleratora (torch.cuda.synchronize()) i fazy rozgrzewki (30 iteracji) dla wiarygodnego pomiaru czasu inferencji.
// Rekomendowana literatura: @paszke2019pytorch
#lorem(130)

#lorem(130)

#lorem(120)

== Organizacja eksperymentów i zarządzanie artefaktami
// [Wskazówki autorskie]: Opisać deklaratywny system konfiguracji oparty na plikach YAML (configs/baseline.yaml, configs/robust.yaml) oraz ustrukturyzowane repozytorium wyników w katalogu experiments/outputs/ (podkatalogi runs/, sweeps/, diagnostics/, tables/). Wyjaśnić, w jaki sposób eksport zagregowanych tabel do formatów JSON i CSV (accuracy_summary.json, practicality.json) umożliwia bezpośrednie, dynamiczne wiązanie danych w dokumencie pracy w Typst bez ręcznego przepisywania wartości liczbowych.
// Rekomendowana literatura: @paszke2019pytorch
#lorem(150)

#lorem(150)
