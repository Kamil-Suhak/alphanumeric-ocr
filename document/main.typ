#import "metadata.typ": *
#import "template/agh_thesis.typ": agh_thesis

#show: agh_thesis.with(
  title_pl: title_pl,
  title_en: title_en,
  author: author,
  album_no: album_no,
  supervisor: supervisor,
  faculty: faculty,
  department: department,
  field_of_study: field_of_study,
  city: city,
  year: year,
  line_spacing: line_spacing,
  font_family: font_family,
)

// ==========================================
// SPIS TREŚCI
// ==========================================
#outline(
  title: [Spis treści],
  depth: 3,
  indent: auto,
)

// ==========================================
// ROZDZIAŁY PRACY
// ==========================================
#include "chapters/01_wstep.typ"
#include "chapters/02_podstawy_teoretyczne.typ"
#include "chapters/03_metodyka_badan.typ"
#include "chapters/04_implementacja_systemu.typ"
#include "chapters/05_wyniki_badan.typ"
#include "chapters/06_podsumowanie_i_wnioski.typ"

// ==========================================
// WYKAZ LITERATURY (Hayagriva YAML)
// ==========================================
#pagebreak()
#bibliography(
  "references/library.yaml",
  style: "ieee",
  title: "Wykaz literatury",
)

// ==========================================
// SPISY RYSUNKÓW I TABEL
// ==========================================
#pagebreak()
#heading(level: 1, numbering: none)[Spis rysunków]
#outline(
  title: none,
  target: figure.where(kind: image),
)

#pagebreak()
#heading(level: 1, numbering: none)[Spis tabel]
#outline(
  title: none,
  target: figure.where(kind: table),
)

// ==========================================
// ZAŁĄCZNIKI
// ==========================================
#include "chapters/07_zalaczniki.typ"
