#import "../metadata.typ": *

= Metodyka badań i architektura modelu

== Architektura AlphanumericCNN
Projekt sieci podporządkowano kryteriom lekkości, niskiego narzutu pamięciowego i deterministycznego czasu wnioskowania na urządzeniach brzegowych. Zastosowano architekturę splotową złożoną z trzech bloków ekstrakcji cech oraz dwuwarstwowej głowicy decyzyjnej.

#figure(
  table(
    columns: (1.5fr, 3fr, 1.5fr),
    align: (left, left, center),
    table.header([*Etap / Warstwa*], [*Operacje składowe*], [*Rozmiar tensora*]),
    [Wejście], [Obraz w skali szarości po dopełnieniu zerami], [$1 times 32 times 32$],
    [Blok splotowy 1], [Conv2D($1 -> 32$, $k=3$, $p=1$) + BatchNorm2D + ReLU + MaxPool($2 times 2$)], [$32 times 16 times 16$],
    [Blok splotowy 2], [Conv2D($32 -> 64$, $k=3$, $p=1$) + BatchNorm2D + ReLU + MaxPool($2 times 2$)], [$64 times 8 times 8$],
    [Blok splotowy 3], [Conv2D($64 -> 128$, $k=3$, $p=1$) + BatchNorm2D + ReLU + MaxPool($2 times 2$)], [$128 times 4 times 4$],
    [Spłaszczenie], [Flatten ($128 times 4 times 4$)], [$2048$],
    [Głowica liniowa 1], [Linear($2048 -> 256$) + BatchNorm1D + ReLU + Dropout($p=0.5$)], [$256$],
    [Wyjście], [Linear($256 -> 62$) (Logits)], [$62$],
  ),
  caption: [Architektura warstwowa sieci AlphanumericCNN.],
) <tab-architektura>

Całkowita liczba parametrów wynosi *634 110* (wszystkie uczone). Wagi w formacie FP32 zajmują zaledwie *2,42 MB*, co umożliwia bezproblemowe załadowanie modelu do pamięci podręcznej L2/L3 procesora wbudowanego.

== Generator syntetycznych degradacji (Degradation Simulator Engine)
W potoku uczenia Modelu B zastosowano niezależne prawdopodobieństwo $p=0.5$ zaaplikowania każdego z trzech rodzajów zaburzeń w locie na poziomie minibatches:
- Rozmycie gaussowskie: $sigma in [0.0, 2.0]$,
- Szum gaussowski: $s in [0.0, 0.15]$,
- Zniekształcenie perspektywiczne: $p_text("dist") in [0.0, 0.25]$.

Daje to kombinację 8 stanów augmentacji (wszystkie trzy naraz, dowolne dwie, jedna lub czysty obraz). Zapobiega to zjawisku overfittingu do pojedynczego wzorca zaburzenia.

== Protokół trenowania i optymalizacji
- *Optymalizator:* AdamW @loshchilov2017adamw z parametrami $lr = 0.001$, $text("weight decay") = 10^(-4)$.
- *Funkcja straty:* Wieloklasowa entropia krzyżowa (Cross-Entropy Loss).
- *Rozmiar partii:* $512$ próbek.
- *Liczba epok:* $25$ epok.
- *Zapis punktów kontrolnych:* Checkpoint `best.pt` zapisywany wyłącznie dla epoki o minimalnej stracie na zbiorze walidacyjnym.

== Wymóg agnostycyzmu względem ziarna losowości (Seed-Agnosticism)
Aby wykluczyć podejrzenie, że wysoka odporność Modelu B wynika z przypadkowej, korzystnej konfiguracji wag początkowych lub specyficznej kolejności tasowania danych, protokół badawczy przewiduje weryfikację na wielu ziarnach generatora liczb pseudolosowych (np. ziarna 123, 42, 999). Wyniki raportowane są w postaci wartości średniej i odchylenia standardowego metryk, co stanowi warunek konieczny rzetelności inżynierskiej.

#block(fill: rgb("#f5f5f7"), inset: 1em, radius: 4pt)[
  #text(weight: "bold")[Wytyczne redakcyjne do rozwinięcia rozdziału:]
  - [ ] Wstawić schemat blokowy architektury (SVG) z wizualizacją map cech.
  - [ ] Dodać szczegółowy opis implementacji zniekształcenia homograficznego w OpenCV/Albumentations.
]
