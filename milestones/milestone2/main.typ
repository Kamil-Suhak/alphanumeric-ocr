// Raport z Etapu 2 (Milestone 2) - Szablon sprawozdania dla promotora
#set document(title: "Raport Etapu 2: Ablacje, walidacja wieloziarnowa, OOD i optymalizacja INT8", author: "Kamil Sebastian Suhak")
#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  header: align(right)[#text(size: 8.5pt, fill: rgb("#666666"))[Praca Inżynierska | Raport z~Etapu 2 --- Kamil Sebastian Suhak]],
  footer: context align(center)[#text(size: 9pt)[#counter(page).display()]],
)
#set text(font: ("Times New Roman", "New Computer Modern"), size: 11pt, lang: "pl")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.")

#align(center)[
  #text(size: 16pt, weight: "bold")[Raport z~Postępów Prac: Etap 2\ Ablacje augmentacji, testy poza dziedziną i~optymalizacja brzegowa INT8]
  
  #v(0.3cm)
  #text(size: 12pt)[*Autor:* Kamil Sebastian Suhak | *Kierunek:* Technologie Przemysłu 4.0 | *AGH Kraków*]
  #v(0.1cm)
  #text(size: 10pt, fill: rgb("#555555"))[Data złożenia: [Do uzupełnienia] | Status: W~trakcie realizacji]
]

#v(0.5cm)
#line(length: 100%, stroke: 0.5pt + rgb("#cccccc"))
#v(0.5cm)

= Zakres planowanych prac w~Etapie 2
W~ramach drugiego etapu zaplanowano realizację następujących zadań zgodnych z~planem badawczym V3 (`EXP-003`–`EXP-010`):
1. *Walidacja wieloziarnowa (`seed in {123, 456, 789}`):* Powtórzenie treningu Modelu A (`baseline`) i~Modelu B (`robust`) dla trzech niezależnych ziaren losowości w~celu wyznaczenia średniej oraz odchylenia standardowego odporności (`EXP-006`).
2. *Ablacja pojedynczych czynników augmentacji (`EXP-003`–`EXP-005`):* Wytrenowanie trzech wariantów pośrednich (wyłącznie rozmycie Gaussa, wyłącznie szum, wyłącznie perspektywa) i~zestawienie macierzy transferu odporności między modalnościami.
3. *Wyjaśnialność wizualna Grad-CAM (`EXP-007`):* Porównanie map atencji warstw splotowych Modelu A i~Modelu B na próbkach czystych oraz zdegradowanych.
4. *Kwantyzacja statyczna INT8 i~profilowanie ONNX Runtime (`EXP-008`):* Eksport modelu do formatu ONNX FP32, statyczna kwantyzacja QDQ INT8 kalibrowana na `1000` próbkach walidacyjnych oraz weryfikacja retencji dokładności i~latencji CPU.
5. *Złożone scenariusze zakłóceń i~rozmycie ruchowe poza dziedziną (`EXP-009`) oraz stratyfikacja błędów (`EXP-010`):* Ewaluacja sekwencji `Perspective -> Blur -> Noise` na trzech progach intensywności, test poziomego rozmycia ruchowego (`L in {3, 5, 7, 9, 11}`) oraz czterokwadrantowa analiza pomyłek i~15 par homoglificznych.

= Postęp prac i wstępne pomiary
[Miejsce na wykresy i tabele z wynikami Etapu 2 --- po wygenerowaniu przez skrypty w `experiments/outputs/`]
