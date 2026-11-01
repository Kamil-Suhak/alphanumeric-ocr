// Raport z Etapu 2 (Milestone 2) - Szablon sprawozdania dla promotora
#set document(title: "Raport Etapu 2: Ewaluacja na zdjęciach rzeczywistych i generalizacja", author: "Kamil Suhak")
#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 2.5cm),
  header: align(right)[#text(size: 8.5pt, fill: rgb("#666666"))[Praca Inżynierska | Raport z Etapu 2 --- Kamil Suhak]],
  footer: context align(center)[#text(size: 9pt)[#counter(page).display()]],
)
#set text(font: ("Times New Roman", "New Computer Modern"), size: 11pt, lang: "pl")
#set par(justify: true, leading: 0.65em)
#set heading(numbering: "1.1.")

#align(center)[
  #text(size: 16pt, weight: "bold")[Raport z Postępów Prac: Etap 2\ Ewaluacja na fotografiach rzeczywistych i analiza generalizacji]
  
  #v(0.3cm)
  #text(size: 12pt)[*Autor:* Kamil Suhak | *Kierunek:* Informatyka | *AGH Kraków*]
  #v(0.1cm)
  #text(size: 10pt, fill: rgb("#555555"))[Data złożenia: [Do uzupełnienia] | Status: W trakcie realizacji]
]

#v(0.5cm)
#line(length: 100%, stroke: 0.5pt + rgb("#cccccc"))
#v(0.5cm)

== 1. Zakres planowanych prac w Etapie 2
W ramach drugiego etapu zaplanowano następujące zadania:
1. *Akwizycja zbioru zdjęć rzeczywistych (Real-World Photos):* Zebranie próbek znaków alfanumerycznych sfotografowanych aparatem smartfona w warunkach zmiennego oświetlenia i kąta.
2. *Benchmark transferu na zbiorze Chars74K:* Porównanie zdolności generalizacji Modelu A i Modelu B na zewnętrznej domenie czcionek naturalnych.
3. *Walidacja agnostycyzmu względem ziarna (Multi-Seed Validation):* Powtórzenie cyklu treningowego dla 3 różnych ziaren losowości w celu wyznaczenia przedziałów ufności dla zysków odporności.
4. *Eksport ONNX i testy na mikrokontrolerze / urządzeniu brzegowym.*

== 2. Postęp prac i wstępne pomiary
[Miejsce na wykresy i tabele z wynikami Etapu 2 --- po wygenerowaniu przez skrypty w `experiments/outputs/`]
