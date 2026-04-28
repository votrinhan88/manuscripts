#!/bin/bash
# Build papers in the repository

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

PAPERS_DIR="$REPO_DIR/papers"

if [ ! -d "$PAPERS_DIR" ]; then
    echo "Error: $PAPERS_DIR not found"
    exit 1
fi

usage() {
    echo "Usage: ./build-paper.sh [PAPER_NAME [main|all] | --all | -h]"
    echo ""
    echo "  ./build-paper.sh 2026-my-topic       Build main.tex (root level)"
    echo "  ./build-paper.sh 2026-my-topic main  Build main.tex only (skip versions)"
    echo "  ./build-paper.sh 2026-my-topic all   Build all versions"
    echo "  ./build-paper.sh 2026-my-topic/version-name  Build specific version"
    echo "  ./build-paper.sh --all               Build all papers"
    echo "  ./build-paper.sh -h, --help          Show this help message"
}

build_paper() {
    local paper_dir="$1"
    local paper_name=$(basename "$paper_dir")

    if [ ! -f "$paper_dir/main.tex" ]; then
        echo "[SKIP] $paper_name (no main.tex)"
        return 1
    fi

    echo -n "  $paper_name ... "
    cd "$paper_dir"

    if latexmk -pdf -synctex=1 -interaction=nonstopmode main.tex > /dev/null 2>&1; then
        echo "[OK]"
        result=0
    else
        echo "[FAIL]"
        result=1
    fi

    cd - > /dev/null
    return $result
}

build_paper_all_versions() {
    local paper_dir="$1"
    local paper_name=$(basename "$paper_dir")
    local versions_dir="$paper_dir/versions"
    
    if [ ! -d "$versions_dir" ]; then
        return 0
    fi
    
    local versions=($(ls -1 "$versions_dir" 2>/dev/null))
    if [ ${#versions[@]} -eq 0 ]; then
        return 0
    fi
    
    echo "  Versions:"
    for version in "${versions[@]}"; do
        build_paper "$versions_dir/$version"
    done
}

if [ "$#" -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    # Show help by default
    usage

elif [ "$1" = "--all" ]; then
    # Build all papers
    echo "Building all papers..."
    echo ""

    for paper_dir in "$PAPERS_DIR"/*/; do
        paper_name=$(basename "$paper_dir")
        echo "Paper: $paper_name"
        
        # Build main if exists
        if [ -f "$paper_dir/main.tex" ]; then
            build_paper "$paper_dir"
        fi
        
        # Build all versions
        build_paper_all_versions "$paper_dir"
        echo ""
    done

    echo "Done!"

else
    # Build specific paper or version
    paper_path="$1"
    build_mode="${2:-main}"  # default to 'main' if not specified
    
    # Check if it's a version path (contains /)
    if [[ "$paper_path" == *"/"* ]]; then
        # It's a specific version - format is PAPER/VERSION
        # Need to construct as PAPER/versions/VERSION
        paper_name="${paper_path%/*}"  # get paper name (before /)
        version_name="${paper_path#*/}"  # get version name (after /)
        paper_dir="$PAPERS_DIR/$paper_name/versions/$version_name"
        
        if [ ! -d "$paper_dir" ]; then
            echo "Error: Version '$paper_path' not found at $paper_dir"
            exit 1
        fi
        
        echo "Building $paper_path..."
        echo ""
        build_paper "$paper_dir"
        
        if [ $? -eq 0 ]; then
            echo ""
            echo "Done!"
            exit 0
        else
            exit 1
        fi
    else
        # It's a paper name
        paper_dir="$PAPERS_DIR/$paper_path"
        
        if [ ! -d "$paper_dir" ]; then
            echo "Error: Paper '$paper_path' not found in $PAPERS_DIR"
            exit 1
        fi
        
        if [ "$build_mode" = "all" ]; then
            # Build all versions
            echo "Building all versions of $paper_path..."
            echo ""
            build_paper_all_versions "$paper_dir"
            echo ""
            echo "Done!"
            exit 0
        else
            # Build main only (default)
            if [ ! -f "$paper_dir/main.tex" ]; then
                echo "Error: main.tex not found in $paper_path"
                exit 1
            fi
            
            echo "Building $paper_path (main only)..."
            echo ""
            build_paper "$paper_dir"
            
            if [ $? -eq 0 ]; then
                echo ""
                echo "Done!"
                exit 0
            else
                exit 1
            fi
        fi
    fi
fi

