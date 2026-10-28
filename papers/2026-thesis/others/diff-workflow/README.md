# Diff workflow: Editorial Version and Summary of Changes

## What

`build.sh` builds up to three documents from git. The default is the Editorial Version and the table:

| Stage | Output | Content |
|---|---|---|
| `main` | `main.pdf` (thesis folder) | The clean thesis |
| `inline` | `main-diffexamined.{tex,pdf}` | The thesis with changes marked. Blue wavy underline is added text, red strikethrough is deleted text |
| `table` | `summary-of-changes.{tex,pdf}` | One row per changed sentence: original, revised text, score, and the page in the Editorial Version |

Results of `inline` and `table` go to `others/diff-workflow/output/`. Only `.tex` and `.pdf` files are kept.

## Why

The list of changes comes from the two versions of the thesis, not from memory. One rule applies to every sentence, so the list is complete and unbiased, and anyone can reproduce it.

## How

```bash
bash others/diff-workflow/build.sh --diff_source=examined
```

With no arguments the script prints help and does nothing.

`--diff_source` is a git tag or commit for the version the examiners saw. Create the tag once. It stays local.

```bash
git tag examined <commit>
git tag -l examined
```

Run from the thesis folder (`papers/2026-thesis`). The command needs Git Bash and these tools: `git`, `python`, `latexmk`, `pdflatex`, `latexpand`, `latexdiff`, `pdfinfo`, `pdftotext`.

A run takes about 10 minutes. Most of it is `latexdiff` (about 5 minutes) and the LaTeX build of the Editorial Version. The script never runs by itself. Start it and wait for `exit 0`.

### Options

| Option | Meaning | Default |
|---|---|---|
| `--diff_source=REF` | Git ref the examiners saw | `examined` |
| `--diff_current=REF` | Revised version: a git ref, or `worktree` | `worktree` |
| `--output=DIR` | Result folder, relative to the thesis folder | `others/diff-workflow/output` |
| `--only=STAGES` | Comma list of `main`, `inline`, `table`, or `all`. `table` needs `inline` in the same run | `inline,table` |
| `--distance=word_lev\|word_count` | Score: word-level Levenshtein or plain word count | `word_lev` |
| `--cutoff=X` | Drop rows with a score below X | `1.0` |
| `--stopword-weight=W` | Cost of a stopword | `0.25` |
| `--count_spelling=BOOL` | Also list British to American spelling changes | `false` |
| `--cleanup=BOOL` | Delete the temporary working copy after the run. Use `false` to inspect it when a build fails | `true` |
| `--dry-run` | Print the steps, run nothing | |
| `-h`, `--help` | Show help | |

### Examples

```bash
# Editorial Version and table (the default stages)
bash others/diff-workflow/build.sh --diff_source=examined

# the same, with a higher cutoff
bash others/diff-workflow/build.sh --diff_source=examined --cutoff=2

# also rebuild the clean thesis (main.pdf)
bash others/diff-workflow/build.sh --diff_source=examined --only=all

# only the clean thesis, keep its temp files for debugging
bash others/diff-workflow/build.sh --only=main --cleanup=false

# preview the steps
bash others/diff-workflow/build.sh --diff_source=examined --dry-run
```

### Page numbers

The Page column of the table is the page number printed on the page of the Editorial Version (arabic or roman, as at the foot of the page). It does not depend on any other document, so you can put the Editorial Version behind a cover letter or any other pages without changing the table.

How the script finds the page: it takes the longest run of up to 6 unchanged words in a row and searches for it in the text of the Editorial Version, in reading order. If a row has fewer than 4 unchanged words (for example a new sentence), it searches for the inserted words instead. It then reads the number printed at the foot of that page.

## The response letter

`../response-to-examiners/response-to-examiners.tex` is written by hand and is not part of the workflow. It reads the results:

| What | How |
|---|---|
| Row counts and cutoff in the text | `\input` of `output/summary-of-changes-stats.tex` (`\nrowslisted`, `\nrowsdropped`, `\mincutoff`) |
| Summary of Changes table | `\includepdf` of `output/summary-of-changes.pdf` |
| Editorial Version | `\includepdf` of `output/main-diffexamined.pdf` |

The letter has no fixed page numbers or row counts, so it stays correct after a rebuild. After every rebuild, compile the letter again. Compile it in a temporary output folder, because an editor or PDF viewer often locks its temp files:

```bash
T=$(mktemp -d); cd others/response-to-examiners
pdflatex -output-directory="$T" response-to-examiners.tex   # run twice
cp "$T/response-to-examiners.pdf" .
```

## Is anything out of date?

The outputs are stale when a thesis source file is newer than the output. Compare timestamps:

```bash
ls -l --time-style='+%m-%d %H:%M' main.pdf others/diff-workflow/output/* others/response-to-examiners/response-to-examiners.pdf
find content references.bib main.tex preamble.tex figures extra_pages -type f -printf '%TY-%Tm-%Td %TH:%TM %p\n' | sort | tail -3
```

The order must be: thesis sources, then `output/`, then the letter PDF. If not, rebuild (`inline,table`, and `main` if `main.pdf` is older), then compile the letter.

## How it works

| Step | Action |
|---|---|
| 1 | The script copies the thesis sources to a temporary folder outside the synced repo. Every LaTeX build runs there: `pdflatex` once, then `latexmk` |
| 2 | `git archive` extracts the old version. `latexpand` flattens old and new to single files |
| 3 | `latexdiff --type=UNDERLINE` marks the differences. The result is built like step 1 |
| 4 | `changes_report.py` compares sentences, scores them, and reads printed page numbers and section numbers from the Editorial Version build |
| 5 | Only `.tex` and `.pdf` files are copied to `--output`. The table is compiled there, and `tools/clean.sh` removes its temp files. With `--cleanup=true`, the temporary copy is deleted |

| File | Role |
|---|---|
| `build.sh` | Runs the stages |
| `changes_report.py` | Compares old and new sentences, scores them, writes `summary-of-changes.tex` and `summary-of-changes-stats.tex` |
| `output/` | Results |

## Scoring rule

The script compares the old and new files one sentence at a time (one source line is one sentence).

- Spelling-only changes (British to American) are ignored unless `--count_spelling=true`.
- Adjacent changed sentences form one row. A row never crosses a `\begin{foldable}` line.
- The score of a row is the word-level Levenshtein distance between the old and new text:
  - Words are normalized first: lowercase, no punctuation, endings `-s`, `-es`, `-ed`, `-ing`, `-ly` removed. A `\ref` counts as one word.
  - Inserting, deleting, or swapping a word costs **1**.
  - A stopword (the, of, to, and, we, is, and similar) costs **0.25**.
  - Words with the same normalized form cost **0**.
  - The score of a row is the sum.
- Rows below the cutoff are dropped. The default cutoff is **1.0**. It keeps every change that alters one real word and drops only rows with no word change.

Examples: "match" to "approach" scores 1.0. "yields" to "aims to yield" scores 1.25 ("aims" costs 1, "to" costs 0.25). "TAKE ;" to "TAKE;" scores 0.

A higher cutoff hides short edits. Examiner-driven fixes are often one or two words, so do not raise the cutoff above 1 without checking what it drops.

Change the rule in `changes_report.py`:

| Setting | Where |
|---|---|
| Cutoff, distance, stopword weight | `--cutoff`, `--distance`, `--stopword-weight` |
| Stopword list | `STOPWORDS` |
| Word normalization | `norm_word()` |
| Which lines count as text | `is_prose()` |

Not listed: table cells, section titles, and lines of LaTeX structure. A new table appears only through its caption and intro sentence.

## Known problems

| Problem | Cause | Fix |
|---|---|---|
| `latexdiff-vc` fails with "cannot find the path" | It builds a temp path that Windows cannot use | Not used. `build.sh` flattens and diffs the two files directly |
| Build fails with "File ended while scanning use of `\@newl@bel`", "invalid character", or page-tree errors | NUL bytes in a `.aux` file. The synced DeskBox/OneDrive folder corrupts LaTeX temp files at random | Never build inside the synced folder. `build.sh` builds in a temporary copy. If you build by hand, copy the thesis out first, or run `bash ../../tools/clean.sh` and retry |
| `latexmk` fails with "no \citation commands" | No `.aux` exists yet, so `bibtex` runs first | The script runs `pdflatex` once before `latexmk` |
| A build writes a 151-page `main.pdf` with undefined references | The build used `-outdir`, and `bibtex` could not find its inputs | Do not use `-outdir`. Build in a plain copy of the thesis folder, as the script does |
| "Device or resource busy" on `main.pdf`, or the letter will not compile | A PDF viewer or editor has the file open | Close the viewer, or compile the letter in a temporary output folder |
| A row has the previous row's page | Its words were not found in the PDF text, for example a deleted sentence | Open the Editorial Version near the previous row |
| `__pycache__` folders appear | Python caches the script | Safe to delete. They are not needed |
| Backslash commands become control characters in inline Python | Shell quoting changes `\r`, `\a`, `\t` | Put Python in a script file, or build the backslash with `chr(92)` |

## Reproducibility

- The examined version is a git tag (`examined`). It must point to the commit the examiners received.
- With `--diff_current=worktree`, uncommitted edits are included.
- Versions used: TeX Live 2025, `latexmk` 4.86, Python 3.14. The script uses only the standard library.
- After any further edit to the thesis, run the build again. `inline` and `table` always rebuild together. Then compile the letter again.
- The workflow does not commit anything. Commit the thesis, `output/`, and the letter yourself.
- Everything in `output/` can be deleted and rebuilt.
