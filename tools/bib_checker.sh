#!/bin/bash

# Script to check which references in a .bib file are used in .tex files
# Usage: ./bib_checker.sh --bib path/to/file.bib --tex path/to/tex/folder [--syntax \cite]


# Default values
BIB_FILE=""
TEX_FOLDER=""
SYNTAX=""  # Empty means scan for all citation commands
SHALLOW=0  # If 1, only scan top-level .tex files (no recursion into subdirs)

# Function to display help
show_help() {
    cat << EOF
Usage: $0 --bib <file.bib> --tex <folder> [--syntax <citation_syntax>]

Options:
  --bib, -b          Path to .bib file (required)
  --tex, -t          Path to folder containing .tex files (required)
  --syntax, -s       Citation syntax to search for (optional, default: all)
                     Examples: cite, citet, citep (no backslash needed!)
                     If not specified, scans for all citation commands
  --help, -h         Show this help message

Example:
  $0 --bib references.bib --tex .
  $0 --bib references.bib --tex . --syntax citep

EOF
}

# Function to validate and normalize syntax
normalize_syntax() {
    local syntax=$1
    # Remove leading backslash if present
    syntax="${syntax#\\}"
    # Check if syntax looks like a LaTeX command (alphabetic chars only)
    if ! [[ "$syntax" =~ ^[a-z]+\*?$ ]]; then
        echo "Error: Invalid citation syntax: $syntax"
        echo "Expected format: cite, citet, citep, citealp, etc."
        echo ""
        show_help
        exit 1
    fi
    # Return with backslash added
    echo "\\$syntax"
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --bib|-b)
            BIB_FILE="$2"
            shift 2
            ;;
        --tex|-t)
            TEX_FOLDER="$2"
            shift 2
            ;;
        --syntax|-s)
            SYNTAX="$2"
            shift 2
            ;;
        --shallow)
            SHALLOW=1
            shift
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo ""
            show_help
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ -z "$BIB_FILE" ]]; then
    echo "Error: --bib file path is required"
    echo ""
    show_help
    exit 1
fi

if [[ -z "$TEX_FOLDER" ]]; then
    echo "Error: --tex folder path is required"
    echo ""
    show_help
    exit 1
fi

# Validate syntax format
if [[ -n "$SYNTAX" ]]; then
    SYNTAX=$(normalize_syntax "$SYNTAX")
fi

if [[ ! -f "$BIB_FILE" ]]; then
    echo "Error: .bib file not found: $BIB_FILE"
    exit 1
fi

if [[ ! -d "$TEX_FOLDER" ]]; then
    echo "Error: tex folder not found: $TEX_FOLDER"
    exit 1
fi

# Extract all citation keys from the .bib file
# Keys are in format: @type{key,
echo "Scanning .bib file: $BIB_FILE"
echo "Tex folder: $TEX_FOLDER"
if [[ -z "$SYNTAX" ]]; then
    echo "Citation syntax: All (\cite, \citet, \citep, \citealp, etc.)"
else
    echo "Citation syntax: $SYNTAX"
fi
echo "---"
# Find all .tex files
if [[ "$SHALLOW" -eq 1 ]]; then
    TEX_FILES=$(find "$TEX_FOLDER" -maxdepth 1 -name "*.tex" -type f)
else
    TEX_FILES=$(find "$TEX_FOLDER" -name "*.tex" -type f)
fi
TEX_FILE_COUNT=$(echo "$TEX_FILES" | wc -l)

echo "Found $TEX_FILE_COUNT .tex file(s) to scan:"
echo "$TEX_FILES" | sed 's/^/  /'
echo "---"
# Create temporary files for results
TEMP_USED=$(mktemp)
TEMP_UNUSED=$(mktemp)
TEMP_COUNTS=$(mktemp)

# Extract citation keys from .bib file
# Look for lines like: @article{key,
BIB_KEYS=$(grep "^@" "$BIB_FILE" | sed 's/^@[^{]*{\([^,]*\),.*/\1/' | sort -u)

if [[ -z "$BIB_KEYS" ]]; then
    echo "No citation keys found in .bib file"
    exit 0
fi

TOTAL_KEYS=$(echo "$BIB_KEYS" | wc -l)
USED_COUNT=0
UNUSED_COUNT=0

echo "Total citations in .bib: $TOTAL_KEYS"
echo ""
echo "Processing citations..."
echo ""

# Check each citation key and count occurrences
count_processed=0
for key in $BIB_KEYS; do
    if [[ -n "$SYNTAX" ]]; then
        # Search for specific syntax with the key: e.g., \cite{...key...}
        MATCHES=$(grep -r "${SYNTAX}{[^}]*${key}" "$TEX_FOLDER" 2>/dev/null || echo "")
    else
        # Search for any citation command (\cite, \citet, \citep, etc) with the key
        # Simple pattern: look for \cite followed by { and containing the key
        MATCHES=$(grep -r "\\\\cite[a-z*]*.*{[^}]*${key}" "$TEX_FOLDER" 2>/dev/null || echo "")
    fi
    
    if [[ -n "$MATCHES" ]]; then
        # Count lines with matches (more reliable than counting occurrences)
        COUNT=$(echo "$MATCHES" | wc -l)
        echo "$COUNT $key" >> "$TEMP_COUNTS"
        ((USED_COUNT++))
        echo "$key" >> "$TEMP_USED"
    else
        ((UNUSED_COUNT++))
        echo "$key" >> "$TEMP_UNUSED"
    fi
    ((count_processed++))
done

echo "Processed $count_processed citations"
echo ""

echo "---"
echo "Summary:"
echo "  Used:   $USED_COUNT / $TOTAL_KEYS"
echo "  Unused: $UNUSED_COUNT / $TOTAL_KEYS"
echo ""

# Show top 10 most cited references
if [[ -s "$TEMP_COUNTS" ]]; then
    echo "Top 10 most cited references:"
    sort -rn "$TEMP_COUNTS" | head -10 | while read count key; do
        echo "  [$count citations] $key"
    done
    echo ""
fi

# Show unused citations
if [[ -s "$TEMP_UNUSED" ]]; then
    echo "Unused citations (${UNUSED_COUNT} total):"
    cat "$TEMP_UNUSED" | sed 's/^/  /'
fi

# Cleanup
rm -f "$TEMP_USED" "$TEMP_UNUSED" "$TEMP_COUNTS"
