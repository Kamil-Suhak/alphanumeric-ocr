#import "../metadata.typ": *

= Podstawy teoretyczne i stan wiedzy

== Ewolucja metod klasyfikacji znaków i OCR
Klasyfikacja pojedynczych wycinków znaków stanowi historyczny fundament uczenia maszynowego w widzeniu komputerowym. Pionierska architektura LeNet-5 zaproponowana przez LeCuna i in. @lecun1998lenet ustanowiła paradygmat splotu, nieliniowej aktywacji i podpróbkowania (pooling), eliminując konieczność ręcznego inżynierowania cech.

Współczesne systemy OCR dzielą się zasadniczo na dwa etapy: detekcję tekstu (np. algorytmy DBNet, EAST) oraz rozpoznawanie wyizolowanych wycinków znaków lub sekwencji słów (CRNN, Transformer-based OCR). W scenariuszach przemysłowych o ścisłych reżimach opóźnień (np. skanowanie kodów alfanumerycznych z linii produkcyjnej z częstotliwością >50 Hz) preferowane są wysoce wyspecjalizowane, lekkie klasyfikatory CNN o zredukowanej liczbie parametrów.

== Zbiory danych w badaniach rozpoznawania pisma
Tradycyjny zbiór MNIST (10 klas cyfr, 70 000 próbek) przestał być wystarczającym benchmarkiem dla nowoczesnych modeli ze względu na relatywną prostotę i nasycenie dokładności powyżej 99.5%.

=== Zbiór EMNIST (Extended MNIST)
W niniejszej pracy jako fundament eksperymentalny wykorzystano wariant *ByClass* ze zbioru EMNIST opracowanego przez Cohena i in. @cohen2017emnist. Zbiór ten stanowi bezpośrednie rozszerzenie bazy NIST Special Database 19:
- Zawiera łącznie 814 255 próbek znaków odręcznych.
- Obejmuje 62 zbalansowane kategorie: cyfry `0-9` (10 klas), wielkie litery `A-Z` (26 klas) oraz małe litery `a-z` (26 klas).
- Każda próbka ma postać jednokanaleowego obrazu w skali szarości o rozmiarze bazowym $28 times 28$ pikseli.

=== Zbiór Chars74K i dane rzeczywiste
W celu późniejszej ewaluacji transferu wiedzy i generalizacji między domenami rozważa się zbiór Chars74K @campos2009chars74k, zawierający znaki pochodzące z rzeczywistych fotografii szyldów i tablic informacyjnych w środowisku naturalnym.

== Matematyczne modele degradacji środowiskowych
W pracy zamodelowano trzy komplementarne mechanizmy pogorszenia jakości obrazu:

=== Rozmycie gaussowskie (Gaussian Blur)
Odpowiada utracie ostrości optycznej i rozmyciu ruchowemu. Formalnie jest to splot obrazu $I(x, y)$ z dwuwymiarowym jądrem Gaussa $G_sigma$:
$ G_sigma (x, y) = frac(1, 2 pi sigma^2) exp(- frac(x^2 + y^2, 2 sigma^2)) $
$ I_text("blur")(x, y) = (I * G_sigma)(x, y) $
Parametr $sigma in [0.0, 3.0]$ kontroluje stopień zatarcia krawędzi i utraty cech wysokoczęstotliwościowych.

=== Szum addytywny matrycy (Gaussian Noise)
Symuluje zakłócenia termiczne i kwantyzacyjne sensora w warunkach niedoświetlenia:
$ I_text("noise")(x, y) = text("clip")(I(x, y) + epsilon, 0, 1), quad epsilon tilde.op cal(N)(0, s^2) $
gdzie $s in [0.0, 0.20]$ reprezentuje odchylenie standardowe szumu w znormalizowanej przestrzeni pikseli $[0, 1]$.

=== Zniekształcenia perspektywiczne (Perspective Distortion)
Modelują rejestrację obrazu pod kątem innym niż prostopadły do płaszczyzny znaku za pomocą transformacji rzutowej (homografii):
$ mat(x'; y'; 1) tilde bold(H) mat(x; y; 1), quad bold(H) in RR^(3 times 3) $
Narożniki ramki obrazu są losowo przemieszczane o wektor o maksymalnej normie proporcjonalnej do współczynnika deformacji $p in [0.0, 0.25]$.

== Odporność sieci splotowych a augmentacja danych
Prace Hendrycksa i Diettericha @hendrycks2019benchmarking wykazały, że sieci neuronowe wykazują znikomą odporność na dystrybucje spoza zbioru uczącego (ang. _out-of-distribution_, OOD), chyba że w trakcie treningu wymusi się odpowiednią niezmienniczość reprezentacji poprzez celową augmentację danych @shorten2019survey.

#block(fill: rgb("#f5f5f7"), inset: 1em, radius: 4pt)[
  #text(weight: "bold")[Wytyczne redakcyjne do rozwinięcia rozdziału:]
  - [ ] Rozbudować analizę literatury o porównanie z transformerami wizyjnymi (ViT) w kontekście małych wycinków.
  - [ ] Omówić wpływ normalizacji wsadowej (BatchNorm) i funkcji aktywacji na gładkość powierzchni decyzyjnej.
  - [ ] Zestawić dotychczasowe benchmarki dokładności na EMNIST ByClass z publikacji 2020--2025.
]
