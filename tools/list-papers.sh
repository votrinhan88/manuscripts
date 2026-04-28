#!/bin/bash
# List all papers in the repository

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PAPERS_DIR="$REPO_DIR/papers"

if [ ! -d "$PAPERS_DIR" ]; then
    echo "Error: $PAPERS_DIR not found"
    exit 1
fi

papers=($(ls -1 "$PAPERS_DIR" 2>/dev/null | grep -E '^[0-9]{4}-' | sort))

if [ ${#papers[@]} -eq 0 ]; then
    echo "No papers found"
    exit 1
fi

for paper in "${papers[@]}"; do
    echo "$paper"
done
