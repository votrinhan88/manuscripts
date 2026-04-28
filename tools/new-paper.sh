#!/bin/bash
# Create a new paper with standard structure

usage() {
    echo "Usage: ./new-paper.sh --paper=YYYY-topic-name"
    echo ""
    echo "  Creates a new paper directory with template structure."
    echo ""
    echo "Options:"
    echo "  -p, --paper=NAME    Paper name (required)"
    echo ""
    echo "Examples:"
    echo "  ./new-paper.sh --paper=2026-neural-attention"
    echo "  ./new-paper.sh -p 2026-neural-attention"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

PAPER_NAME=""

# Parse flags
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--paper=*)
            if [[ $1 == *"="* ]]; then
                PAPER_NAME="${1#--paper=}"
            else
                PAPER_NAME="$2"
                shift
            fi
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$PAPER_NAME" ]; then
    echo "Error: --paper is required"
    usage
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

PAPER_DIR="$REPO_DIR/papers/$PAPER_NAME"
SHARED_DIR="$REPO_DIR/shared"

if [ -d "$PAPER_DIR" ]; then
    echo "Error: $PAPER_DIR already exists"
    exit 1
fi

if [ ! -d "$SHARED_DIR" ]; then
    echo "Error: $SHARED_DIR not found"
    exit 1
fi

mkdir -p "$PAPER_DIR/figures"

# Copy shared files
cp "$SHARED_DIR/templates/preamble.tex" "$PAPER_DIR/"
cp "$REPO_DIR/papers/references.bib" "$PAPER_DIR/"
cp "$SHARED_DIR/templates/main.tex" "$PAPER_DIR/"

# Create section files to match template structure
touch "$PAPER_DIR/00-abstract.tex"
touch "$PAPER_DIR/01-introduction.tex"
touch "$PAPER_DIR/02-related.tex"
touch "$PAPER_DIR/03-framework.tex"
touch "$PAPER_DIR/04-experiments.tex"
touch "$PAPER_DIR/05-conclusion.tex"

# Add placeholder content
for file in "$PAPER_DIR"/0{0..5}-*.tex; do
    echo "% TODO: Write this section" > "$file"
done

echo "[OK] Created new paper: $PAPER_DIR"
