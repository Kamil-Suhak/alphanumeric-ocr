#import "../metadata.typ": *

= Implementacja systemu

== Środowisko programistyczne i wykorzystane narzędzia
System badawczy zrealizowano w~języku Python w~wersji 3.12, wykorzystując nowoczesny stos technologiczny dedykowany do obliczeń z~zakresu głębokiego uczenia i~przetwarzania obrazów:
- *PyTorch (v2.x):* Podstawowa biblioteka obliczeń tensorowych, automatycznego różniczkowania (_autograd_) oraz budowy grafu obliczeniowego sieci neuronowych.
- *Torchvision:* Moduły obsługi potoków danych wizualnych oraz podstawowych przekształceń geometrycznych.
- *OpenCV oraz Pillow:* Biblioteki niskopoziomowego przetwarzania macierzy obrazów, wykorzystywane w~generatorze przekształceń rzutowych i~filtracji splotowej.
- *NumPy oraz SciPy:* Narzędzia algebry liniowej i~operacji na macierzach wielowymiarowych.
- *Scikit-learn:* Obliczanie metryk jakościowych (precyzja, pełność, miara F1 uśredniane makro) oraz wyznaczanie macierzy pomyłek.
- *Narzędzie uv:* Nowoczesny menedżer pakietów i~wirtualnych środowisk w~ekosystemie języka Python, gwarantujący w~100% powtarzalne instalacje zależności dzięki plikowi blokady `uv.lock`.
- *System Git:* Kontrola wersji kodu źródłowego oraz konfiguracji eksperymentów.

== Implementacja modelu klasyfikacyjnego
Model zaimplementowano jako klasę `AlphanumericCNN` dziedziczącą po klasie bazowej `torch.nn.Module`. Kod źródłowy zlokalizowano w~module `experiments/src/models/cnn.py`.

Architekturę podzielono na dwa sekwencyjne komponenty:
1. *Ekstraktor cech (`self.features`):* Składa się z~trzech kaskadowo połączonych bloków splotowych. Każdy blok zawiera warstwę splotową `nn.Conv2d` o~rozmiarze jądra $3 times 3$ i~dopełnieniu 1 piksela, warstwę normalizacji wsadowej `nn.BatchNorm2d`, funkcję aktywacji `nn.ReLU(inplace=True)` oraz podpróbkowanie `nn.MaxPool2d(kernel_size=2, stride=2)`. W~wyniku tego rozmiar przestrzenny tensora wejściowego redukowany jest sekwencyjnie z~$32 times 32$, przez $16 times 16$ i~$8 times 8$, do $4 times 4$, przy jednoczesnej progresji liczby kanałów ($1 -> 32 -> 64 -> 128$).
2. *Głowica klasyfikacyjna (`self.classifier`):* Tensor wyjściowy ekstraktora o~wymiarach $128 times 4 times 4$ jest spłaszczany warstwą `nn.Flatten()` do wektora o~długości 2048 cech, po czym trafia do warstwy gęstej `nn.Linear(2048, 256)`. Po niej aplikowana jest jednowymiarowa normalizacja `nn.BatchNorm1d(256)`, aktywacja ReLU oraz regularyzacja `nn.Dropout(p=0.5)`. Końcowa warstwa liniowa `nn.Linear(256, 62)` generuje surowe logity dla 62 klas znaków.

Dzięki zwartej definicji model charakteryzuje się deterministycznym przepływem danych bez rozgałęzień, co sprzyja optymalizacjom kompilatora TorchScript i~konwersji do formatu ONNX.

== Implementacja generowania degradacji
Moduł symulacji degradacji środowiskowych zrealizowano w~pliku `experiments/src/data/transforms.py`. Opracowano trzy dedykowane funkcje transformujące oraz klasę potoku `DegradationPipeline`:
- `apply_gaussian_blur(image, sigma)`: Wyznacza rozmiar jądra filtru według reguły $k = 2 ceil(3 sigma) + 1$, gwarantującej objęcie 99,7% masy rozkładu Gaussa, po czym dokonuje splotu za pomocą funkcji `cv2.GaussianBlur`.
- `apply_gaussian_noise(image, std, rng)`: Generuje addytywny szum za pomocą generatora liczb pseudolosowych `np.random.Generator`, dodaje go do tablicy pikseli i~przycina wartości do dozwolonego przedziału $[0.0, 1.0]$.
- `apply_perspective_distortion(image, severity, rng)`: Losuje wektory przesunięć dla czterech wierzchołków obrazu o~maksymalnej amplitudzie zależnej od parametru `severity`. Następnie wyznacza macierz homografii $3 times 3$ metodą `cv2.getPerspectiveTransform` i~dokonuje interpolacji dwuliniowej przez `cv2.warpPerspective`.

Klasa `DegradationPipeline` integruje powyższe przekształcenia, losując niezależnie aplikację każdego z~nich dla każdej próbki w~trakcie ładowania danych w~obiekcie `DataLoader`.

== Implementacja procesu uczenia
Procedurę uczenia zaimplementowano w~module `experiments/src/training/train.py`. Główne elementy potoku treningowego obejmują:
- Obsługę konfiguracji wczytywanych z~plików YAML za pośrednictwem modułu `experiments/src/config.py`.
- Inicjalizację generatorów liczb pseudolosowych za pomocą `experiments/src/seed.py`.
- Pętlę trenującą z~funkcją straty wieloklasowej entropii krzyżowej `nn.CrossEntropyLoss()` oraz optymalizatorem `torch.optim.AdamW`.
- Walidację po każdej epoce na wydzielonym podzbiorze walidacyjnym (69~794 próbki), rejestrującą stratę walidacyjną oraz dokładność Top-1.
- Zapisywanie najlepszego punktu kontrolnego (`best.pt`) przy użyciu mechanizmu w~`experiments/src/utils/checkpoint.py`, przechowującego wagi modelu, stan optymalizatora oraz osiągnięte metryki.
- Ciągłe logowanie przebiegu uczenia do pliku `metrics.csv`, umożliwiające generowanie wykresów zbieżności.

== Implementacja procesu ewaluacji
Moduł ewaluacyjny (`experiments/src/training/evaluate.py`) realizuje deterministyczny test modelu na nienaruszonym zbiorze testowym:
- Przełącza model w~tryb wnioskowania (`model.eval()`) oraz blokuje wyliczanie gradientów (`torch.no_grad()`).
- Zlicza predykcje i~buduje pełną macierz pomyłek o~wymiarach $62 times 62$.
- Oblicza metryki uśrednione makro za pośrednictwem funkcji z~`experiments/src/utils/metrics.py`.
- Wylicza dokładność niewrażliwą na wielkość liter (_case-insensitive accuracy_), mapując indeksy 15 par znaków homomorficznych do wspólnego identyfikatora cechy.
- Zapisuje zagregowane wyniki ewaluacji do plików w~formacie JSON (`test_results.json`).

== Organizacja eksperymentów
Architektura repozytorium badawczego została zorganizowana w~sposób modułowy:
- `configs/`: Zawiera deklaratywne pliki konfiguracyjne YAML definiujące hiperparametry modelu bazowego (`baseline.yaml`) oraz odpornego (`robust.yaml`).
- `manifests/`: Przechowuje deterministyczne listy identyfikatorów próbek podziału treningowego i~walidacyjnego.
- `outputs/runs/`: Każde uruchomienie eksperymentalne otrzymuje unikalny katalog (np. `EXP-001_baseline/`, `EXP-002_robust/`), w~którym gromadzone są wagi `best.pt`, metryki `metrics.csv`, wykresy uczenia `training_curve.png` oraz macierze pomyłek `confusion_matrix.png`.
- `outputs/sweeps/`: Gromadzi wyniki testów odpornościowych w~funkcji intensywności poszczególnych zaburzeń, realizowanych przez skrypt `degradation_sweep.py`.
- `outputs/tables/`: Przechowuje zintegrowane tabele JSON i~CSV, z~których dane wstrzykiwane są dynamicznie do niniejszej pracy.
