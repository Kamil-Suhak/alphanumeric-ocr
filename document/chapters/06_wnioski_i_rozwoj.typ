#import "../metadata.typ": *

= Wnioski końcowe i perspektywy rozwoju

== Wnioski z przeprowadzonych badań
Przeprowadzone eksperymenty dostarczyły jednoznacznych dowodów na słuszność postawionych hipotez badawczych:
1. *Wrażliwość modelu czystego:* Konwencjonalny proces uczenia, oparty wyłącznie na idealnych danych laboratoryjnych, generuje reprezentacje cech skrajnie niestabilne w obecności dystrybucji zaburzonych. Załamanie dokładności poniżej progu 50% następuje przy relatywnie niskich poziomach rozmycia i szumu.
2. *Skuteczność regularyzacji degradacyjnej:* Trening z wykorzystaniem losowego potoku degradacji syntetycznych podnosi próg odporności sieci o kilkadziesiąt punktów procentowych (aż do $+60,16$ p.p. w reżimie silnego rozmycia), nie powodując istotnego uszczerbku dla dokładności na czystym wejściu.
3. *Weryfikacja bariery 90%:* Zastosowanie metryki niewrażliwej na wielkość liter potwierdziło, że około $3.3$--$3.4$ p.p. błędów klasyfikacji na izolowanych wycinkach wynika z nieusuwalnej niejednoznaczności par znaków o identycznej morfologii.
4. *Wysoka wydajność brzegowa:* Czas wnioskowania na poziomie około $1$ ms na rdzeniu CPU oraz mały rozmiar pliku wag ($2.42$ MB) potwierdzają pełną przydatność zaproponowanej architektury do pracy w systemach wbudowanych czasu rzeczywistego.

== Ograniczenia obecnego etapu prac
- *Syntetyczny charakter degradacji:* Zaburzenia matematyczne stanowią aproksymację zjawisk fizycznych. Rzeczywiste zniekształcenia optyczne telefonów komórkowych mogą łączyć aberracje chromatyczne, winietowanie oraz specyficzne flary świetlne.
- *Ograniczenie do jednej domeny źródłowej:* Badania prowadzono na odręcznym piśmie bazy EMNIST.

== Planowane kolejne fazy badawcze
1. *Faza ewaluacji na fotografiach rzeczywistych (Real-World Photos):* Pozyskanie i otestowanie modeli na zbiorze wycinków znaków sfotografowanych smartfonem w zróżnicowanych warunkach oświetleniowych.
2. *Faza generalizacji na zbiorze Chars74K:* Zbadanie przenoszalności wyuczonych cech na czcionki drukarskie i napisy w scenach naturalnych.
3. *Eksport ONNX i optymalizacja kwantyzacyjna:* Konwersja modelu do formatu ONNX oraz ewaluacja wpływu kwantyzacji INT8 na dokładność i zużycie energii procesora brzegowego.

#block(fill: rgb("#f5f5f7"), inset: 1em, radius: 4pt)[
  #text(weight: "bold")[Wytyczne redakcyjne do rozwinięcia rozdziału:]
  - [ ] Rozwinąć sekcję rekomendacji wdrożeniowych dla inżynierów projektujących systemy OCR.
  - [ ] Dodać tabelaryczne zestawienie hipotez z jednoznacznym statusem ich empirycznej weryfikacji.
]
