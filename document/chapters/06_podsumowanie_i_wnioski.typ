#import "../metadata.typ": *

= Podsumowanie i wnioski

== Podsumowanie przeprowadzonych badań
// [Section Guide]: Synthesize the end-to-end engineering and research workflow accomplished in the thesis: from building the deterministic 32x32 zero-padded EMNIST ByClass pipeline and designing the compact 2.42 MB AlphanumericCNN architecture, to implementing the continuous degradation simulator and executing over 4.42 million evaluation passes. Keep this as a high-level executive recap without introducing new tables.
// Recommended citations: @cohen2017emnist

== Odpowiedzi na pytania badawcze
// [Section Guide]: Provide direct, structured, one-by-one answers to Research Questions 1–4 defined in Section 1.3, backing each answer with the exact key empirical deltas (e.g., Model A's collapse to 4.28% under sigma=3.0 blur vs. Model B's +60.16 p.p. retention, the -0.16 p.p. clean parity difference, and the +3.34/+3.42 p.p. homoglyph recovery).
// Recommended citations: @cohen2017emnist, @hendrycks2019benchmarking

== Ograniczenia pracy
// [Section Guide]: Critically and transparently discuss the methodological boundaries of the study: classification of isolated 32x32 single-character crops without sequence/word-level language context (which makes homoglyphs like 0/O and C/c inherently indistinguishable), reliance on synthetic parametric approximations of optical and sensor degradations, and evaluation on grayscale handwritten/printed crops rather than full scene-text detection pipelines.
// Recommended citations: @cohen2017emnist, @chen2021text

== Możliwe kierunki dalszych badań
// [Section Guide]: Outline concrete, technically grounded extensions for future work: integrating the robust AlphanumericCNN backbone with a lightweight sequence decoder (e.g., CRNN/CTC or n-gram post-processing) to resolve homoglyph ambiguity via word context, applying post-training INT8 quantization or ONNX Runtime deployment on ARM microcontrollers, and extending the degradation simulator with motion blur kernels and uneven illumination gradients.
// Recommended citations: @chen2021text, @trivedi2026improving
