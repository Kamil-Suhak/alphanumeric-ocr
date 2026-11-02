#import "../metadata.typ": *
#import "../template/agh_thesis.typ": fmt_val, fmt_diff

#let results = json("../../experiments/outputs/tables/accuracy_summary.json")

= Podsumowanie i wnioski

== Podsumowanie przeprowadzonych badań
Niniejsza praca inżynierska poświęcona została zbadaniu i~zwiększeniu odporności kompaktowych konwolucyjnych sieci neuronowych na degradacje środowiskowe w~zadaniu klasyfikacji 62 klas znaków alfanumerycznych.

W~ramach realizacji projektu:
1. Zaprojektowano i~zaimplementowano lekką architekturę splotową *AlphanumericCNN* (634~tys. parametrów, 2,42~MB wag w~formacie FP32), przystosowaną do wymagań systemów wbudowanych.
2. Opracowano parametryczny symulator degradacji syntetycznych obejmujący rozmycie optyczne, addytywny szum matrycy CMOS oraz transformacje perspektywiczne.
3. Przeprowadzono rygorystyczny proces treningowy na korpusie EMNIST ByClass (ponad 814~tys. próbek) z~wykorzystaniem deterministycznego dopełnienia zerami oraz utrwalonych podziałów danych.
4. Zrealizowano kompleksową ewaluację empiryczną porównującą model bazowy (Model A) oraz model z~dynamiczną augmentacją zniekształceniami (Model B).

== Odpowiedzi na pytania badawcze
W~oparciu o~uzyskane wyniki empiryczne sformułowano bezpośrednie odpowiedzi na cztery pytania badawcze postawione w~rozdziale pierwszym:

1. *Odpowiedź na Pytanie 1 (Dynamika załamania modelu bazowego):* Model uczony wyłącznie na idealnych danych referencyjnych wykazuje skrajną niestabilność decyzyjną. Spadek dokładności ma charakter nieliniowy i~prowadzi do katastrofalnego załamania: przy umiarkowanym rozmyciu ($sigma = 2.0$) skuteczność Modelu A spada z~#fmt_val(results.clean_baseline.accuracy) do zaledwie #fmt_val(results.clean_baseline.blur_sigma_2_0), a~w~warunkach szumu matrycy ($s = 0.20$) do poziomu #fmt_val(results.clean_baseline.noise_std_0_20).
2. *Odpowiedź na Pytanie 2 (Skuteczność regularyzacji degradacyjnej):* Zastosowanie losowego potoku degradacji w~trakcie treningu pozwala na spektakularny wzrost odporności. Zysk dokładności Modelu B w~warunkach silnego rozmycia sięga aż *#fmt_diff(results.robust_cnn.blur_sigma_2_0 - results.clean_baseline.blur_sigma_2_0)*, a~przy szumie sensora wynosi *#fmt_diff(results.robust_cnn.noise_std_0_20 - results.clean_baseline.noise_std_0_20)*. Co niezwykle istotne, koszt odporności na czystym zbiorze testowym wynosi jedynie #fmt_diff(results.robust_cnn.accuracy - results.clean_baseline.accuracy), przy jednoczesnym wzroście precyzji makro o~#fmt_diff(results.robust_cnn.macro_precision - results.clean_baseline.macro_precision).
3. *Odpowiedź na Pytanie 3 (Bariera niejednoznaczności morfologicznej):* Analiza błędów potwierdziła istnienie obiektywnej granicy dokładności na poziomie około 3,3 punktu procentowego, wynikającej z~identycznego kształtu 15 par wielkich i~małych znaków (np. $C/c$, $O/o$, $S/s$, $0/O$) pozbawionych kontekstu linii bazowej. Zastosowanie ewaluacji niewrażliwej na wielkość liter podnosi dokładność Modelu B do #fmt_val(results.robust_cnn.case_insensitive_accuracy), dowodząc ponad 90-procentowej czystości rozpoznawania geometrii glifów.
4. *Odpowiedź na Pytanie 4 (Agnostycyzm względem ziarna losowości):* Wielokrotne powtórzenie eksperymentów dla różnych ziaren generatora liczb pseudolosowych wykazało odchylenie standardowe metryk poniżej 0,25 p.p. Nabyta odporność jest zatem trwałą cechą struktury wagowej wymuszonej przez proces optymalizacji, a~nie przypadkowym punktem minimum.

== Ograniczenia pracy
Do głównych ograniczeń zrealizowanych badań należy zaliczyć:
- *Syntetyczny charakter degradacji:* Matematyczne modele zniekształceń stanowią przybliżenie zjawisk fizycznych; rzeczywiste matryce fotograficzne mogą generować nieliniowe aberracje chromatyczne, winietowanie czy flary optyczne.
- *Brak kontekstu lingwistycznego:* Praca koncentruje się na wyizolowanych wycinkach pojedynczych znaków $32 times 32$ piksele. W~pełnym systemie OCR informacja leksykalna (słowniki, modele językowe) pozwoliłaby na bezbłędne rozstrzyganie par homomorficznych.
- *Monochromatyczność wejścia:* Wszystkie badania prowadzono na obrazach w~skali szarości, pomijając barwne cechy tła i~kontrastu koloru.

== Możliwe kierunki dalszych badań
Zidentyfikowane ograniczenia wyznaczają obiecujące kierunki kontynuacji prac badawczo-rozwojowych:
1. *Integracja z~detektorami tekstu:* Połączenie modelu AlphanumericCNN z~lekką siecią detekcji (np. DBNet-Mobile), tworząc kompletny system end-to-end do inspekcji wizyjnej w~czasie rzeczywistym.
2. *Optymalizacja sprzętowa i~kwantyzacja:* Konwersja wag do formatu ONNX oraz ewaluacja wpływu kwantyzacji do 8-bitowych liczb całkowitych (INT8) na opóźnienia i~pobór mocy dedykowanych koprocesorów neuronowych (NPU).
3. *Eksploracja małych architektur transformatorowych:* Zbadanie podatności na degradacje kompaktowych modeli typu Vision Transformer (np. MobileViT) w~zadaniu klasyfikacji wycinków o~niskiej rozdzielczości.
