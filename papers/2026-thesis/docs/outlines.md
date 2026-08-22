# Thesis Outline: Knowledge Distillation under Practical Constraints for Models and Datasets

<!--
Legends:
- Untick = not drafted/stale
- [d] = drafted
- [r] = manually reviewed (done)
-->

# Abstract

- [r] KD as knowledge transfer: model distillation, dataset distillation compress knowledge, not reduction.
- [r] Real-world constraints: limited/unavailable data, black-box access, underdeveloped text dataset distillation.
- [r] Three contributions: DivBFKD, DIPKD, TAKE.

# Chapter 1: Introduction

## Section 1.1: Large-Scale Models and Knowledge Distillation

- [r] Deep learning's history: models and data scale as the dominant trend (bitter lesson).
- [r] The deployment gap: scaling requirements bottlenecked by real-world constraints.
- [r] The constraints that motivates model compression: KD stands out by transferring knowledge from teacher to student.
- [r] The constraints that motivates dataset compression: DD stands out by optimising a synthetic set end-to-end rather selecting representative samples.
- [r] Wrap-up: KD and DD both treat compression as knowledge transfer, acknowledging fidelity, not just size.

## Section 1.2: Model Distillation and Practical Gaps

- [r] Model compression families; KD unique: learning problem, no weight access, architecture-agnostic.
- [r] Dark knowledge via soft targets; KL divergence + cross-entropy; requires full data, white-box access.
- [r] Data inaccessibility: legal, commercial, cost barriers; few-shot to data-free spectrum.
- [r] Black-box withholds soft logits; deliberate security; student loses dark knowledge.
- [r] Incomplete data narrows coverage; black-box degrades quality; reshapes signal statistics.

## Section 1.3: Dataset Distillation and Practical Gaps

- [r] Data compression families: prototypes, coreset selection, dataset distillation.
- [r] DD compresses training data preserving essential knowledge.
- [r] DD objective: minimize performance gap; gradient → trajectory → distribution matching.
- [r] Gap 1: Text tokens discrete (resist interpolation); gradient matching incompatible.
- [r] Gap 2: Compression burden intensifies; rare tokens absent, independent scoring fails.
- [r] Require: discrete tokens, distributional coverage, human-readable output.

## Section 1.4: Distributional Fidelity of the Training Signal

- [r] Distributional fidelity: coverage gaps in training signal correspond to gaps in student's knowledge domain.
- [r] Few-shot: synthesis diversity is binding; data-free: image priors seed coverage without real-data anchor.
- [r] Black-box spectrum: truncated probabilities to hard integer label; challenge is recovering soft-label knowledge.
- [r] Dataset distillation: synthetic samples raise fidelity ceiling; needs knowledge estimation, global optimization.
- [r] Unified problem: coverage deficit in KD and selection failures in DD both reflect fidelity deficit.
- [r] Design commitment: fidelity as first-class objective, not collateral outcome of reasonable methods.

## Section 1.5: Thesis Contributions

- [r] Three settings: few-shot image KD, data-free image KD, text dataset distillation, unified by fidelity.
- [r] DivBFKD: generation + adaptive confidence thresholds to filter for quality under few-shot constraints.
- [r] DIPKD: synthesis + contrastive contrast + primer distillation to enforce diversity under data-free constraints.
- [r] TAKE: influence-based scoring + discrete OT selection to identify high-value samples under compression constraints.
- [r] Coverage and quality are explicit design objectives, not implicit; mechanisms match information scarcity.

## Section 1.6: Thesis Structure

- [r] Two tracks unified by distributional fidelity: Model Track (image KD) and Dataset Track (text).
- [r] Chapter 2 forks into strands; Chapters 3--5 develop each; Chapter 6 synthesizes.

---

# Chapter 2: Background

- [d] The chapter establishes a two-track overview where distributional fidelity emerges as the unifying design criterion.
- [d] [short] Model Track (Model Distillation).
- [d] [short] Dataset Track (Dataset Distillation).
- [d] [short] Unifying Principle (distributional fidelity).

## Section 2.1: Deep Learning Foundations

### Subsection 2.1.1: Neural Networks and Supervised Learning

- [d] Layers compose affine maps and nonlinearities (ReLU); deep stacks build abstract representations.
- [d] Supervised learning minimises cross-entropy via backpropagation and SGD/Adam.
- [d] Accuracy requires scaling capacity and data together; large models are costly to deploy.

### Subsection 2.1.2: Convolutional Neural Networks for Image Classification

- [d] CNN basics: translation equivariance, local connectivity; pooling builds semantic hierarchy.
- [d] Receptive field grows geometrically via pooling; integrates local texture to global layout.
- [d] LeNet5: proof of concept, seven layers, 60K parameters; established convolutional template.
- [d] Vanishing gradients limit depth; LeNet→AlexNet→VGG pushed boundaries but training fragile.
- [d] Skip connections (ResNet) solve gradient flow; enable training of 152+ layer networks.
- [d] Architectural progression: LeNet (60K) → AlexNet (60M) → VGG → ResNet; standard KD teachers.
- [d] Accuracy scales with depth/width but cost grows faster; motivates model compression.

### Subsection 2.1.3: Foundational Natural Language Processing

- [d] NLP arc: rules → statistical features → neural representations, mirroring vision.
- [d] Symbolic NLP: interpretable but brittle; cannot scale beyond manually encoded knowledge.
- [d] Statistical NLP (n-grams, HMMs, CRFs): data-driven but sparse, task-specific representations.
- [d] Neural NLP: Word2Vec/GloVe embeddings; LSTM/Seq2Seq limited by fixed-length bottleneck.
- [d] Subword tokenisation (BPE, WordPiece) shapes token-level statistics used in Chapter 5.

### Subsection 2.1.4: The Transformer Era

- [d] Self-attention replaced recurrence: fully parallel, eliminates vanishing-gradient-over-distance.
- [d] Pre-training then fine-tuning unified the field; BERT (encoder), GPT (decoder), T5 (enc-dec).
- [d] Downstream tasks: classification, QA, NLI; Chapter 5 uses encoder-only models on NLI.
- [d] Scaling laws: loss decreases smoothly; emergent abilities arise at scale; costs necessitate distillation.

## Section 2.2: From Compression to Distillation

### Subsection 2.2.1: Model Compression

- [d] Four families: pruning, quantisation, low-rank factorisation, KD; access requirements differ.
- [d] Pruning removes weights/filters; requires internal weights, produces sparse or dense sub-networks.
- [d] Quantisation lowers numerical precision; requires activation statistics and weight access.
- [d] Low-rank factorisation decomposes weight matrices; best for large FC/embedding layers.
- [d] KD trains student from teacher outputs alone; no weight access required.
- [d] Pruning/quantisation/factorisation all require internal access; black-box leaves KD as only option.

### Subsection 2.2.2: Dataset Compression

- [d] Dataset compression reduces training data volume; three families differ in approach and representativeness.
- [d] Prototype/clustering methods summarise by centroids; fast but ignore learning objective.
- [d] Coreset selection retains real samples grounded in learning objective; bounded by existing data.
- [d] Dataset distillation optimises synthetic samples end-to-end; unconstrained by original data support.
- [d] Three families differ in preservation: prototypes (geometry), coreset (loss), DD (behaviour); only DD extends coverage.

### Subsection 2.2.3: Why Distillation?

- [d] KD is umbrella for model and dataset distillation; both compress via knowledge transfer.
- [d] Model distillation: architecture-agnostic, no internal access, preserves dark knowledge over hard labels.
- [d] Dataset distillation: not bounded by original data; preserves model behaviour over surface proxies.
- [d] Shared principle: compression as knowledge transfer; shared failure mode is distributional fidelity.

## Section 2.3: Model Distillation

### Subsection 2.3.1: The Original Formulation

- [d] Setup: KD transfers decision-boundary structure, not pointwise fidelity.
- [d] Dark knowledge: one-hot labels discard inter-class structure in soft output.
- [d] Formulation: KL divergence on outputs; temperature scaling amplifies visibility; combined soft + hard loss.
- [d] Empirical validation: same-arch student beats hard labels (signal quality > capacity).

### Subsection 2.3.2: Taxonomy of Model Distillation Methods

- [d] Design space: knowledge source (response/feature/relation) × training scheme (offline/online/self/co).
- [d] Response-based: output distribution matching; output-only access, black-box compatible.
- [d] Feature-based: intermediate reps via projector (FitNets, AT, PKT); requires internal activations; API incompatibility structural.
- [d] Relation-based: pairwise structure preservation; requires intermediate access; batch dependence and geometry mismatch problems.
- [d] Training schemes: offline (frozen teacher), online (jointly trained), self, co-distillation.
- [d] All three assume offline teacher, full dataset, logit-level access; response-based sole advantage when either fails.

### Subsection 2.3.3: Standard Assumptions and Their Limitations

- [d] Assumption 1: full dataset available; in practice restricted (GDPR, proprietary) or unavailable (few-shot to data-free).
- [d] Assumption 2: teacher logit-level accessible; black-box APIs return only top-1; eliminates feature/relation; response-based sole option.
- [d] Together: absent data loses coverage; absent soft targets loses relational structure; motivates restricted-access treatment.

## Section 2.4: Model Distillation Under Restricted Access

- [d] Two dimensions of restriction: teacher access (white-box → black-box) and data availability (full → few-shot → data-free).

### Subsection 2.4.1: White-Box Model Distillation

- [d] §2.3 baseline; surveys progressive data reduction while white-box access remains intact.
- [d] Few-shot: standard augmentation extends coverage; rich soft supervision partially compensates.
- [d] Proxy/in-the-wild data: soft targets preserved but domain mismatch biases the student's distribution.
- [d] Data-free model inversion (DAFL, DeepInversion): requires gradients and BatchNorm statistics; white-box only.
- [d] Removing white-box access: collapses design space to hard-label response-based distillation only.

### Subsection 2.4.2: Black-Box Model Distillation: Few-Shot

- [d] Black-box full-data: manageable; signal quality is the residual constraint.
- [d] Few-shot: hard labels + sparse data create double bind; neither compensates for other.
- [d] Coverage degradation: few-shot queries cover only a few modes; student gets a biased, narrow view.
- [d] Standard augmentation (MixUp, CutMix): increases count but stays within the few-shot support.
- [d] Generative augmentation (BBKD, FS-BBT): extends coverage but inherits the few-shot distributional limits.
- [d] Loop argument: both approaches stay inside the few-shot information horizon; external signal required.
- [d] Open problem: signal outside the few-shot support needed to anchor synthesis; Chapter 3.

### Subsection 2.4.3: Black-Box Model Distillation: Data-Free

- [d] Strictest setting: no real data, no teacher internals, hard labels only.
- [d] ZSDB3: decision-boundary random walk; limited by high-dimensional sparsity and off-manifold images.
- [d] IDEAL: student-proxy feedback; end-to-end but tied to student failure modes, causing mode collapse.
- [d] DFHL-RS: random search added to IDEAL; partially counteracts collapse, retains hard-label bottleneck.
- [d] Two shared structural deficits: domain-coverage deficit and information-bottleneck deficit.
- [d] Domain-coverage deficit: generator gravitates to prior-favoured modes; long-tail regions uncovered.
- [d] Information-bottleneck deficit: hard label discards inter-class relational structure; within-class geometry lost.
- [d] Addressing both deficits simultaneously is the topic of Chapter 4.

## Section 2.5: Distributional Fidelity and Synthetic Data

- [d] Three contributions, three restricted-access settings; training signal insufficient for direct high-fidelity distillation.

### Subsection 2.5.1: The Fidelity Deficit

- [d] Restricted access reduces distributional coverage, not just signal quantity; absent knowledge is unrecoverable.
- [d] Coverage is the binding constraint: student accuracy bounded by fraction of teacher distribution covered.
- [d] Three instantiations: few-shot leaves regions unsampled; data-free has no anchor; oversized corpus misfires on outliers.
- [d] Unified treatment required: synthetic data must be enforced on coverage, not just per-example fidelity.

### Subsection 2.5.2: Generation Mechanisms

- [d] Image and text synthesis differ in mechanism but share a common embedding-space evaluation ground.
- [d] Images: WGAN-GP replaces Jensen-Shannon with Wasserstein-1; stable training and better mode coverage.
- [d] Text: LLM fine-tuning generates fluent candidates; fine-tuning improves alignment but may oversample frequent patterns.
- [d] Shared embedding space: common ground for coverage metrics, UMAP diagnostics, and diversity enforcement.

### Subsection 2.5.3: Diagnosing Coverage Failures

- [d] FID/IS aggregate fidelity and diversity; low FID is compatible with severe mode collapse.
- [d] Density and Coverage decompose them: Density measures per-sample fidelity; Coverage measures distributional recall.
- [d] Key insight: low FID does not imply high Coverage; Coverage is an independent objective.

### Subsection 2.5.4: Active Fidelity Recovery

- [d] Each setting requires active mechanism matched to its specific constraints and affordances.
- [d] Few-shot: adaptive confidence filtering expands beyond support via teacher-guided rejection sampling.
- [d] Data-free: multi-scale noise + contrastive loss enforces diversity before teacher queries.
- [d] Text: trajectory-aware scoring + discrete OT enforces importance-weighted distributional coverage.
- [d] Unifying pattern: name deficit → understand cause → apply upstream mechanism → verify Coverage.
- [d] Data compression: same fidelity principle applies; actively enforced throughout, not post-hoc.

## Section 2.6: Dataset Distillation

### Subsection 2.6.1: Problem Definition

- [d] Compress dataset: small surrogate matches full-dataset training performance on held-out test set.
- [d] Intractable objective relaxed: distribution-matching minimises divergence in task-relevant feature space.
- [d] DD vs MD complementary: DD compresses data, MD compresses model; both require distributional fidelity.
- [d] Complete text DD requires: knowledge-informed weighting, distributional coverage, human-readable output.

### Subsection 2.6.2: Image Dataset Distillation

- [d] Gradient matching (DC): optimise synthetic images to match per-step gradients; unnatural but effective.
- [d] Trajectory matching (MTT): match full training trajectories across checkpoints; improves performance.
- [d] Distribution matching (DM): align feature-space distributions via random feature maps; computationally scalable.
- [d] All three incompatible with text: discrete tokens, undefined gradients, soft sequences not readable.

### Subsection 2.6.3: Text Dataset Distillation

- [d] Text requires different approach: discrete tokens, non-local dependencies, semantic coherence constraint.
- [d] Soft-embedding methods (SLDD): architecture-locked embeddings, unreadable; unsuitable for deployment/auditing.
- [d] Clustering methods (DaLLME): fast and readable, but uniform cluster weighting; miss hard examples.
- [d] LLM-based generation (DiLM): fluent and private, but faces selection problems with importance bias.

## Section 2.7: Sample Importance and Distributional Selection

- [d] Two binding constraints from §2.6.3: knowledge-informed weighting (1) and distributional coverage (2).

### Subsection 2.7.1: Influence Functions and Hard-Sample Bias

- [d] Influence functions quantify counterfactual effect of removing each example on learned parameters.
- [d] Exact computation intractable; approximations: TracIn integrates gradients, TRAK projects low-rank, gradient norm simplest.
- [d] Test-conditioned methods adapted via self-influence for corpus-level scoring; evaluation at convergence.
- [d] Hard-sample bias: single-checkpoint gradients conflate hard-to-fit outliers with representative well-fit examples.
- [d] Empirical evidence: dataset cartography and co-teaching confirm late-stage bias toward noisy examples.
- [d] Trajectory integration: average importance across training stages; dilutes noise, produces calibrated scores.
- [d] Corrected weights necessary but insufficient: accurate per-sample scores alone cannot enforce distributional coverage.

### Subsection 2.7.2: Optimal Transport and Distributional Coverage

- [d] Select compact subset minimizing importance-weighted divergence from source distribution.
- [d] Ranking fails: ignores redundancy and relationships; Wasserstein distance remains valid under disjoint supports.
- [d] Discrete OT formulation: transport plan moves importance mass from source to candidate pool at minimum cost.
- [d] Sinkhorn algorithm: entropic regularisation enables tractable computation via alternating normalisation.
- [d] k-means clustering: geometric coverage misleads; allocates capacity to low-importance regions.
- [d] k-centre selection: selects geometric extremes; same failure as k-means when geometry decouples from importance.
- [d] Optimal transport: importance-weighted allocation; concentrates capacity on regions that matter most.

## Section 2.8: Summary and Research Gaps

- [d] Chapter builds foundation along two tracks: Model Track (§2.3–2.5) and Dataset Track (§2.6–2.7).
- [d] Model Track: KD framework, restricted-access settings, distributional coverage as binding constraint.
- [d] Dataset Track: text DD objective, image method limitations, importance scoring and OT tools.
- [d] Unifying thread: compact artefact must cover source distribution; coverage failures share a root cause.
- [d] Three open problems, one per contribution; each is a specific fidelity deficit instance.
- [d] Gap 1 (Ch. 3): few-shot BB KD; synthetic diversity insufficient to escape few-shot support.
- [d] Gap 2 (Ch. 4): data-free BB KD; domain coverage and information bottleneck both unresolved.
- [d] Gap 3 (Ch. 5): text DD; importance scoring and coverage both unresolved; three properties never jointly satisfied.
- [d] Chapters 3–5 address each gap, operationalising distributional fidelity under its specific constraint.

---

# Chapter 3: DivBFKD: Diversity in Black-box Few-shot Knowledge Distillation

## Section 3.1: Introduction

- [r] Few-shot distillation harder than standard KD which requires extensive data.
- [r] Real-world teachers are black-box APIs; white-box access unavailable in practice.
- [r] Prior few-shot methods (MixUp, CVAE) lack diversity or introduce artifacts.
- [r] DivBFKD: WGAN with high-confidence filtering for diverse synthetic image generation.
- [r] Key contributions: adaptive per-class thresholds, novel WGAN training, comprehensive ablations.
- [r] Framework (§3.2) details method; experiments (§3.3) validate on seven benchmarks.

## Section 3.2: Framework

### Subsection 3.2.1: Problem Statement

- [r] Goal: train student on few-shot set to approximate black-box teacher performance.
- [r] Standard KD suboptimal with few-shot data; requires abundant training images.
- [r] Proposed method: DivBFKD two-phase pipeline (Generation, Distillation) with high-confidence filtering.

### Subsection 3.2.2: Generation Phase

- [r] WGAN with generator G and discriminator D for diverse synthetic image generation.
- [r] Few-shot WGAN alone fails: generates images similar to few-shot set, not teacher's true distribution.
- [r] High-confidence images: synthetic samples where teacher's max probability exceeds threshold τ.
- [r] Class-specific bias: teacher predicts different classes with varying confidence; requires adaptive τ^k.
- [r] Adaptive thresholds: class-specific τ^k from q-quantile of real image confidence scores.
- [r] WGAN architecture: symmetric generator and discriminator with convolutional blocks.
- [r] High-confidence images as proxy for unknown teacher training distribution; positive feedback loop.
- [r] Novel training scheme: discriminator trains on real + high-confidence synthetic (not just real/fake).
- [r] Novelty summary: teacher-supervised adaptive thresholds guide synthesis toward teacher's distribution.
- [r] Implementation: store high-confidence set each step, update discriminator on combined real+synthetic.

### Subsection 3.2.3: Distillation Phase

- [r] Distillation set combines N real + M synthetic images; train student via cross-entropy.
- [r] Class balancing via rejection sampling ensures balanced synthetic image distribution.

## Section 3.3: Experiments

### Subsection 3.3.1: Setup and Baselines

- [r] Wide range of experiments: simple/complex datasets, cross-architecture, ablations, data-free comparison.
- [r] Baselines: Student-Full, Student-Alone, Standard-KD, FSKD, WaGe, BBKD, FS-BBT.
- [r] Fair comparison: same architecture, matched image budgets (N, M) as prior work.

### Subsection 3.3.2: Implementation Details

- [r] Seven datasets: MNIST, FMNIST, SVHN, CIFAR10, CIFAR100, Tiny-ImageNet, Imagenette.
- [r] Few-shot budget: N=2K (MNIST/FMNIST/SVHN/CIFAR10/Imagenette), N=5K (CIFAR100), N=10K (Tiny-ImageNet).
- [r] Architectures: LeNet5, AlexNet, ResNet, VGG; standard across few-shot KD literature.
- [r] Teacher: SGD momentum 0.9, weight decay 5e-4, 100-200 epochs depending on dataset.
- [r] Student: SGD momentum 0.9, weight decay 5e-4, 100-1000 epochs with scheduled learning rate decay.
- [r] WGAN generator: latent→256 base features 8×8→upscale→image; discriminator symmetric.
- [r] WGAN training: gradient penalty 10:1, 5 discriminator updates per generator update.

### Subsection 3.3.3: Distillation Performance

- [r] Two settings: smaller student (LeNet5→LeNet5-Half, AlexNet→AlexNet-Half) and same architecture.
- [r] Simple datasets: DivBFKD +3–6% over Standard-KD (MNIST/FMNIST/SVHN), +17% on CIFAR10.
- [r] Complex datasets: DivBFKD beats FS-BBT by +3% (CIFAR100), +1% (Tiny-ImageNet).
- [r] High-resolution Imagenette: DivBFKD +10% over Standard-KD, approaches Student-Full performance.

### Subsection 3.3.4: Cross-Architecture Distillation

- [r] Cross-architecture setup: evaluate ResNet, VGG, AlexNet teacher-student pairs on CIFAR10.
- [r] Cross-architecture: ResNet teacher best; DivBFKD +14–22% over Standard-KD on all pairs.

### Subsection 3.3.5: Diversity Analysis

- [r] Embedding visualization: synthetic images overlap teacher's training distribution in visualization.
- [r] Coverage metric: DivBFKD 0.42 vs few-shot 0.18, standard WGAN 0.29; superior distribution overlap.
- [r] Quality metrics IS and FID: DivBFKD 4.42 IS, 13.96 FID; best among all compared methods.
- [r] Visual quality: DivBFKD synthetic images plausible; demonstrate convincing properties of real counterparts.

### Subsection 3.3.6: Ablation Studies

- [r] Component ablation: adaptive thresholds +0.76%, class balancing +0.53%; jointly +1.38%.
- [r] Data scaling: DivBFKD robust at N=250 (66.76%) vs Standard-KD (33.33%); improves with M.
- [r] Quantile stability: q ∈ [0.03, 0.10] achieves 76.22–76.97% (recommended range).

### Subsection 3.3.7: Comparison with Data-Free Methods

- [r] Data-free comparison: DivBFKD 87.65% (FMNIST), 78.07% (CIFAR10); outperforms ZSDB3KD, IDEAL.

## Section 3.4: Conclusion

- [r] High-confidence filtering with adaptive per-class thresholds achieves SOTA few-shot KD.

---

# Chapter 4: DIPKD: Diverse Image Priors for Black-box Data-free Knowledge Distillation

## Section 4.1: Introduction

- [r] Data-free qualitatively different from few-shot: no real-data anchor for synthesis.
- [r] Prior BBDFKD methods encounter domain-coverage and information-bottleneck deficits.
- [r] DIPKD: three-phase pipeline (Synthesis, Contrast, Distillation) addressing both deficits.
- [r] Contributions: image priors, primer student, SOTA on 12 benchmarks.
- [r] Framework (§4.2), experiments (§4.3), conclusion (§4.4) follow.

## Section 4.2: Proposed Framework

### Subsection 4.2.1: Problem Setup

- [r] Black-box teacher returns only hard labels; train student without real data.
- [r] Naive KD baseline on uniform noise fails: non-diverse noise lacks semantics.
- [r] DIPKD three-phase collaborative pipeline: Synthesis, Contrast, Distillation.

### Subsection 4.2.2: Synthesis: Reconstructing the Knowledge Domain

- [r] Natural images characterized by hierarchy, nonlinearity, semantics; generate image priors via pipeline.
- [r] Hierarchy universal in nature; design sampler capturing local and global patterns.
- [r] Multi-scale noise: sample {U[0,1]^(2^d×2^d)} for d=0 to d_max, combine via softmax weights.
- [r] Nonlinear transforms: rotation (±45°), elastic deformation, cropping produce nonlinear-transformed images.
- [r] Semantic cutmixing: overcome rectangular CutMix via refined masking for coherent structures.
- [r] Diverging filter: piecewise quadratic (continuously differentiable at 0.5) produces sharp boundaries.
- [r] Iterative mask refinement to steady-state (~10 iterations); final cutmix creates image priors.

### Subsection 4.2.3: Contrast: Collaborative Diversity Optimization

- [r] Primer student S₀ trains on image priors via Hard-KD; acts as white-box mediator.
- [r] Instance-discriminator R appended to S₀ backbone; cosine similarity measures embedding similarity.
- [r] Contrastive loss: maximize Sim(x, x⁺), minimize Sim(x, x⁻); backprop updates R and samples x.

### Subsection 4.2.4: Distillation: Restoring Informative Signals

- [r] Hard-KD + Soft-KD: match student logits with teacher hard labels and primer soft labels.

## Section 4.3: Experiments

- [r] Evaluate DIPKD on extensive BBDFKD benchmarks with ablations and practical analysis.
- [r] Twelve benchmarks: 8 general-purpose (USPS, MNIST, SVHN, FMNIST, CIFAR10/100, Tiny-ImageNet, Imagenette) + 4 MedMNIST.
- [r] Baselines: NaiveKD (uniform noise) and SOTA BBDFKD methods (ZSDB3, IDEAL, DFHL-RS).
- [r] Dataset categories: simple (10 classes), complex (10–200 classes), domain-specific (medical).
- [r] DIPKD outperforms baselines on 11/12 datasets; large margins on complex/domain-specific tasks.
- [r] Performance saturates on simple; gap widens on complex; diversity critical at scale.
- [r] Consistently low standard errors across runs; robustness attributed to diversity and soft signals.
- [r] Ablations: component dissection, budget scaling, cross-architecture robustness, aggressive compression.
- [r] Component dissection: Synthesis largest gain (+2.27% MNIST, +64.18% CIFAR10, primarily hierarchical noise).
- [r] Image priors embeddings overlap teacher's distribution; superior density/coverage/recall vs noise.
- [r] Contrast phase expands coverage into neighboring regions; coverage/recall increase with trivial density trade-off.
- [r] Synthetic budget minimum quorum: 10K (digits), 100K (large-scale); emergence of collective intelligence.
- [r] Cross-architecture: best when teacher/student match; degradation acceptable; practical for unknown teachers.
- [r] Aggressive compression: stable at 25% CR, tolerable at 4% CR; significant drop at 1% CR.

## Section 4.4: Conclusion

- [r] Synthesis, Contrast, Distillation phases unify domain-coverage, diversity, and soft-signal recovery for data-free black-box KD.

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
- TAKE achieves 85--92% of oracle accuracy across datasets, outperforming clustering and generation baselines by 3--8%.
- Backbone-agnostic advantage: TAKE works with DistilBERT and ALBERT without retuning.
- Stability: TAKE's standard deviation is 2--3× lower than baselines, indicating correct bias correction.
- SST-2 comparison: TAKE outperforms DiLM (prior state-of-the-art) by 2--4%, showing trajectory-aware advantage.

### Subsection 5.5.3: Natural Language Inference

- Table: NLI accuracy on MNLI-m and QQP with TAKE, DiLM, baselines, and oracle.
- NLI gains are consistent with classification; TAKE achieves 80--88% of oracle accuracy.
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

- Restate deployment paradox: capable models blocked by physical, legal, economic constraints at inference.
- Name unifying thread: distributional fidelity as active upstream constraint, not passive assumption.
- Name three problem axes: source access, generation prior, selection geometry under tightening restrictions.
- Transition: synthesis follows, not recap; one thesis, not three papers.

## Section 6.1: Summary of Contributions

- Synthesis: three works trace one arc from restricted access to active fidelity enforcement.
- DivBFKD enforces fidelity under few-shot black-box access via WGAN with adaptive confidence filtering.
- DIPKD enforces fidelity under data-free black-box access via multi-scale priors and contrastive diversity.
- TAKE enforces fidelity over discrete tokens via trajectory-aware influence and optimal transport selection.
- TAKE validated across five benchmarks: AG News, IMDb, SST-2 classification and MNLI-m, QQP inference.
- In TAKE, importance-weighted OT beats importance-alone and coverage-alone selection on text benchmarks.
- Fidelity-first design enables edge, privacy-preserving, low-resource deployment, cutting carbon and respecting data governance.

## Section 6.2: Limitations and Future Directions

### Subsection 6.2.1: Technical Limitations

- DivBFKD: WGAN instability at scale limits high-resolution and many-class settings.
- DivBFKD: class-specific thresholds ignore domain shift and task-relevant diversity.
- DIPKD: structured noise priors are semantically agnostic to teacher-relevant features.
- DIPKD: primer architecture $S_0$ is pre-selected without principled criterion.
- DIPKD: $S_0$ soft labels are not guaranteed to align with the true teacher distribution.
- TAKE: gradient-norm proxy lacks Fisher preconditioning, overstating noisy-sample influence.
- TAKE: OT cost matrix inherits encoder $\phi$ geometry, distorting transport under mismatch.
- TAKE: LLM generation pool risks memorising rare training samples.
- TAKE: discrete OT solver scales quadratically, capping corpus size.
- Cross-cutting: all three assume teacher correctness and lack task-specific fidelity measures.
- Cross-cutting: long-tailed subpopulations remain underserved across the three frameworks.
- Cross-cutting: black-box and discrete-token distillation lack standardised evaluation protocols.

### Subsection 6.2.2: Theoretical Open Problems

- Fidelity-efficiency Pareto frontier remains uncharacterised; no formal bound links coverage to generalisation gap.
- Privacy-fidelity coupling is unexplored: synthetic data leakage under membership inference lacks formal $\varepsilon$ accounting.
- Hard-sample bias causality under compression is unresolved; whether amplification is selection or representation remains open.
- Convergence of trajectory-matching distillation under stochastic optimisation lacks formal guarantees.

### Subsection 6.2.3: Future Directions

- Co-design fidelity with differential privacy under explicit $\varepsilon$ budgets across synthesis and selection.
- Strengthen distributional robustness so compressed students preserve fidelity under OOD and long-tailed shift.
- Establish standardised benchmarks for black-box distillation and discrete-token dataset distillation.
- Extend fidelity enforcement to non-stationary, multi-modal, and continually evolving teacher distributions.
- Once fidelity is solved, distillation becomes a substrate for auditable, on-device, lifelong learning systems.
- Closing: transfer intelligence through fidelity, not model capacity copying.
