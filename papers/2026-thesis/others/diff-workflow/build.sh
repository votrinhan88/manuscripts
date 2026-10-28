#!/usr/bin/env bash
# Build the clean thesis, the Editorial Version and the Summary of Changes table.
# Run with no arguments to print help. Nothing runs unless you pass an argument.
# Full guide: others/diff-workflow/README.md

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"                      # papers/2026-thesis
CLEAN_SH="$(cd "$ROOT/../.." && pwd)/tools/clean.sh"   # repo tool: deletes LaTeX temp files under the current folder

usage() {
cat <<'EOF'
Usage: build.sh [options]          (no arguments prints this help)

Builds, from git, the clean thesis (main), the Editorial Version (inline) and the
Summary of Changes table (table). The LaTeX builds run in a temporary copy
outside the synced folder, so no LaTeX temp files appear in the repo.
Only .tex and .pdf files are written back.

Options (defaults in brackets):
  --diff_source=REF       git ref the examiners saw: tag or commit      [examined]
  --diff_current=REF      revised version: a git ref, or "worktree"     [worktree]
  --output=DIR            where to write results, relative to the
                          thesis folder (papers/2026-thesis)            [others/diff-workflow/output]
  --only=STAGES           comma list of: main, inline, table, or all    [inline,table]
                            main    clean thesis -> main.pdf (thesis folder)
                            inline  Editorial Version -> main-diffexamined.{tex,pdf}
                            table   change table -> summary-of-changes.{tex,pdf}
                          table needs inline in the same run (--only=inline,table).
  --distance=METRIC       word_lev | word_count                         [word_lev]
  --cutoff=X              drop rows with a score below X                [1.0]
  --stopword-weight=W     cost of a stopword in the score               [0.25]
  --count_spelling=BOOL   also list British->American spelling changes  [false]
  --cleanup=BOOL          delete the temporary copy after the run       [true]
  --dry-run               print the steps without running them
  -h, --help              show this help

Examples:
  bash others/diff-workflow/build.sh --diff_source=examined
  bash others/diff-workflow/build.sh --diff_source=examined --cutoff=2
  bash others/diff-workflow/build.sh --diff_source=examined --only=all
  bash others/diff-workflow/build.sh --only=main --cleanup=false
EOF
}

# ---- defaults
SOURCE="examined"; CURRENT="worktree"; OUTPUT="others/diff-workflow/output"; ONLY="inline,table"
DISTANCE="word_lev"; CUTOFF="1.0"; STOPW="0.25"; SPELL="false"; CLEANUP="true"; DRY="false"

[ "$#" -eq 0 ] && { usage; exit 0; }
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --diff_source=*)     SOURCE="${arg#*=}" ;;
    --diff_current=*)    CURRENT="${arg#*=}" ;;
    --output=*)          OUTPUT="${arg#*=}" ;;
    --only=*)            ONLY="${arg#*=}" ;;
    --distance=*)        DISTANCE="${arg#*=}" ;;
    --cutoff=*)          CUTOFF="${arg#*=}" ;;
    --stopword-weight=*) STOPW="${arg#*=}" ;;
    --count_spelling=*)  SPELL="${arg#*=}" ;;
    --cleanup=*)         CLEANUP="${arg#*=}" ;;
    --dry-run)           DRY="true" ;;
    *) echo "unknown argument: $arg (see --help)" >&2; exit 2 ;;
  esac
done

# ---- validate
[ "$ONLY" = "all" ] && ONLY="main,inline,table"
DO_MAIN=false; DO_INLINE=false; DO_TABLE=false
IFS=',' read -ra STAGES <<< "$ONLY"
for st in "${STAGES[@]}"; do
  case "$st" in main) DO_MAIN=true ;; inline) DO_INLINE=true ;; table) DO_TABLE=true ;;
    *) echo "--only: unknown stage '$st' (use main, inline, table, all)" >&2; exit 2 ;; esac
done
if $DO_TABLE && ! $DO_INLINE; then
  echo "--only=table needs the Editorial Version build. Use --only=inline,table" >&2; exit 2
fi
case "$DISTANCE" in word_lev) METRIC="lev" ;; word_count) METRIC="count" ;; *) echo "--distance must be word_lev or word_count" >&2; exit 2 ;; esac
case "$CLEANUP" in true|false) ;; *) echo "--cleanup must be true or false" >&2; exit 2 ;; esac
case "$SPELL" in true|false) ;; *) echo "--count_spelling must be true or false" >&2; exit 2 ;; esac

cd "$ROOT"
OUTDIR="$ROOT/$OUTPUT"
say() { printf '\n== %s\n' "$*"; }
need() { command -v "$1" >/dev/null 2>&1 || { echo "missing tool: $1" >&2; exit 1; }; }

if [ "$DRY" = "false" ]; then
  for t in git python latexmk pdflatex latexpand latexdiff pdfinfo pdftotext; do need "$t"; done
  [ -f "$CLEAN_SH" ] || { echo "missing $CLEAN_SH" >&2; exit 1; }
fi
if $DO_INLINE; then
  git rev-parse -q --verify "$SOURCE^{commit}" >/dev/null 2>&1 \
    || { echo "diff_source '$SOURCE' is not a tag or commit. Create it: git tag $SOURCE <commit>" >&2; exit 1; }
  if [ "$CURRENT" != "worktree" ]; then
    git rev-parse -q --verify "$CURRENT^{commit}" >/dev/null 2>&1 || { echo "diff_current '$CURRENT' is not a git ref" >&2; exit 1; }
  fi
fi

echo "source=$SOURCE current=$CURRENT output=$OUTPUT only=$ONLY distance=$DISTANCE cutoff=$CUTOFF"
echo "stopword-weight=$STOPW count_spelling=$SPELL cleanup=$CLEANUP dry-run=$DRY"

# ---- temporary working copy outside the synced folder.
# LaTeX temp files written inside the synced folder get corrupted at random
# (NUL bytes in .aux files). Building in a copy avoids it.
WORK=""
cleanup_work() { if [ "$CLEANUP" = "true" ] && [ -n "$WORK" ]; then rm -rf "$WORK" || true; fi; }
trap cleanup_work EXIT

if [ "$DRY" = "false" ]; then
  WORK="$(mktemp -d)"
  cp -r content figures extra_pages references.bib main.tex preamble.tex "$WORK"/
  echo "working copy: $WORK"
fi

# clean DIR: delete LaTeX temp files under DIR with the repo tool
clean() {
  if [ "$DRY" = "true" ]; then echo "[dry-run] tools/clean.sh in $1"; return; fi
  ( cd "$1" && bash "$CLEAN_SH" >/dev/null )
}

# build NAME: NAME.tex in the working copy -> NAME.pdf. One plain pdflatex run,
# then latexmk (bibtex and reruns). Stops on a LaTeX error.
build() {
  local name="$1"
  if [ "$DRY" = "true" ]; then echo "[dry-run] pdflatex; latexmk $name.tex (in the working copy)"; return; fi
  ( cd "$WORK"
    pdflatex -interaction=nonstopmode "$name.tex" >/dev/null 2>&1 || true
    latexmk -pdf -interaction=nonstopmode "$name.tex" >/dev/null 2>&1 || true
    if grep -a -q '^!' "$name.log"; then
      echo "LaTeX error in $name.log:" >&2
      grep -a -n -A4 '^!' "$name.log" | head -20 >&2
      echo "working copy kept for debugging: $WORK" >&2
      exit 1
    fi
    grep -a -q -i 'undefined' "$name.log" && echo "warning: undefined references or citations in $name" >&2 || true
  ) || { CLEANUP=false; exit 1; }
}

if $DO_MAIN; then
  say "clean thesis (main.pdf)"
  build main
  if [ "$DRY" = "false" ]; then
    cp "$WORK/main.pdf" "$ROOT/main.pdf"
    pdfinfo "$ROOT/main.pdf" | grep Pages
  fi
fi

if $DO_INLINE; then
  say "old version from '$SOURCE'"
  PREFIX="$(git rev-parse --show-prefix)"; TOP="$(git rev-parse --show-toplevel)"
  if [ "$DRY" = "true" ]; then echo "[dry-run] git archive $SOURCE; latexpand old and new; latexdiff"; else
    mkdir -p "$WORK/old" "$WORK/new"
    git -C "$TOP" archive "$SOURCE" "${PREFIX%/}" | tar -x -C "$WORK/old"
    ( cd "$WORK/old/${PREFIX%/}" && latexpand main.tex > "$WORK/old-flat.tex" )
    if [ "$CURRENT" = "worktree" ]; then
      ( cd "$WORK" && latexpand main.tex > "$WORK/new-flat.tex" )
    else
      git -C "$TOP" archive "$CURRENT" "${PREFIX%/}" | tar -x -C "$WORK/new"
      ( cd "$WORK/new/${PREFIX%/}" && latexpand main.tex > "$WORK/new-flat.tex" )
    fi
  fi

  say "Editorial Version (main-diffexamined)"
  if [ "$DRY" = "true" ]; then echo "[dry-run] latexdiff --type=UNDERLINE; build main-diffexamined; copy .tex and .pdf to $OUTPUT"; else
    # latexdiff-vc is not used: it fails on Windows paths.
    ( cd "$WORK" && latexdiff --type=UNDERLINE \
      --exclude-textcmd="section,subsection,subsubsection,caption" \
      --config="PICTUREENV=(?:picture|DIFnomarkup|tabular|table|figure|equation|align|algorithm)[\\w\\d*@]*" \
      old-flat.tex new-flat.tex > main-diffexamined.tex 2> latexdiff.err )
    build main-diffexamined
    pdfinfo "$WORK/main-diffexamined.pdf" | grep Pages
  fi

  if $DO_TABLE; then
    say "Summary of Changes table"
    EXTRA=()
    [ "$SPELL" = "true" ] && EXTRA+=(--keep-spelling)
    [ "$CURRENT" != "worktree" ] && EXTRA+=(--new-ref "$CURRENT")
    if [ "$DRY" = "true" ]; then echo "[dry-run] python changes_report.py --ref $SOURCE --min-words $CUTOFF --metric $METRIC ..."; else
      mkdir -p "$OUTDIR"
      python others/diff-workflow/changes_report.py --ref "$SOURCE" --min-words "$CUTOFF" --metric "$METRIC" \
        --stopword-weight "$STOPW" ${EXTRA[@]+"${EXTRA[@]}"} \
        --diff-pdf "$WORK/main-diffexamined.pdf" --diff-aux "$WORK/main-diffexamined.aux" \
        --out "$OUTPUT/summary-of-changes"
      ( cd "$OUTDIR" && pdflatex -interaction=nonstopmode summary-of-changes.tex >/dev/null 2>&1 \
          && pdflatex -interaction=nonstopmode summary-of-changes.tex >/dev/null 2>&1 )
      clean "$OUTDIR"
    fi
  fi

  if [ "$DRY" = "false" ]; then
    mkdir -p "$OUTDIR"
    cp "$WORK/main-diffexamined.tex" "$WORK/main-diffexamined.pdf" "$OUTDIR/"
  fi
fi

say "done"
if [ "$DRY" = "false" ]; then
  [ -d "$OUTDIR" ] && ls -1 "$OUTDIR" | sed 's/^/  /'
  $DO_MAIN && echo "  (clean thesis: main.pdf in the thesis folder)"
  [ "$CLEANUP" = "false" ] && echo "  working copy kept: $WORK"
fi
true
