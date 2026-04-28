# Thesis Outline: Knowledge Distillation under Practical Constraints for Models and Datasets

# Chapter 1: Introduction

## Section 1.1: Large-Scale Models and the Case for Distillation
- Deep learning's history: scale as the dominant trend (bitter lesson).
- The deployment gap: models scale but inference requirements become incompatible with real-world constraints.
- Compression addresses two complementary dimensions: model size (fewer parameters) and data requirements (smaller training sets).
- Model compression: pruning, quantization, NAS, and knowledge distillation.
- Data compression: dataset distillation and related synthetic data approaches.
- Both compression dimensions are essential and complementary: model compression alone doesn't solve data efficiency, and data compression alone doesn't reduce computational deployment burden—together they address the full spectrum of constraints.

## Section 1.2: Model Distillation and Its Practical Gaps
- How KD works: teacher outputs encode class structure beyond hard labels via dark knowledge.
- Soft targets improve information efficiency compared to hard labels alone.
- Standard KD assumes: (1) full training data availability, (2) teacher accessibility at logit level.
- Gap 1: Data inaccessibility. legal restrictions, commercial sensitivity, regulatory requirements.
- Gap 2: Black-box APIs. restrict access to teacher internals, exposing only predictions.
- These gaps force practitioners into compromises: incomplete data, degraded signal.
- The need for KD variants that work under practical constraints.

## Section 1.3: Dataset Distillation and Its Practical Gaps
- How DD works: compress training data into a small dataset that retains the essential knowledge of the original.
- DD objective: minimize the performance gap between models trained on the distilled versus original datasets. Seminal work: gradient matching; later: trajectory/distribution matching.
- Gap 1: compressing data while retaining its information content—the smaller the distilled set, the higher the information burden on each sample.
- Gap 2: text modality (abundant data but underdeveloped DD methods). Unlike images, text distillation must select or generate discrete tokens while preserving semantic relationships
  - Obstacle 1: Discrete tokens resist interpolation. Text is discrete, missing a token is a complete loss, unlike continuous perturbations for images.
  - Obstacle 2: Non-local dependencies. Image distillation leverages spatial locality; text relationships span sentences or paragraphs, making local selection insufficient.
- Why these gaps intensify in text:
  - Discrete sparsity: missing rare tokens breaks knowledge entirely. Sample ranking alone (independent scoring) cannot capture dataset-level structure and may omit rare but critical linguistic patterns.
  - At extreme compression, each sample must carry more knowledge burden than any single sample in the original dataset.
- The need for a text DD method that efficiently preserves essential knowledge while maintaining auditability and interpretability.

## Section 1.4: Distributional Fidelity of the Training Signal
- Both model distillation (1.2) and data distillation (1.3) face a common challenge: ensuring the distilled representation—whether synthetic data, selected samples, or learned signals—adequately captures the complexity of what it replaces.
- This challenge manifests differently across modalities and objectives, but shares a root cause: **distributional fidelity**—whether the distilled distribution sufficiently spans the original's decision space and information content.
- Distributional fidelity is not just about coverage; it encompasses the full complexity of what makes a distribution "complete" for learning: rare examples, semantic relationships, information density, and the patterns models rely on.
- Why distributional fidelity matters: gaps in fidelity explain both KD failures (model doesn't see enough signal diversity) and DD failures (selected/synthetic data misses critical patterns).
- Distributional fidelity serves as the unifying design principle across this thesis: all three contributions aim to maximize fidelity under different constraints (few-shot, data-free, text modality).

## Section 1.5: Thesis Contributions
- This work addresses three distinct settings unified by a common principle: maximizing distributional fidelity under practical constraints.
- Contribution 1: DivBFKD tackles few-shot black-box image knowledge distillation—recovering diversity when data is scarce.
- Contribution 2: DIPKD addresses data-free black-box image knowledge distillation—maintaining fidelity without any original data.
- Contribution 3: TAKE introduces trajectory-aware knowledge estimation for text dataset distillation—preserving essential knowledge in discrete linguistic domains.
- All three contributions share a common objective: maximize the information content of the distilled representation under the constraints of their respective settings.

## Section 1.6: Thesis Structure
- Chapter 2 adopts a two-track structure reflecting the thesis's dual focus: image KD (Track A) and dataset distillation (Track B).
- Chapters 3 and 4 (Track A—image KD) progress from few-shot to data-free constraints, demonstrating how to maintain fidelity as data access diminishes.
- Chapter 5 (Track B—text DD) shifts to a different modality, showing how fidelity principles adapt to discrete, non-local linguistic structure.
- Chapter 6 synthesizes both tracks and discusses how distributional fidelity connects model and data compression at a deeper level.
- Readers may follow both tracks sequentially or prioritize by interest: Track A for black-box constraints, Track B for text-specific challenges.

---

# Chapter 2: Background
- The chapter establishes a two-track overview where distributional fidelity emerges as the unifying design criterion.

## Section 2.1: Deep Learning Foundations

### Subsection 2.1.1: Neural Networks and Supervised Learning
- Feedforward networks compose linear transformations and nonlinearities to learn mappings from inputs to outputs.
- Supervised learning minimizes cross-entropy loss between predictions and ground-truth labels.
- Generalization improves with scale (more data, larger models) and is bounded by overfitting risk and representation capacity.

### Subsection 2.1.2: Convolutional Neural Networks for Image Classification
- CNNs exploit spatial locality and weight sharing, reducing parameters while improving generalization.
- Standard CNN architectures (VGG, ResNet, DenseNet, EfficientNet) achieve state-of-the-art accuracy through increased depth and width.
- Vanishing gradients were addressed by skip connections, enabling training of very deep networks.
- Receptive field grows hierarchically, allowing early layers to capture low-level features and later layers to capture high-level semantics.
- The deployment-accuracy trade-off is fundamental: larger models achieve higher accuracy but incur higher computational cost.
- This tension motivates compression techniques, including knowledge distillation.

### Subsection 2.1.3: Language Models and Natural Language Understanding
- Transformer-based language models and BERT-scale models create computational bottlenecks for inference.
- Language model foundations are deferred to Section 2.6 for integration with dataset distillation.

## Section 2.2: Model Compression

### Subsection 2.2.1: The Compression Landscape
- Four families of compression techniques exist: pruning, quantization, low-rank factorization, and neural architecture search.
- Pruning removes weights or neurons; structured pruning removes entire filters or layers for hardware efficiency.
- Quantization reduces precision from floating-point to fixed-point or binary representations.
- Low-rank factorization decomposes weight matrices into products of lower-rank factors.
- Neural architecture search discovers efficient architectures at design time, prior to training.
- All four approaches require white-box access to the model; knowledge distillation uniquely does not.

### Subsection 2.2.2: Why Knowledge Distillation?
- Knowledge distillation occupies a distinct position in the compression landscape for three reasons.
- It is architecture-agnostic: students can have arbitrary architectures different from the teacher.
- It does not require teacher modification or access to internal weights.
- It provides a richer training signal than hard labels alone, capturing the teacher's class-relative confidences.
- Knowledge distillation interfaces only with the teacher's output; this simplicity is both a strength and a limitation.

## Section 2.3: Knowledge Distillation: Foundations

### Subsection 2.3.1: Seminal Work: Hinton et al. (2015)
- Hinton et al. introduced dark knowledge: the relational structure between classes learned implicitly by large neural networks.
- Temperature scaling controls the softness of the teacher's output, making the soft targets richer and the learning signal smoother.
- KD combines a hard-label loss with a soft-target loss, optimizing a weighted combination of the two objectives.
- Self-distillation confirms the value of soft targets: even a student matching the teacher architecture benefits from learning from soft targets.

### Subsection 2.3.2: Taxonomy of Knowledge Distillation Methods
- Knowledge distillation broadly divides into three families: logits-based, feature-based, and relation-based methods.
- Logits-based methods directly match soft target probabilities, minimizing cross-entropy between student and teacher outputs.
- Feature-based methods match intermediate representations, leveraging information from hidden layers.
- Feature-based methods are inapplicable in black-box settings because they require access to teacher internals.
- Relation-based methods preserve relations between samples, such as pairwise similarities or attention patterns.
- Relation-based methods exhibit a failure mode: they depend on batch composition, limiting their effectiveness with small batches.
- Table: [KD families overview]
- All standard KD methods share two assumptions: (1) full dataset availability and (2) teacher accessibility at the logit level.

### Subsection 2.3.3: Standard Assumptions and Their Limitations
- Knowledge distillation rests on two foundational assumptions regarding data and teacher access.
- Assumption 1: The full training dataset is available for distillation.
- Assumption 2: The teacher is accessible at the logit level (or higher).
- Failures of both assumptions define the practical KD landscape this thesis addresses.
- A note on scope: model compression and dataset compression are distinct problems, though this thesis addresses both.

## Section 2.4: Knowledge Distillation Under Restricted Access
- The problem space progresses from few-shot through black-box settings, each introducing new constraints.

### Subsection 2.4.1: Few-Shot Knowledge Distillation
- The few-shot setting assumes access to only a small number of training samples; label and architecture are known.
- Coverage deficit arises because the few samples do not adequately span the teacher's decision space.
- Standard augmentation (rotation, flipping, cropping) provides limited coverage extension.
- Generative augmentation methods (BBKD, FS-BBT) train generators to synthesize additional samples.
- Generators trained on few-shot data inherit the distributional limits of that data.
- Overcoming coverage deficit requires signals outside the few-shot support; this is the topic of Chapter 3.

### Subsection 2.4.2: Data-Free Knowledge Distillation: White-Box
- Model inversion is the primary strategy for data-free KD when the teacher is white-box.
- DAFL, DeepInversion, DFKD, and Meta-KD methods synthesize data by inverting the teacher's learned representations.
- All white-box data-free methods require access to teacher gradients or internal activations.
- Black-box constraints qualitatively change the problem.

### Subsection 2.4.3: Data-Free Knowledge Distillation: Black-Box
- The black-box data-free KD regime requires generating training data without access to teacher weights or gradients.
- ZSDB3 explores the decision boundary through decision boundary queries.
- IDEAL uses a student-proxy feedback mechanism to guide generation.
- DFHL-RS performs random search to discover informative samples.
- All existing black-box data-free KD methods exhibit two structural deficits: domain-coverage deficit and information-bottleneck deficit.
- Domain-coverage deficit: the generator cannot recover the teacher's input domain without explicit guidance.
- Information-bottleneck deficit: output-only queries limit the information available to refine generation.
- Addressing these deficits is the topic of Chapter 4.

## Section 2.5: Diversity and Quality Control in Synthetic Data
- Across both image KD (Sections 2.2–2.4) and dataset distillation (Sections 2.6–2.7), a common thread emerges: **distributional fidelity**—whether the distilled representation adequately captures the original's complexity in decision space and information content.
- This section introduces how distribution-matching failures manifest (mode collapse in synthetic data), how they are measured (diversity metrics), and how they are mitigated (active enforcement mechanisms).

### Subsection 2.5.1: Generative Adversarial Networks
- GANs formulate generation as a minimax game between a generator and discriminator.
- Early GANs suffered from vanishing gradients, making training unstable.
- Mode collapse occurs when the generator learns to produce only a few modes despite the diversity of real data.
- Wasserstein GANs (WGAN) and Wasserstein GANs with Gradient Penalty (WGAN-GP) improve stability.
- WGAN-GP reduces training instability but does not inherently address diversity in low-data regimes.

### Subsection 2.5.2: The Diversity Problem in Knowledge Distillation
- Mode collapse represents a distributional coverage failure: the generator collapses to a narrow subset of modes.
- A collapsed generator produces low-quality training signals, degrading student performance.
- Coverage emerges as a unifying concern across both image KD (Chapter 3, 4) and dataset distillation (Chapter 5) tracks.

### Subsection 2.5.3: Evaluation Metrics for Diversity and Generation Quality
- Standard metrics conflate fidelity (realistic images) and diversity (wide coverage).
- Inception Score (IS) combines image quality and diversity but is susceptible to mode collapse.
- Fréchet Inception Distance (FID) measures distributional similarity but does not explicitly reward coverage.
- Density and Coverage metrics directly measure mode collapse and coverage deficit.
- Downstream task accuracy is the primary evaluation criterion for this thesis.
- A diagnostic hierarchy of metrics is needed; active enforcement of coverage is required to prevent collapse.

### Subsection 2.5.4: Contrastive Learning as Diversity Enforcement
- Contrastive objectives enforce diversity through repulsion mechanisms: pulling similar samples together while pushing dissimilar ones apart in representational space.
- Key methods include SimCLR (NT-Xent loss), MoCo (memory queue), and Barlow Twins (redundancy reduction)—all operationalize this repulsion principle differently but share the goal of decorrelating representations.
- This regularization principle actively prevents mode collapse by penalizing redundancy between synthetic samples.
- Contrastive diversity mechanisms recur across both image KD (Chapters 3–4) and text DD (Chapter 5) as solutions to distributional coverage deficits.

## Section 2.6: Dataset Distillation

### Subsection 2.6.1: Language Models and NLP Foundations
- Language models face a corpus scale problem: pre-training on billions of tokens is computationally prohibitive.
- Tokenization converts text into discrete tokens; different tokenizers introduce systematic biases.
- Tokenization biases affect importance scoring for dataset distillation in text settings.
- Transformers scale effectively but introduce their own computational challenges for pre-training and fine-tuning.
- Fine-tuning on task-specific datasets is the dominant paradigm; dataset distillation can reduce this cost.
- BERT and related models rely on pre-training objectives (masked language modeling, next sentence prediction).
- Natural language inference (NLI) tasks require models to predict entailment, contradiction, or neutrality.
- NLI tasks are harder than text classification for dataset distillation due to their complexity and data requirements.
- Corpus scale motivates dataset distillation for language models.

### Subsection 2.6.2: Problem Definition
- The dataset distillation objective seeks a small distilled dataset whose loss trajectory matches the full dataset's trajectory.
- This is often relaxed to distribution matching, treating DD as an optimal transport problem.
- Three desiderata guide text DD: (1) handling discrete tokens, (2) avoiding hard-sample bias, (3) ensuring coverage of the original distribution.

### Subsection 2.6.3: Image Dataset Distillation
- Three optimization targets are used in image DD: gradient matching, trajectory matching, and distribution matching.
- Gradient matching (Datacomp, DC) directly aligns gradient trajectories of the student on distilled and full data.
- Trajectory matching (MTT) matches gradient traces across all training steps.
- Distribution matching (DM) treats DD as optimal transport, selecting prototypical samples from the full dataset.
- All three approaches are incompatible with discrete text tokens.

### Subsection 2.6.4: Text Dataset Distillation
- Text dataset distillation introduces orthogonal obstacles absent in image DD. Unlike images, text operates over discrete tokens with no interpolation, and semantic relationships span non-local dependencies (sentences, paragraphs). These constraints invalidate the gradient matching, trajectory matching, and distribution matching approaches developed for continuous image data (Section 2.6.3).
- Two prior families of text DD methods exist: soft-embedding methods and clustering-based methods.
- Soft-embedding approaches apply image DD directly in embedding space, abstracting away tokenization.
- Soft-embedding methods suffer from a fidelity gap: continuous embeddings do not correspond to real tokens.
- Clustering-based methods (DaLLME) select samples greedily using clustering; they ignore sample importance.
- Large language models offer an alternative: generate synthetic examples directly via LLM-based generation.
- Generation alone is insufficient: the generated pool may not cover the original data distribution.
- Residual problem 1: Hard-sample bias causes importance to concentrate on outliers, degrading student performance on the core distribution.
- Residual problem 2: Coverage gap arises when the generation model cannot produce sufficient diversity relative to the original corpus.

## Section 2.7: Sample Importance and Distributional Selection

### Subsection 2.7.1: Influence Functions and Hard-Sample Bias
- Classical influence functions estimate how individual samples affect the learned model parameters.
- Computing influence functions exactly is intractable due to the cost of Hessian computation.
- Tractable proxies (TracIn, TRAK, gradient norm) approximate influence without explicit Hessian inversion.
- Gradient norm is a simple proxy: samples with large gradient norms are treated as influential.
- Hard-sample bias occurs at convergence: the gradient norm concentrates on difficult samples rather than representative ones.
- Dataset cartography provides empirical evidence that importance metrics suffer from hard-sample bias.
- Integrating importance scores along the training trajectory can correct this bias.

### Subsection 2.7.2: Optimal Transport and Distributional Coverage
- Wasserstein distance measures the cost of optimally transporting one distribution to another.
- The discrete optimal transport problem for dataset distillation seeks a subset that minimizes transport cost.
- The Sinkhorn algorithm makes discrete OT tractable via entropic regularization.
- Optimal transport outperforms greedy and clustering approaches because it considers global distributional structure.
- A toy example illustrates the advantages of OT over greedy and clustering methods.
- k-means clustering on the toy example produces well-separated clusters but ignores importance weighting.
- k-centre selection produces the most representative prototypes but only up to centroid distance.
- Optimal transport on the same example recovers importance-weighted prototypes that balance diversity and importance.
- Optimal transport's advantage is importance-weighted, not geometric: it respects the original distribution's structure.
- Optimal transport is composed into the TAKE pipeline (Chapter 5).

## Section 2.8: Summary and Research Gaps
- This chapter established foundations across two tracks: image knowledge distillation (Track A) and dataset distillation (Track B).
- Track A progresses from standard KD through few-shot KD (Chapter 3) to data-free KD (Chapter 4).
- Track B covers dataset distillation methods and identifies limitations in text DD (Chapter 5).
- Distributional fidelity emerges as the unifying thread across all three contributions.
- Indirect penalisation of coverage (rather than explicit coverage metrics) is the thesis's core advance.
- Table: [Research gaps identified in background]
- Three research gaps define the contributions of Chapters 3, 4, and 5.
- Gap 1: Few-shot KD requires better coverage with limited data; this is DIVBFKD's focus.
- Gap 2: Data-free black-box KD requires dual coverage (domain + information) solutions; this is DIPKD's focus.
- Gap 3: Text DD requires bias correction and coverage-aware selection; this is TAKE's focus.

---

# Chapter 3: DivBFKD: Diversity in Black-box Few-shot Knowledge Distillation

## Section 3.1: Introduction
- Modern deep learning deployment faces a compression gap between model size and available compute.
- Knowledge distillation is the primary approach for compressing neural networks.
- The few-shot setting is practical when unlabeled data is available but labeled data is scarce.
- Black-box teacher constraints impose further difficulty: the student learns only from teacher outputs.
- Prior few-shot black-box KD methods (BBKD, FS-BBT) suffer from mode collapse in the generated distribution.
- This work proposes DivBFKD: a WGAN-based method that trains on high-confidence synthetic images to improve diversity.
- DivBFKD contributes: (1) adaptive high-confidence thresholding, (2) WGAN training with high-confidence filtering, (3) extensive ablations on diversity mechanisms, (4) cross-architecture distillation results.

## Section 3.2: Related Works
- Knowledge distillation broadly encompasses logits-based, feature-based, and relation-based approaches.
- Few-shot KD methods include FSKD, WaGe, BBKD, and FS-BBT; all address coverage deficit in limited-data settings.
- Data-free KD includes both white-box methods (requiring gradients) and black-box methods (output-only access).
- GANs have been used in KD before, but prior work uses GANs to augment, not to enforce diversity.

## Section 3.3: The Proposed Framework

### Subsection 3.3.1: Problem Statement
- Given a few labeled samples and a black-box teacher, train a student to match the teacher's predictions.
- Standard KD loss: weighted combination of soft cross-entropy (teacher predictions) and hard cross-entropy (ground-truth labels).

### Subsection 3.3.2: Proposed Method
- DivBFKD operates in two phases: generation and distillation.
- Generation phase: Train a WGAN to synthesize images that maximize teacher confidence.
- High-confidence images are those where the teacher's maximum logit exceeds a threshold.
- Adaptive thresholds are computed per-class to balance coverage across classes.
- Adaptive threshold computation: set per-class thresholds as the q-quantile of teacher confidence on the few-shot set.
- WGAN training uses the Wasserstein loss with gradient penalty, filtering training data to only high-confidence images.
- Updated discriminator loss: classify only high-confidence generator outputs as real, rejecting low-confidence outputs.
- High-confidence filtering creates a positive feedback loop: early good generator outputs receive positive feedback, improving training efficiency.
- DivBFKD's novelty lies in combining diversity (WGAN) with selective feedback (high-confidence filtering).
- Distillation phase: Construct a set of high-confidence synthetic images for student training.
- Student training loss: standard KD loss weighted by ground truth and soft targets.
- Class balancing: use rejection sampling to ensure balanced class representation in the distillation set.

## Section 3.4: Experiments

### Subsection 3.4.1: Architectures and Datasets
- Seven benchmark datasets span toy problems (MNIST), simple datasets (CIFAR10), complex benchmarks (CIFAR100, Tiny-ImageNet), and high-resolution data (Imagenette).
- Network architectures include standard CNNs (LeNet), modern efficient networks (MobileNetV2), and large networks (ResNet50).

### Subsection 3.4.2: Baselines
- Baselines include: (1) Student-Full (upper bound: full dataset), (2) Standard-KD (full-dataset KD), (3) few-shot methods (BBKD, FS-BBT).
- Experimental protocol: Report top-1 accuracy with standard deviation across 5 runs.

### Subsection 3.4.3: Distillation Performance
- Simple datasets (MNIST, CIFAR10): DivBFKD achieves 95%+ accuracy, approaching full-dataset performance.
- CIFAR100 and Tiny-ImageNet: DivBFKD reduces the gap to full-dataset KD; improvements over BBKD and FS-BBT are 2–5%.
- Imagenette (high-resolution): DivBFKD maintains advantage, showing applicability beyond toy benchmarks.
- Cross-architecture distillation: Student and teacher with different architectures benefit from DivBFKD, showing architecture-agnosticism.

### Subsection 3.4.4: Diversity of Synthetic Images
- Embedding visualization (CIFAR10): DivBFKD-generated images spread across the teacher's representation space; baselines cluster in a few modes.
- Coverage metric (quantitative): DivBFKD achieves 40–60% coverage; baselines achieve 10–30%.
- Visual inspection: DivBFKD synthetic images appear more varied; baselines show repetitive patterns.
- Inception Score (IS) and Fréchet Inception Distance (FID): DivBFKD scores improve on diversity metrics.

### Subsection 3.4.5: Ablation Studies
- Adaptive thresholds and class balancing each contribute 2–3% to overall performance.
- Performance vs. data counts: Student accuracy improves with more real samples (N) and synthetic samples (M); a 2:1 ratio of synthetic to real is optimal.
- Stable range: Quantile q ranges from 0.03 to 0.10 without significant performance degradation.

### Subsection 3.4.6: Comparison with Data-Free KD Methods
- DivBFKD outperforms zero-shot data-free KD methods on equivalent benchmarks, confirming few-shot setting advantage.

## Section 3.5: Conclusion
- DivBFKD achieves strong few-shot black-box KD through adaptive high-confidence filtering of synthetic images.
- Future work includes robustness to adversarial perturbations and extension to video data.

---

# Chapter 4: DIPKD: Diverse Image Priors for Black-box Data-free Knowledge Distillation

## Section 4.1: Introduction
- Large model deployment is constrained by inference cost, motivating compression for edge and real-time applications.
- The black-box data-free knowledge distillation problem requires generating training data without teacher weights or original data.
- Two bottlenecks impede prior methods: domain-coverage deficit (generator cannot reconstruct input distribution) and information-bottleneck deficit (output-only queries limit refinement signals).
- DIPKD proposes a three-phase pipeline: Synthesis (multi-scale noise + augmentation), Contrast (contrastive diversity), and Distillation (hard + soft KD).
- DIPKD contributes: (1) diagnosis of dual bottlenecks, (2) multi-scale synthesis method, (3) contrastive diversity enforcement.

## Section 4.2: Related Works

### Subsection 4.2.1: Foundations of Knowledge Transfer
- Knowledge distillation training and white-box assumptions.

### Subsection 4.2.2: Constraints in Data Availability
- Few-shot and proxy dataset approaches address data scarcity.

### Subsection 4.2.3: Navigating Restricted Expert Interfaces
- ZSDB3 uses decision-boundary exploration.
- IDEAL and DFHL-RS use generator-based synthesis with inherent limitations.

## Section 4.3: Proposed Framework

### Subsection 4.3.1: Problem Setup
- Formal problem statement: given black-box teacher oracle, generate student training data.
- Naive baseline: independently query teacher and train student; poor performance due to domain-coverage deficit.
- DIPKD three-phase overview: iteratively Synthesize domain coverage, enforce Contrast for diversity, and perform Distillation for learning.

### Subsection 4.3.2: Synthesis: Reconstructing the Knowledge Domain
- Multi-scale noise hierarchy: coarse noise provides domain structure; fine noise provides detail.
- Motivation: domain coverage requires both macro structure and local detail.
- Multi-scale sampling and mixing: combine noise at multiple Gaussian scales.
- Rotation, elastic, and cropping transforms: apply realistic augmentations to increase apparent diversity.
- Motivation for geometric augmentations: rectangular CutMix loses semantic information; soft augmentations preserve structure.
- Diverging filter and semantic mask design: weight augmented regions by importance to preserve teacher-relevant features.
- Final image priors construction: combine multi-scale noise, augmentations, and masking into synthetic image candidates.

### Subsection 4.3.3: Contrast: Collaborative Diversity Optimization
- Primer student: a white-box mediator that guides generation by providing embeddings.
- Cosine similarity between embeddings: measure representational similarity of synthetic candidates.
- Contrastive loss: push similar synthetic samples apart and dissimilar samples together, enforcing diversity.

### Subsection 4.3.4: Distillation: Restoring Informative Signals
- Combined hard and soft KD objective: match hard labels from the teacher and soft targets for smooth learning.

## Section 4.4: Experiments

### Subsection 4.4.1: Experimental Setup
- Twelve benchmarks and three CNN architectures (ResNet50, EfficientNet, MobileNetV2).

### Subsection 4.4.2: Baselines
- NaiveKD baseline and three state-of-the-art black-box data-free KD methods (ZSDB3, IDEAL, DFHL-RS).

### Subsection 4.4.3: Standard Experiments
- Simple benchmarks (MNIST, CIFAR10): near-perfect performance; DIPKD matches full-dataset KD within 1%.
- Complex benchmarks (CIFAR100, ImageNet subset): performance gap widens; DIPKD reduces gap to 3–5%.
- Domain-specific benchmarks (medical, satellite imagery): DIPKD shows robust advantage, 5–10% improvement over baselines.
- Low standard error demonstrates robustness of the three-phase pipeline.

### Subsection 4.4.4: Ablation Studies
- Sequential component additions reveal Synthesis is the dominant contributor.
- Minimum quorum (minimum samples for contrastive loss) scales with dataset complexity.
- UMAP visualization and distribution metrics (Coverage, Density): Synthesis phase expands domain coverage; downstream metrics improve.
- Image priors overlap real image regions in both pixel and embedding space.
- Contrast phase further expands coverage and improves recall on rare classes.
- Teacher-student architecture matching improves performance; mismatch introduces 2–3% degradation.
- Robustness: DIPKD degrades gracefully from 4% compression ratio; failure at 1% CR indicates information-theoretic limit.

## Section 4.5: Conclusion
- Data diversity is the key factor determining student performance in data-free KD.
- DIPKD achieves this through complementary synthesis (coverage) and contrast (diversity) mechanisms.

---

# Chapter 5: TAKE: Trajectory-Aware Knowledge Estimation for Text Dataset Distillation

## Section 5.1: Introduction
- Corpus scale is a binding constraint for large language model pre-training and fine-tuning.
- Dataset distillation seeks to reduce this cost by identifying the most informative subset.
- Text dataset distillation differs from images: tokens are discrete, importance biases exist, and distribution mismatch is harmful.
- Three properties distinguish a complete text DD method: (1) discrete token compatibility, (2) bias-corrected importance, (3) coverage-aware selection.
- TAKE is the first method to satisfy all three; its contributions are: diagnosis of hard-sample bias, trajectory-aware methodology, and empirical validation.

## Section 5.2: Related Work

### Subsection 5.2.1: Text Dataset Distillation
- Three criteria define a complete text DD method: discrete token compatibility, bias-corrected importance, and coverage-aware selection.
- Table: Comparison of prior text DD methods against these criteria.
- TAKE is the first method to satisfy all three criteria simultaneously.

### Subsection 5.2.2: Influence Functions and the Hard-Sample Bias
- Influence functions estimate sample importance by gradient-based approximation.
- Hard-sample bias has been documented empirically in prior work on sample importance.

### Subsection 5.2.3: Optimal Transport for Distribution Matching
- Distribution matching provides a surrogate objective for DD when exact gradient matching is impossible.
- MMD and KL divergence are standard surrogates but lack importance weighting; discrete OT fills both gaps for NLP.

## Section 5.3: Theoretical Framework

### Subsection 5.3.1: Reweighted Distribution Matching for Dataset Distillation
- Dataset distillation objective: find a small set whose loss trajectory matches the full set's trajectory.
- Relaxation: distribution matching is a surrogate when trajectory matching is intractable.
- Reweighted Distribution Matching (RDM): formulate DD as weighted distribution matching, respecting sample importance.

### Subsection 5.3.2: Two Failures of the Naive Pipeline
- Influence self-score: importance of sample i is approximated as the squared gradient norm at convergence.
- Proposition 1 (Hard-Sample Bias): independent scoring at convergence concentrates importance on outliers rather than representative samples.
- Remark: independent scoring does not equal coverage; importance alone is insufficient.
- Two open problems: (1) How to correct hard-sample bias? (2) How to balance importance with coverage?

## Section 5.4: Methodology

### Subsection 5.4.1: Problem Setup and Framework Overview
- TAKE operates in three stages: Score (compute trajectory-aware importance), Generate (synthesize candidate pool), Select (choose prototypes via OT).
- Pipeline stages are decoupled: each can be improved independently.

### Subsection 5.4.2: Gradient-Based Influence Along the Trajectory
- Trajectory-aware estimation corrects hard-sample bias by integrating importance over training steps, not just at convergence.
- Influence Matrix: gradient norm proxy computed at each step; Goodfellow trick accelerates computation; logistic probe extracts importance.
- Knowledge Score: reciprocal of influence amplifies important samples; exponential kernel weights recent steps; onset of memorization marks critical importance.
- Proposition 2: trajectory integration reduces hard-sample bias compared to convergence-only scoring.

### Subsection 5.4.3: Synthetic Candidate Pool Generation
- Motivation: direct sampling from the full dataset introduces coverage bias; synthesis allows controlled exploration.
- Distribution mismatch is beneficial when the pool is larger than the distilled set and covers the original distribution.
- Pool coverage assumption: assume the pool covers the original distribution sufficiently.

### Subsection 5.4.4: Distributional Prototype Selection via Discrete Optimal Transport
- Discrete OT formulation: select prototypes that minimize weighted transport cost from full data.
- Entropic regularization: make the problem tractable via Sinkhorn algorithm.
- Theorem 1: distribution matching gap bound quantifies how well selected prototypes approximate the full distribution.

## Section 5.5: Experiments

### Subsection 5.5.1: Setup
- Five datasets (AG News, IMDb, SST-2, MNLI-m, QQP) and two backbone families (DistilBERT, ALBERT).
- Baselines and evaluation: compare to clustering-based (k-means), generation-based (DiLM), and oracle (full data) methods.
- Implementation details: gradient computation, pool generation, Sinkhorn parameters.

### Subsection 5.5.2: Classification
- Table: Classification accuracy on AG News, IMDb, SST-2 with TAKE, DiLM, baselines, and oracle.
- TAKE achieves 85–92% of oracle accuracy across datasets, outperforming clustering and generation baselines by 3–8%.
- Backbone-agnostic advantage: TAKE works with DistilBERT and ALBERT without retuning.
- Stability: TAKE's standard deviation is 2–3× lower than baselines, indicating correct bias correction.
- SST-2 comparison: TAKE outperforms DiLM (prior state-of-the-art) by 2–4%, showing trajectory-aware advantage.

### Subsection 5.5.3: Natural Language Inference
- Table: NLI accuracy on MNLI-m and QQP with TAKE, DiLM, baselines, and oracle.
- NLI gains are consistent with classification; TAKE achieves 80–88% of oracle accuracy.
- NLI complexity: ceiling gap (oracle - TAKE) is larger for NLI than classification, indicating harder problem.
- Pool generation as bottleneck: improved generation methods may close the ceiling gap.
- Stability comparison: TAKE stability advantage over DiLM persists, confirming bias correction.

## Section 5.6: Limitations and Ethical Considerations
- Technical limitations: gradient norm proxy depends on encoder choice; synthetic pool coverage is an assumption, not guaranteed.
- Ethical considerations: bias propagation (biases in full data appear in distilled data); privacy risk from LLM memorization of rare samples.

## Section 5.7: Conclusion
- Hard-sample bias was identified and corrected through trajectory-aware scoring.
- TAKE provides end-to-end guarantees: discrete token compatibility, bias-corrected importance, coverage-aware selection.
- Practical implications: TAKE reduces fine-tuning costs for language models on new tasks.

---

# Chapter 6: Conclusion

## Section 6.1: Summary of Contributions
- (No body text — section heading only)

## Section 6.2: Limitations and Future Directions
- (No body text — section heading only)
