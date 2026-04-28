# Manuscripts Repository

LaTeX source for academic manuscripts, organized as a monorepo with shared resources.

## Structure

- **papers/** - Individual manuscript directories (example: `YYYY-topic`)
  - `references.bib` - Shared bibliography file
- **shared/** - Common resources
  - `main.tex` - <TODO>
  - `preamble.tex` - Standard packages and document configurations
- **tools/** - TUI scripts to manage/build/update manuscripts
- **docs/** - Guidelines and documentation

## Quick Start

### For New Projects

**Start from the `scaffold` branch** (not `main`):

```bash
git clone <repo-url>
git checkout scaffold
./tools/new-paper.sh --paper=2026-your-topic
```

The `scaffold` branch contains the project template and tools without any papers. The `main` branch contains published papers and may have conflicting changes.

### For Running Commands

Use the TUI menu interface:

```bash
./tools/main.sh
```

Or use scripts directly:

```bash
./tools/new-paper.sh --paper=2026-my-topic  # Initialize new paper with template
./tools/new-version.sh --paper=2026-my-topic --version=arxiv  # Create versioned snapshot
./tools/build-paper.sh --paper=2026-my-topic  # Compile LaTeX to PDF
./tools/clean.sh  # Remove temporary LaTeX files
./tools/bib_checker.sh --bib=papers/2026-my-topic/references.bib --tex=papers/2026-my-topic  # Analyze citations
```

Short forms: `-p` for `--paper`, `-v` for `--version`, `-f` for `--force`.

## Paper Structure

Each paper contains:

- **Main document:** `main.tex`
- **Sections:** Following the template structure:
  - `00-abstract.tex`
  - `01-introduction.tex`
  - `02-related.tex`
  - `03-framework.tex`
  - `04-experiments.tex`
  - `05-conclusion.tex`
- **Config:** `preamble.tex`, `references.bib`
- **Assets:** `figures/` directory (external, not tracked)
- **Snapshots:** `versions/` directory for submission versions

## Figures

Keep figures in external storage (OneDrive, cloud, etc.) to minimize repository size.

Reference in LaTeX:

```latex
\includegraphics{figures/my-figure.pdf}
```

Figures are not tracked in git (see `.gitignore`).

## File Naming

- Papers: `YYYY-kebab-case-topic`
- Sections: `NN-section-name.tex` (00-05)
- Figures: `figure-descriptive-name.pdf` or `.png`

## Documentation

See [`docs/`](docs/) for:
- [Commit format guidelines](docs/commit-format.md)
- [Workflow and rebasing guide](docs/update-guide.md)
