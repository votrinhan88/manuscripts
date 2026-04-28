#!/bin/bash
# List all versions for a given paper

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PAPERS_DIR="$REPO_DIR/papers"

usage() {
    echo "Usage: ./list-versions.sh PAPER_NAME"
    echo ""
    echo "  ./list-versions.sh 2026-my-topic   List all versions of a paper"
}

if [ "$#" -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    usage
    exit 0
fi

paper="$1"
versions_dir="$PAPERS_DIR/$paper/versions"

if [ ! -d "$versions_dir" ]; then
    echo "Error: No versions directory for '$paper'"
    exit 1
fi

versions=($(ls -1 "$versions_dir" 2>/dev/null | sort))

if [ ${#versions[@]} -eq 0 ]; then
    echo "No versions found for $paper"
    exit 1
fi

for version in "${versions[@]}"; do
    echo "$version"
done
