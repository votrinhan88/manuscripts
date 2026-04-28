#!/bin/bash
# Main TUI for manuscripts tools

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
PAPERS_DIR="$REPO_DIR/papers"

# Helper function to get array of papers
list_papers() {
    "$SCRIPT_DIR/list-papers.sh"
}

# Helper function to get array of versions for a paper
list_versions() {
    local paper="$1"
    "$SCRIPT_DIR/list-versions.sh" "$paper" 2>/dev/null
}

# Interactive selection menu with arrow keys
select_option() {
    local prompt="$1"
    shift
    local options=()
    
    # Handle both array arguments and piped input
    if [ $# -gt 0 ]; then
        options=("$@")
    else
        # Read from stdin line by line
        while IFS= read -r line; do
            [ -n "$line" ] && options+=("$line")
        done
    fi
    
    if [ ${#options[@]} -eq 0 ]; then
        echo "No options available" >&2
        return 1
    fi
    
    if [ ${#options[@]} -eq 1 ]; then
        echo "${options[0]}"
        return 0
    fi
    
    # Check if fzf is available for better UX
    if command -v fzf &> /dev/null; then
        local result=$(printf '%s\n' "${options[@]}" | fzf --height 10 --border --prompt "$prompt: " 2>&1)
        if [ -n "$result" ]; then
            echo "$result"
            return 0
        else
            return 1
        fi
    fi
    
    # Fallback: simple numbered menu (works better with pipes)
    echo "" >&2
    echo "$prompt" >&2
    local i=1
    for opt in "${options[@]}"; do
        echo "$i) $opt" >&2
        ((i++))
    done
    echo "$((i))) Cancel" >&2
    echo "" >&2
    
    # Read from /dev/tty to handle piped input
    read -p "Choose [1-$((i-1))]: " choice < /dev/tty
    
    if [ "$choice" -ge 1 ] 2>/dev/null && [ "$choice" -lt "$i" ] 2>/dev/null; then
        echo "${options[$((choice-1))]}"
        return 0
    else
        return 1
    fi
}

show_menu() {
    clear
    echo "========================================"
    echo "  Manuscripts Tools"
    echo "========================================"
    echo ""
    echo "1. Create new paper"
    echo "2. Create new version"
    echo "3. Build papers"
    echo "4. Clean LaTeX files"
    echo "5. Check bibliography"
    echo "6. Exit"
    echo ""
    echo "========================================"
}

build_menu() {
    clear
    echo "========================================"
    echo "  Build Papers"
    echo "========================================"
    echo ""
    echo "1. Build all papers"
    echo "2. Build specific paper (all versions)"
    echo "3. Build specific paper (main only)"
    echo "4. Build specific version"
    echo "5. Back to main menu"
    echo ""
    echo "========================================"
}

check_menu() {
    clear
    echo "========================================"
    echo "  Check Bibliography"
    echo "========================================"
    echo ""
    echo "1. Select reference bib"
    echo "2. Back to main menu"
    echo ""
    echo "========================================"
}

bib_source_menu() {
    clear
    echo "========================================"
    echo "  Select Reference Bibliography"
    echo "========================================"
    echo ""
    echo "1. Global (papers/references.bib - check all papers)"
    echo "2. Paper (specific paper's references.bib - check paper/versions)"
    echo "3. Version (specific version's references.bib - check version only)"
    echo "4. Back"
    echo ""
    echo "========================================"
}

bib_target_menu() {
    clear
    echo "========================================"
    echo "  Select Target to Check"
    echo "========================================"
    echo ""
    echo "1. Check all versions"
    echo "2. Check main paper only"
    echo "3. Check specific version"
    echo "4. Back"
    echo ""
    echo "========================================"
}

new_paper() {
    echo ""
    echo "Current papers:"
    "$SCRIPT_DIR/list-papers.sh" | sed 's/^/  - /'
    echo ""
    read -p "Paper name (YYYY-topic): " paper_name
    if [ -z "$paper_name" ]; then
        echo "Error: Paper name required"
        read -p "Press enter to continue..."
        return
    fi
    "$SCRIPT_DIR/new-paper.sh" --paper="$paper_name"
    read -p "Press enter to continue..."
}

new_version() {
    local paper=$("$SCRIPT_DIR/list-papers.sh" | select_option "Select paper:")
    if [ $? -ne 0 ] || [ -z "$paper" ]; then
        return
    fi
    
    read -p "Version name (arxiv, conf2026, etc.): " version_name
    if [ -z "$version_name" ]; then
        echo "Error: Version name required"
        read -p "Press enter to continue..."
        return
    fi
    
    read -p "Overwrite if exists? (y/n): " overwrite
    if [ "$overwrite" = "y" ] || [ "$overwrite" = "Y" ]; then
        "$SCRIPT_DIR/new-version.sh" --paper="$paper" --version="$version_name" --force
    else
        "$SCRIPT_DIR/new-version.sh" --paper="$paper" --version="$version_name"
    fi
    read -p "Press enter to continue..."
}

build_submenu() {
    while true; do
        build_menu
        read -p "Choose option: " choice

        case $choice in
            1)
                "$SCRIPT_DIR/build-paper.sh" --all
                read -p "Press enter to continue..."
                ;;
            2)
                local paper=$("$SCRIPT_DIR/list-papers.sh" | select_option "Select paper to build (all versions):")
                if [ $? -eq 0 ] && [ -n "$paper" ]; then
                    "$SCRIPT_DIR/build-paper.sh" "$paper" all
                fi
                read -p "Press enter to continue..."
                ;;
            3)
                local paper=$("$SCRIPT_DIR/list-papers.sh" | select_option "Select paper to build (main only):")
                if [ $? -eq 0 ] && [ -n "$paper" ]; then
                    "$SCRIPT_DIR/build-paper.sh" "$paper" main
                fi
                read -p "Press enter to continue..."
                ;;
            4)
                local paper=$("$SCRIPT_DIR/list-papers.sh" | select_option "Select paper:")
                if [ $? -ne 0 ] || [ -z "$paper" ]; then
                    read -p "Press enter to continue..."
                    continue
                fi
                
                local version=$("$SCRIPT_DIR/list-versions.sh" "$paper" | select_option "Select version:")
                if [ $? -eq 0 ] && [ -n "$version" ]; then
                    "$SCRIPT_DIR/build-paper.sh" "$paper/$version"
                fi
                read -p "Press enter to continue..."
                ;;
            5)
                return
                ;;
            *)
                echo "Invalid option"
                read -p "Press enter to continue..."
                ;;
        esac
    done
}

clean_files() {
    read -p "Clean LaTeX temporary files in current directory? (y/n): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        "$SCRIPT_DIR/clean.sh"
        echo "Done!"
    fi
    read -p "Press enter to continue..."
}

check_submenu() {
    # Phase 1: Select reference bibliography
    local ref_bib=""
    local ref_folder=""
    local check_target=""
    local target_paper=""
    
    while true; do
        bib_source_menu
        read -p "Choose option: " choice

        case $choice in
            1)
                # Global bib
                ref_bib="$REPO_DIR/papers/references.bib"
                ref_folder="$REPO_DIR/papers"

                if [ ! -f "$ref_bib" ]; then
                    echo "Error: Global references.bib not found at $ref_bib"
                    read -p "Press enter to continue..."
                    continue
                fi
                check_target="global"
                
                # For global bib, ask which paper to check
                target_paper=$("$SCRIPT_DIR/list-papers.sh" | select_option "Select paper to check:")
                if [ $? -ne 0 ] || [ -z "$target_paper" ]; then
                    read -p "Press enter to continue..."
                    continue
                fi
                target_paper=$(echo "$target_paper" | tr '\\' '/')
                break
                ;;
            2)
                # Paper bib
                local paper=$("$SCRIPT_DIR/list-papers.sh" | select_option "Select paper:")
                if [ $? -ne 0 ] || [ -z "$paper" ]; then
                    read -p "Press enter to continue..."
                    continue
                fi
                
                ref_bib="$PAPERS_DIR/$paper/references.bib"
                ref_folder="$PAPERS_DIR/$paper"
                
                if [ ! -f "$ref_bib" ]; then
                    echo "Error: references.bib not found for paper $paper"
                    read -p "Press enter to continue..."
                    continue
                fi
                check_target="paper:$paper"
                target_paper=$(echo "$paper" | tr '\\' '/')
                break
                ;;
            3)
                # Specific version bib - check that version directly
                local paper=$("$SCRIPT_DIR/list-papers.sh" | select_option "Select paper:")
                if [ $? -ne 0 ] || [ -z "$paper" ]; then
                    read -p "Press enter to continue..."
                    continue
                fi
                
                local versions=$("$SCRIPT_DIR/list-versions.sh" "$paper" 2>/dev/null)
                if [ $? -ne 0 ] || [ -z "$versions" ]; then
                    echo "Error: No versions found for $paper"
                    read -p "Press enter to continue..."
                    continue
                fi
                
                local version=$(echo "$versions" | select_option "Select version:")
                if [ $? -ne 0 ] || [ -z "$version" ]; then
                    read -p "Press enter to continue..."
                    continue
                fi
                
                ref_bib="$PAPERS_DIR/$paper/versions/$version/references.bib"
                ref_folder="$PAPERS_DIR/$paper/versions/$version"
                
                if [ ! -f "$ref_bib" ]; then
                    echo "Error: references.bib not found for version $version"
                    read -p "Press enter to continue..."
                    continue
                fi
                
                # Check this specific version directly
                local paper_path="$paper/versions/$version"
                local paper_path=$(echo "$paper_path" | tr '\\' '/')
                local tex_folder="$PAPERS_DIR/$paper_path"
                
                echo ""
                echo "Checking bibliography for: $paper_path"
                echo "Using bib: $ref_bib"
                echo "This may take a moment..."
                echo ""
                bash "$SCRIPT_DIR/bib_checker.sh" -b "$ref_bib" -t "$tex_folder"
                read -p "Press enter to continue..."
                return
                ;;
            4)
                return
                ;;
            *)
                echo "Invalid option"
                read -p "Press enter to continue..."
                ;;
        esac
    done
    
    # Phase 2: Select target scope (all versions, main only, or specific version)
    echo ""
    echo "Using bib: $ref_bib"
    echo "Paper: $target_paper"
    echo ""
    
    while true; do
        bib_target_menu
        read -p "Choose option: " choice

        case $choice in
            1)
                # Check all versions
                local check_folder="$PAPERS_DIR/$target_paper"
                
                echo ""
                echo "Checking all versions of: $target_paper"
                echo "Using bib: $ref_bib"
                echo "This may take a moment..."
                echo ""
                bash "$SCRIPT_DIR/bib_checker.sh" -b "$ref_bib" -t "$check_folder"
                read -p "Press enter to continue..."
                ;;
            2)
                # Check main paper only
                local tex_folder="$PAPERS_DIR/$target_paper"
                
                echo ""
                echo "Checking main paper: $target_paper"
                echo "Using bib: $ref_bib"
                echo "This may take a moment..."
                echo ""
                bash "$SCRIPT_DIR/bib_checker.sh" -b "$ref_bib" -t "$tex_folder"
                read -p "Press enter to continue..."
                ;;
            3)
                # Check specific version
                local versions=$("$SCRIPT_DIR/list-versions.sh" "$target_paper" 2>/dev/null)
                if [ $? -ne 0 ] || [ -z "$versions" ]; then
                    echo "Error: No versions found for $target_paper"
                    read -p "Press enter to continue..."
                    continue
                fi
                
                local version=$(echo "$versions" | select_option "Select version:")
                if [ $? -ne 0 ] || [ -z "$version" ]; then
                    read -p "Press enter to continue..."
                    continue
                fi
                
                local paper_path="$target_paper/versions/$version"
                local paper_path=$(echo "$paper_path" | tr '\\' '/')
                local tex_folder="$PAPERS_DIR/$paper_path"
                
                echo ""
                echo "Checking: $paper_path"
                echo "Using bib: $ref_bib"
                echo "This may take a moment..."
                echo ""
                bash "$SCRIPT_DIR/bib_checker.sh" -b "$ref_bib" -t "$tex_folder"
                read -p "Press enter to continue..."
                ;;
            4)
                return
                ;;
            *)
                echo "Invalid option"
                read -p "Press enter to continue..."
                ;;
        esac
    done
}

while true; do
    show_menu
    read -p "Choose option: " choice

    case $choice in
        1)
            new_paper
            ;;
        2)
            new_version
            ;;
        3)
            build_submenu
            ;;
        4)
            clean_files
            ;;
        5)
            check_submenu
            ;;
        6)
            echo "Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid option"
            read -p "Press enter to continue..."
            ;;
    esac
done
