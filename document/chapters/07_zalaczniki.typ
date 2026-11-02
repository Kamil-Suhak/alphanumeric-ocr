#import "../metadata.typ": *

#pagebreak()
#heading(level: 1, numbering: none)[Załączniki]

#heading(level: 2, numbering: none)[Załącznik A: Zestawienie par homomorficznych w zbiorze EMNIST ByClass]
W~tabeli @tab-ambiguity-pairs zestawiono 15 zidentyfikowanych par znaków alfanumerycznych, które w~rozdzielczości $32 times 32$ piksele bez kontekstu linii bazowej tekstu i~wysokości pisma wykazują niemal pełną tożsamość morfologiczną.

#figure(
  table(
    columns: (1fr, 2fr, 2fr, 3fr),
    align: (center, center, center, left),
    table.header([*Lp.*], [*Znak 1*], [*Znak 2*], [*Typ niejednoznaczności*]),
    [1], [`C` (wielkie)], [`c` (małe)], [Homomorfizm skali litery],
    [2], [`J` (wielkie)], [`j` (małe)], [Homomorfizm (zależny od obecności kropki)],
    [3], [`K` (wielkie)], [`k` (małe)], [Homomorfizm proporcji ramion],
    [4], [`O` (wielkie)], [`o` (małe)], [Homomorfizm skali litery],
    [5], [`P` (wielkie)], [`p` (małe)], [Homomorfizm linii bazowej (ogonek)],
    [6], [`S` (wielkie)], [`s` (małe)], [Homomorfizm skali litery],
    [7], [`U` (wielkie)], [`u` (małe)], [Homomorfizm skali litery],
    [8], [`V` (wielkie)], [`v` (małe)], [Homomorfizm skali litery],
    [9], [`W` (wielkie)], [`w` (małe)], [Homomorfizm skali litery],
    [10], [`X` (wielkie)], [`x` (małe)], [Homomorfizm skali litery],
    [11], [`Y` (wielkie)], [`y` (małe)], [Homomorfizm linii bazowej],
    [12], [`Z` (wielkie)], [`z` (małe)], [Homomorfizm skali litery],
    [13], [`0` (cyfra)], [`O` (wielkie litera)], [Niejednoznaczność cyfra--litera],
    [14], [`1` (cyfra)], [`l` (małe L)], [Niejednoznaczność pionowej kreski],
    [15], [`1` (cyfra)], [`I` (wielkie i)], [Niejednoznaczność pionowej kreski],
  ),
  caption: [Lista 15 par znaków wewnętrznie niejednoznacznych w zbiorze EMNIST ByClass.],
) <tab-ambiguity-pairs>

#heading(level: 2, numbering: none)[Załącznik B: Parametry konfiguracyjne eksperymentów]
Konfiguracja treningowa modelu bazowego (`baseline.yaml`):
```yaml
experiment:
  name: EXP-001_baseline
  seed: 123
data:
  dataset: emnist_byclass
  image_size: 32
  padding: 2
  batch_size: 512
training:
  epochs: 25
  optimizer: adamw
  lr: 0.001
  weight_decay: 0.0001
model:
  name: AlphanumericCNN
  num_classes: 62
  dropout: 0.5
augmentation:
  enabled: false
```

Konfiguracja treningowa modelu odpornego (`robust.yaml`):
```yaml
experiment:
  name: EXP-002_robust
  seed: 123
data:
  dataset: emnist_byclass
  image_size: 32
  padding: 2
  batch_size: 512
training:
  epochs: 25
  optimizer: adamw
  lr: 0.001
  weight_decay: 0.0001
model:
  name: AlphanumericCNN
  num_classes: 62
  dropout: 0.5
augmentation:
  enabled: true
  blur_prob: 0.5
  max_sigma: 2.0
  noise_prob: 0.5
  max_noise_std: 0.15
  perspective_prob: 0.5
  max_perspective_severity: 0.15
```
