// Szablon pracy dyplomowej inżynierskiej AGH (Typst v0.15+)

// Pomocnicze funkcje formatowania liczb i metryk dla tabel empirycznych
#let fmt_val(val, digits: 2, unit: "%") = {
  let r = calc.round(val, digits: digits)
  let parts = str(calc.abs(r)).split(".")
  let int_part = parts.at(0)
  let frac_part = if parts.len() > 1 { parts.at(1) } else { "" }
  while frac_part.len() < digits {
    frac_part = frac_part + "0"
  }
  let sign_str = if r < 0 { "-" } else { "" }
  sign_str + int_part + "," + frac_part + unit
}

#let fmt_diff(val, digits: 2, unit: " p.p.") = {
  let r = calc.round(val, digits: digits)
  let parts = str(calc.abs(r)).split(".")
  let int_part = parts.at(0)
  let frac_part = if parts.len() > 1 { parts.at(1) } else { "" }
  while frac_part.len() < digits {
    frac_part = frac_part + "0"
  }
  let sign_str = if r < 0 { "-" } else if r > 0 { "+" } else { "" }
  sign_str + int_part + "," + frac_part + unit
}

#let agh_thesis(
  title_pl: "",
  title_en: "",
  author: "",
  album_no: "",
  supervisor: "",
  faculty: "",
  department: "",
  field_of_study: "",
  city: "Kraków",
  year: "2026",
  line_spacing: 1.25,
  font_family: ("Times New Roman", "New Computer Modern"),
  body,
) = {
  // 1. Podstawowe ustawienia dokumentu i strony
  set document(title: title_pl, author: author)

  set page(
    paper: "a4",
    margin: (
      inside: 3.0cm, // Margines na oprawę
      outside: 2.0cm,
      top: 2.0cm,
      bottom: 2.0cm,
    ),
    header: context {
      let page_num = counter(page).get().first()
      let in_chapters = counter(heading.where(level: 1)).get().first() > 0
      // Wyświetlaj nagłówek wyłącznie w treści rozdziałów (po spisie treści)
      if in_chapters {
        set text(size: 8.5pt, fill: rgb("#555555"))
        grid(
          columns: (1fr, auto),
          align(left + bottom)[#author --- #title_pl], align(right + bottom)[#page_num],
        )
        v(-0.15cm)
        line(length: 100%, stroke: 0.5pt + rgb("#cccccc"))
      }
    },
    footer: none,
  )

  set text(
    font: font_family,
    size: 12pt,
    lang: "pl",
  )

  // Interlinia oraz wcięcie akapitowe
  set par(
    justify: true,
    leading: line_spacing * 0.55em,
    first-line-indent: 0.8cm,
  )

  // 2. Formatowanie podpisów rysunków i tabel (Wytyczne: tabele podpis nad, rysunki pod)
  show figure.where(kind: table): set figure.caption(position: top)
  show figure.where(kind: image): set figure.caption(position: bottom)
  show figure.caption: c => {
    set text(size: 10.5pt)
    c
  }

  // 3. Hierarchia nagłówków
  set heading(numbering: "1.1.")

  show heading: it => {
    set text(weight: "bold")
    let num_prefix = if it.numbering != none {
      counter(heading).display() + " "
    } else {
      ""
    }
    if it.level == 1 {
      // Rozdział główny: nowa strona, 15pt bold
      pagebreak(weak: true)
      v(1.5cm)
      text(size: 15pt)[#num_prefix#it.body]
      v(1cm)
    } else if it.level == 2 {
      // Podrozdział: 13pt bold
      v(0.8cm)
      text(size: 13pt)[#num_prefix#it.body]
      v(0.4cm)
    } else {
      // Dalsze poziomy: 12pt bold
      v(0.5cm)
      text(size: 12pt)[#num_prefix#it.body]
      v(0.3cm)
    }
  }

  // ==========================================
  // STRONA TYTUŁOWA AGH (wzór Z1A WEAIiIB)
  // ==========================================
  align(center)[
    #image("../assets/agh_logo.jpg", width: 8.5cm)

    #v(0.6cm)
    #text(size: 11pt, weight: "bold", hyphenate: false)[
      WYDZIAŁ ELEKTROTECHNIKI, AUTOMATYKI, INFORMATYKI\ I INŻYNIERII BIOMEDYCZNEJ
    ]

    #if department != "" [
      #v(0.2cm)
      #text(size: 11pt, weight: "medium")[#department]
    ]

    #v(1.8cm)
    #text(size: 16pt, weight: "bold")[Projekt dyplomowy]

    #v(1.4cm)
    #text(size: 14pt, style: "italic", hyphenate: false)[#title_pl]

    #v(0.3cm)
    #text(size: 11.5pt, style: "italic", hyphenate: false)[#title_en]

    #v(2.2cm)
    #align(left)[
      #block(inset: (left: 2.0cm))[
        #grid(
          columns: (auto, auto),
          gutter: 1.0em,
          [Autor:], [*#author*],
          [Kierunek studiów:], [*#field_of_study*],
          [Opiekun pracy:], [*#supervisor*],
        )
      ]
    ]

    #v(1fr)
    #text(size: 11pt)[#city, #year]
  ]

  // Reset licznika stron po stronie tytułowej
  pagebreak()
  counter(page).update(1)

  // Treść właściwa
  body
}
