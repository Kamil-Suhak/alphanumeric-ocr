#import "../metadata.typ": *

= Metodyka badań

== Zbiór danych
Jako podstawę empiryczną badań wybrano zbiór EMNIST w~wariancie *ByClass* @cohen2017emnist, stanowiący rozszerzenie i~poprawioną wersję bazy NIST Special Database 19. Jest to jeden z~najbardziej wymagających korpusów do badań nad klasyfikacją pisma odręcznego:
- Obejmuje łącznie *814~255* próbek znaków.
- Definiuje *62* kategorie decyzyjne: cyfry `0--9` (10 klas), wielkie litery alfabetu łacińskiego `A--Z` (26 klas) oraz małe litery `a--z` (26 klas).
- Każda próbka ma pierwotnie postać jednokanałowego obrazu w~skali szarości o~rozdzielczości $28 times 28$ pikseli.

W~celu późniejszej weryfikacji zdolności generalizacji modeli poza domenę pisma odręcznego EMNIST, w~pracy uwzględniono także rzeczywiste wycinki znaków ze zbioru Chars74K @campos2009chars74k oraz autorską kolekcję fotografii cyfrowych wykonanych w~warunkach polowych.

== Przygotowanie danych
Surowe dane z~bazy NIST zapisane są ze specyficzną orientacją osiową (transpozycja współrzędnych pionowych i~poziomych). Pierwszym krokiem preprocessingu jest zatem programowa transpozycja tensora do prawidłowej orientacji czytelnej dla człowieka.

W~celu dostosowania rozdzielczości do wielokrotności potęg dwójki (standard $32 times 32$ piksele) zrezygnowano ze standardowego skalowania biliniowego (`Resize((32, 32))`). Zamiast tego zastosowano symetryczne *dopełnienie zerami* (ang. _Zero-Padding_) o~szerokości 2 pikseli z~każdej strony (`Pad(padding=2, fill=0)`):
- Zabieg ten zapobiega powstawaniu artefaktów rozmycia interpolacyjnego i~zachowuje nienaruszone, ostre krawędzie kresek pisma.
- Odtwarza naturalną ramkę marginesu tła, analogicznie do klasycznej procedury w~architekturze LeNet-5.

Wartości średniej $mu$ i~odchylenia standardowego $sigma$ do normalizacji wyznaczono empirycznie na podzbiorze uczącym:
$ mu = 0.1331, quad sigma = 0.2870 $
Wyznaczone parametry odbiegają od standardowych stałych MNIST ($mu=0.1307, sigma=0.3081$), co wynika ze specyfiki rozkładu intensywności wariantu ByClass.

W~celu całkowitego wykluczenia wycieku danych (ang. _data leakage_), zbiór podzielono w~sposób deterministyczny i~utrwalono na dysku w~formacie manifestów CSV:
- *Zbiór testowy:* Oficjalny podzbiór testowy EMNIST (116~323 próbki) pozostawiono w~stanie nienaruszonym; służy on wyłącznie do finalnej ewaluacji modeli.
- *Zbiór treningowy:* 628~139 próbek (90% puli uczącej), zapisanych w~`train_indices.csv`.
- *Zbiór walidacyjny:* 69~794 próbki (10% puli uczącej), zapisanych w~`val_indices.csv`.

== Architektura modelu
Zaprojektowano sieć *AlphanumericCNN* zoptymalizowaną pod kątem minimalnego narzutu pamięciowego i~wysokiej przepustowości na procesorach wbudowanych. Składa się ona z~trzech bloków splotowych oraz dwuwarstwowego klasyfikatora liniowego.

#figure(
  table(
    columns: (1.8fr, 3.2fr, 1.5fr),
    align: (left, left, center),
    table.header([*Blok / Warstwa*], [*Operacje składowe*], [*Wymiar wyjściowy*]),
    [Wejście], [Obraz w skali szarości ze stemplem zerowym], [$1 times 32 times 32$],
    [Blok splotowy 1], [Conv2D($1 -> 32$, $3 times 3$, pad 1) + BatchNorm + ReLU + MaxPool($2 times 2$)], [$32 times 16 times 16$],
    [Blok splotowy 2], [Conv2D($32 -> 64$, $3 times 3$, pad 1) + BatchNorm + ReLU + MaxPool($2 times 2$)], [$64 times 8 times 8$],
    [Blok splotowy 3], [Conv2D($64 -> 128$, $3 times 3$, pad 1) + BatchNorm + ReLU + MaxPool($2 times 2$)], [$128 times 4 times 4$],
    [Spłaszczenie], [Spłaszczenie map cech (Flatten)], [$2048$],
    [Warstwa gęsta], [Linear($2048 -> 256$) + BatchNorm + ReLU + Dropout($p=0.5$)], [$256$],
    [Wyjście], [Linear($256 -> 62$) (Logity klas decyzyjnych)], [$62$],
  ),
  caption: [Struktura warstwowa architektury AlphanumericCNN.],
) <tab-architektura-modelu>

Model posiada *634~110* parametrów uczonych. Plik wag w~precyzji 32-bitowej zmiennoprzecinkowej (FP32) zajmuje zaledwie *2,42~MB*, co pozwala na jego bezpośrednie umieszczenie w~pamięci podręcznej L2/L3 nowoczesnych mikroprocesorów.

== Scenariusze degradacji obrazów
Zaimplementowano trzy parametryczne generatory zaburzeń symulujące trudne warunki środowiskowe.

=== Rozmycie
Symulowane za pomocą splotu z~filtrem Gaussa o~rozmiarze jądra dostosowanym dynamicznie do parametru dyspersji $sigma in [0.0, 3.0]$. Parametr $sigma$ steruje stopniem utraty wysokoczęstotliwościowych informacji o~krawędziach znaku.

=== Szum
Symulowany jako addytywny szum gaussowski o~zerowej wartości oczekiwanej i~odchyleniu standardowym $s in [0.0, 0.20]$. Po dodaniu szumu wartości jasności pikseli są przycinane do przedziału $[0, 1]$.

=== Zniekształcenia perspektywiczne
Symulowane za pomocą losowej deformacji perspektywicznej (homografii). Każdy z~czterech wierzchołków obrazu zostaje przesunięty o~losowy wektor o~maksymalnej amplitudzie regulowanej współczynnikiem $p in [0.0, 0.25]$.

Wizualizację syntetycznych zaburzeń dla przykładowych próbek przedstawiono na @fig-degradation-samples.

#figure(
  image("../../experiments/outputs/diagnostics/degradation_samples.png", width: 85%),
  caption: [Przykłady syntetycznych zniekształceń obrazów znaków: czyste próbki (górny wiersz) oraz warianty poddane rozmyciu, szumowi i deformacji perspektywicznej.],
) <fig-degradation-samples>

== Strategie uczenia modeli
W~celu rzetelnego porównania sformułowano dwie strategie trenowania modelu:

=== Model bazowy
Model bazowy (oznaczany jako *Model A*) trenowany jest wyłącznie na czystych obrazach wejściowych poddanych standardowej normalizacji. Strategia ta odpowiada powszechnej w~literaturze praktyce trenowania modeli na idealnych zbiorach referencyjnych.

=== Model uczony z uwzględnieniem degradacji
Model odporny (oznaczany jako *Model B*) wykorzystuje dynamiczną augmentację w~czasie treningu. Podczas konstruowania każdej minipartii danych, dla każdej próbki podejmowana jest niezależna decyzja (z prawdopodobieństwem $p=0.5$) o~zaaplikowaniu:
1. losowego rozmycia gaussowskiego ($sigma in [0.0, 2.0]$),
2. losowego szumu addytywnego ($s in [0.0, 0.15]$),
3. losowego zniekształcenia perspektywicznego ($p_text("dist") in [0.0, 0.25]$).

Daje to łącznie $2^3 = 8$ możliwych stanów augmentacji (od czystego obrazu aż po nałożenie wszystkich trzech zniekształceń jednocześnie), co zapobiega nadmiernemu dopasowaniu sieci do jednego typu zniekształcenia.

== Procedura eksperymentalna
Proces optymalizacji prowadzony był w~jednolitych warunkach sprzętowych i~hiperparametrycznych:
- Rozmiar minipartii (_batch size_): 512 próbek.
- Optymalizator: AdamW @loshchilov2017adamw ze stałą uczenia $lr = 0.001$ oraz zanikiem wag $10^(-4)$.
- Liczba epok: 25.
- Kryterium zapisu: Model o~najniższej wartości funkcji straty na zbiorze walidacyjnym zapisywany był jako punkt kontrolny `best.pt`.

== Metody oceny modeli
Ewaluację modeli oparto na zestawie komplementarnych wskaźników jakości:
1. *Dokładność ogólna (Top-1 Accuracy):* Odsetek prawidłowo zaklasyfikowanych znaków spośród wszystkich 62 klas.
2. *Dokładność bez rozróżniania wielkości liter (Case-Insensitive Accuracy):* Metryka traktująca małe i~wielkie litery o~zbliżonym kształcie jako równoważne. Zidentyfikowano 15 par wewnętrznie niejednoznacznych w~niskiej rozdzielczości bez linii pisma: $(C, c)$, $(J, j)$, $(K, k)$, $(O, o)$, $(P, p)$, $(S, s)$, $(U, u)$, $(V, v)$, $(W, w)$, $(X, x)$, $(Y, y)$, $(Z, z)$ oraz pary cyfra--litera: $(0, O)$, $(1, l)$, $(1, I)$.
3. *Metryki uśrednione makro:* Precyzja makro (Macro-Precision), pełność makro (Macro-Recall) oraz miara F1 makro (Macro-F1), uwzględniające zrównoważenie predykcji dla wszystkich klas.
4. *Pomiary efektywności sprzętowej:* Średnie opóźnienie inferencji pojedynczego znaku oraz przepustowość (liczba przetworzonych znaków na sekundę) na procesorze CPU oraz karcie graficznej GPU.

== Reprodukowalność eksperymentów
W~celu zapewnienia pełnej reprodukowalności badań:
- Wprowadzono centralną funkcję zarządzania ziarnem liczb pseudolosowych (`set_seed()`), inicjalizującą moduły bibliotek Python `random`, `numpy` oraz `torch`.
- Wszystkie indeksy podziału zbiorów utrwalono w~statycznych plikach manifestu CSV.
- Zależności biblioteczne i~wersje interpreterów zostały zablokowane za pomocą środowiska `uv`.
- Kluczowe eksperymenty powtórzono dla wielu niezależnych ziaren losowości w~celu weryfikacji właściwości agnostycyzmu względem inicjalizacji (_seed-agnosticism_).
