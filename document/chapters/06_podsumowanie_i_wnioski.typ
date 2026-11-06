#import "../metadata.typ": *

= Podsumowanie i wnioski

== Podsumowanie przeprowadzonych badań
// [Wskazówki autorskie]: Syntetycznie podsumować zrealizowany w pracy potok inżyniersko-badawczy: od opracowania deterministycznego przetwarzania wstępnego EMNIST ByClass (format $32 times 32$ z dopełnieniem zerami) i projektu kompaktowej sieci AlphanumericCNN (2,42 MB), przez implementację silnika degradacji ciągłych, aż po przeprowadzenie ponad 4,42 miliona operacji inferencji w testach odporności. Utrzymać charakter syntetycznego podsumowania menedżerskiego bez wprowadzania nowych tabel.
// Rekomendowana literatura: @cohen2017emnist
#lorem(150)

#lorem(150)

== Odpowiedzi na pytania badawcze
// [Wskazówki autorskie]: Przedstawić bezpośrednie, uporządkowane punkt po punkcie odpowiedzi na Pytania Badawcze 1–4 postawione w Rozdziale 1.3, popierając każdą odpowiedź konkretnymi, kluczowymi deltami empirycznymi (np. spadek Modelu A do 4,28% przy rozmyciu $sigma = 3,0$ w kontraście do zachowania 64,44% przez Model B, minimalna różnica na danych czystych wynosząca -0,16 p.p. oraz zysk +3,34/+3,42 p.p. po ujednoliceniu par homoglificznych).
// Rekomendowana literatura: @cohen2017emnist, @hendrycks2019benchmarking
#lorem(115)

#lorem(115)

#lorem(110)

#lorem(110)

== Ograniczenia pracy
// [Wskazówki autorskie]: Krytycznie i transparentnie omówić metodyczne ograniczenia projektu: klasyfikację wyizolowanych wycinków znaków $32 times 32$ w oderwaniu od kontekstu leksykalnego całego wyrazu (co czyni znaki takie jak 0/O czy C/c obiektywnie nierozróżnialnymi), oparcie badań na syntetycznych, parametrycznych modelach zakłóceń optycznych i matrycowych, a także skupienie się na wycinkach w odcieniach szarości zamiast pełnego potoku detekcji tekstu w scenach naturalnych.
// Rekomendowana literatura: @cohen2017emnist, @chen2021text
#lorem(140)

#lorem(140)

== Możliwe kierunki dalszych badań
// [Wskazówki autorskie]: Wskazać uzasadnione technicznie i merytorycznie kierunki kontynuacji prac: integrację odpornego ekstraktora cech AlphanumericCNN z lekkim dekoderem sekwencyjnym (np. CRNN/CTC lub modułem post-processingu n-gramowego) w celu eliminacji niejednoznaczności homoglificznych dzięki kontekstowi słowa, kwantyzację post-treningową INT8 i wdrożenie produkcyjne za pośrednictwem środowiska ONNX Runtime na mikrokontrolerach ARM, a także rozszerzenie symulatora o kierunkowe rozmycie ruchowe (ang. motion blur) oraz niejednorodne gradienty oświetlenia.
// Rekomendowana literatura: @chen2021text, @trivedi2026improving
#lorem(140)

#lorem(140)
