# Notation and Conventions for Thesis

This document defines the mathematical notation, LaTeX macros, acronyms, and writing conventions used throughout the thesis.

## Math Operators and Functions

All math operators must use `preamble.tex` macros for consistency:

- `\argmax` — argument maximizing a function
- `\argmin` — argument minimizing a function
- `\exp` — exponential function
- `\log` — natural logarithm
- `\sqrt` — square root
- `\frac` — fraction notation

## Theorem and Proof Environments

Use `preamble.tex` theorem environments:

- `\begin{theorem}...\end{theorem}` — formal theorems with labels (`\label{thm:...}`)
- `\begin{lemma}...\end{lemma}` — supporting lemmas
- `\begin{proof}...\end{proof}` — proofs (automatically appends QED symbol)
- `\begin{corollary}...\end{corollary}` — corollaries

## Utility Commands

Always use these convenience macros:

- `\ie` — shorthand for "that is" (properly formatted with spacing)
- `\eg` — shorthand for "for example"
- `\etc` — shorthand for "et cetera"
- `\boldtight{text}` — bold text (for emphasis in formal statements)

## Key Variables and Symbols

### Teacher-Student Framework

- **T** — teacher network
- **S** — student network
- **S₀** — primer student (used in some methods)

### Datasets and Data Symbols

- **D** — original training dataset
- **D\*** — augmented or synthetic dataset (context-dependent)
- **D_{KD}** — dataset for knowledge distillation
- **D_{train}** — training split
- **D_{synth}** — synthetically generated dataset
- **D̃** — query set in black-box setting
- **D_G** — generator-produced dataset

### Distributions

- **p(·)** — probability distribution
- **q(·)** — query or proposal distribution
- **τ** (tau) — temperature parameter for softening outputs

### Loss Functions

All loss functions use subscript notation:

- **L_{KD}** — knowledge distillation loss
- **L_{CE}** — cross-entropy loss
- **L_{KL}** — Kullback-Leibler divergence loss
- **L_G** — generator loss
- **L_D** — discriminator loss
- **L_{Hard-KD}** — hard (0/1) knowledge distillation loss
- **L_{Soft-KD}** — soft (probability) knowledge distillation loss
- **L_{CT}** — contrastive loss

### Key Hyperparameters and Scalars

- **α, λ** — weighting coefficients for loss terms
- **K** — number of queries or samples
- **N** — batch size or dataset cardinality
- **M** — model size or memory limit
- **q** — query dimensionality
- **τ** (tau) — temperature parameter (range 0–∞, typical 3–5)

### TAKE-Specific Notation (Chapter 5)

- **I_{n,t}** — information measure at sample n, timestep t
- **κ_n** — trajectory curvature for sample n
- **w_n** — importance weight for sample n
- **k(t)** — kernel function over time
- **T_m** — memory window length
- **γ\*** — optimal decision boundary
- **C_{nc}** — neural collapse component
- **φ** — feature representation

### Evaluation Metrics

- **IS** — Inception Score (for image quality)
- **FID** — Fréchet Inception Distance
- **Coverage** — diversity metric (% of modes covered)
- **Density** — concentration metric (samples per mode)
- **W_p** — p-Wasserstein distance

## Acronyms

All acronym definitions live in `preamble.tex` (`\DeclareAcronym{}`). Usage rules:

- First mention in a section: `\acfp{}` (full plural) or `\acf{}` (full singular)
- Subsequent mentions: `\ac{}` (acronym only)

## Label Naming Conventions

Use consistent label prefixes for cross-references:

- `\label{sec:chapter-section}` — sections (e.g., `\label{sec:3-2}` for Ch. 3.2)
- `\label{fig:chapter-description}` — figures (e.g., `\label{fig:3-divbfkd-arch}`)
- `\label{tab:chapter-description}` — tables (e.g., `\label{tab:4-results}`)
- `\label{eq:description}` — equations (e.g., `\label{eq:kl-divergence}`)
- `\label{alg:description}` — algorithms (e.g., `\label{alg:divbfkd-query}`)
- `\label{thm:description}` — theorems (e.g., `\label{thm:convergence}`)

**Reference format**: Always use `\ref{sec:...}`, `\eqref{eq:...}`, `\cref{fig:...}` (if cleveref is loaded), never bare numbers.

## Terminology and Phrasing

### Own Contributions vs. Prior Work

- **Prior work**: Use passive voice or explicit citations: "Research by X (cite) shows that..."
- **Own contributions**: Use active voice: "We propose...", "In this work, we introduce...", "We show that..."
- Do NOT use `\ours{}` command for one-off phrases; reserve it for systematic labeling of novel methods

### Consistency Rules

- Always use "knowledge distillation", not "KD", on first mention in a section
- Use "teacher model" and "student model", not "teacher network" and "student network" (except when discussing architecture details)
- Use "black-box" (hyphenated) when attributive: "black-box knowledge distillation"; "black box" (two words) when predicative: "access is a black box"
- Use "few-shot" (hyphenated) when attributive: "few-shot learning"
- Synthetic data: "synthetically generated data" on first mention, then "synthetic data"

## Citation Discipline

- Every factual claim about prior work must include `\cite{}`
- Your contributions require NO citation but MUST be marked clearly ("we show", "we propose", "in this work")
- Distinguish: background facts (cite), adapted results (cite + note adaptation), own contributions (no cite + clear ownership)

## Build Verification

Before marking notation as complete:
- [ ] All `\ac{}` entries resolve in LaTeX (no undefined acronyms)
- [ ] All math symbols compile without errors
- [ ] Theorem environments render properly with labels
- [ ] No undefined commands or macro conflicts with `preamble.tex`
