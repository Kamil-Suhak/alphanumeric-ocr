#import "../metadata.typ": *

= Podstawy teoretyczne i stan wiedzy

== Optyczne rozpoznawanie znaków alfanumerycznych
// [Section Guide]: Introduce the domain of Optical Character Recognition (OCR) and contrast full multi-stage pipelines (text detection, line segmentation, sequential recognition) with isolated character classification on edge devices. Discuss why environmental degradations in industrial and mobile imagery break classical thresholding and template-matching approaches, motivating learned spatial representations.
// Recommended citations: @ye2015text, @chen2021text, @du2013automatic, @campos2009chars74k

== Sformułowanie problemu klasyfikacji obrazów
// [Section Guide]: Formally define multi-class single-channel image classification as learning a parametric mapping from a normalized pixel grid to a discrete probability simplex over K=62 alphanumeric classes. Briefly explain why flattening 2D images into 1D vectors for standard multilayer perceptrons destroys local spatial topology and lacks translation invariance.
// Recommended citations: @goodfellow2016deep, @lecun1998lenet

== Konwolucyjne sieci neuronowe
// [Section Guide]: Provide a concise architectural overview of hierarchical feature extraction in convolutional networks, explaining how successive stages progress from low-level edge and stroke detectors to higher-level morphological glyph descriptors. Keep this introductory umbrella brief (1-2 paragraphs) before diving into the four layer-specific subsections below.
// Recommended citations: @lecun1998lenet, @goodfellow2016deep

=== Warstwy konwolucyjne
// [Section Guide]: Present the mathematical formulation of the discrete 2D cross-correlation/convolution operator, local receptive fields, weight sharing, and zero-padding for preserving spatial dimensions. Explain how small 3x3 kernels capture stroke orientation and curvature with minimal parameter overhead.
// Recommended citations: @lecun1998lenet, @goodfellow2016deep

=== Funkcje aktywacji
// [Section Guide]: Explain why non-linear activation functions are required to prevent a multi-layer network from collapsing into a single linear transformation. Define the Rectified Linear Unit (ReLU), highlight its computational efficiency and non-saturating positive gradient compared to sigmoid/tanh, and mention dead-neuron considerations.
// Recommended citations: @he2015delving, @goodfellow2016deep

=== Normalizacja i agregacja cech
// [Section Guide]: Detail Batch Normalization (normalizing channel activations via mini-batch statistics with learnable affine parameters gamma and beta) and spatial downsampling via 2x2 Max Pooling. Explain how Batch Normalization stabilizes gradient flow and acts as an implicit regularizer, while Max Pooling halves spatial resolution and provides local translation invariance.
// Recommended citations: @ioffe2015batchnorm, @lecun1998lenet, @goodfellow2016deep

=== Warstwa klasyfikacyjna
// [Section Guide]: Describe the transition from 3D convolutional feature maps to the dense classification head via tensor flattening, fully connected projections, Dropout regularization, and the output Softmax transformation. Explain how Dropout randomly zeroes activations during training to prevent co-adaptation of features.
// Recommended citations: @srivastava2014dropout, @goodfellow2016deep

== Uczenie modeli klasyfikacyjnych
// [Section Guide]: Formulate the categorical cross-entropy loss function and explain how parameters are updated via backpropagation and stochastic gradient descent with adaptive moment estimation. Specifically contrast standard L2 regularization with decoupled weight decay in the AdamW optimizer and explain why minimum validation loss is used for checkpoint selection.
// Recommended citations: @goodfellow2016deep, @kingma2014adam, @loshchilov2017adamw, @he2015delving

== Odporność modeli na degradację obrazu
// [Section Guide]: Analyze why standard CNNs trained solely on clean benchmark distributions suffer sharp accuracy drops under covariate and corruption shifts (such as defocus blur, sensor noise, and projective skew). Discuss the frequency-domain and spatial mechanisms behind this vulnerability, noting how high-frequency noise spikes and low-pass blur distort learned filter activations.
// Recommended citations: @hendrycks2019benchmarking, @dodge2016understanding, @vasiljevic2016examining, @gonzalez2018digital

== Metody zwiększania odporności modeli
// [Section Guide]: Survey literature strategies for improving corruption robustness, comparing pre-processing/denoising pipelines against stochastic on-the-fly training data augmentation. Justify why training-time augmentation is favored for embedded OCR: it shifts all computational overhead to the offline training phase while maintaining zero extra latency during inference.
// Recommended citations: @shorten2019survey, @hendrycks2019benchmarking, @vasiljevic2016examining, @trivedi2026improving
