#!/bin/bash
# Create a new version of an existing paper

usage() {
    echo "Usage: ./new-version.sh --paper=YYYY-topic --version=NAME [-f|--force]"
    echo ""
    echo "  Creates a snapshot of current paper files in versions/ folder."
    echo ""
    echo "Options:"
    echo "  -p, --paper=NAME      Paper name (required)"
    echo "  -v, --version=NAME    Version name (required)"
    echo "  -f, --force           Overwrite existing version"
    echo ""
    echo "Example:"
    echo "  ./new-version.sh --paper=2026-neural-attention --version=arxiv"
    echo "  ./new-version.sh -p 2026-neural-attention -v arxiv --force"
}

if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

PAPER_NAME=""
VERSION_NAME=""
FORCE=false

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
        -v|--version=*)
            if [[ $1 == *"="* ]]; then
                VERSION_NAME="${1#--version=}"
            else
                VERSION_NAME="$2"
                shift
            fi
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

if [ -z "$PAPER_NAME" ] || [ -z "$VERSION_NAME" ]; then
    echo "Error: --paper and --version are required"
    usage
    exit 1
fi

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PAPER_DIR="$REPO_DIR/papers/$PAPER_NAME"
VERSION_DIR="$PAPER_DIR/versions/$VERSION_NAME"

if [ ! -d "$PAPER_DIR" ]; then
    echo "Error: Paper '$PAPER_NAME' not found in $REPO_DIR/papers/"
    exit 1
fi

if [ -d "$VERSION_DIR" ]; then
    if [ "$FORCE" = false ]; then
        echo "Error: Version '$VERSION_NAME' already exists"
        echo "Use --force to overwrite: ./new-version.sh $PAPER_NAME $VERSION_NAME --force"
        exit 1
    fi
else
    mkdir -p "$VERSION_DIR"
fi

# Copy all .tex files to version folder
cp "$PAPER_DIR"/*.tex "$VERSION_DIR/"

echo "[OK] Created version: $PAPER_DIR/$VERSION_DIR"
