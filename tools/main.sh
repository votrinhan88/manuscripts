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
    # Phase 1: Select paper
    local paper
    paper=$("$SCRIPT_DIR/list-papers.sh" | select_option "Select paper:")
    if [ $? -ne 0 ] || [ -z "$paper" ]; then
        return
    fi
    paper=$(echo "$paper" | tr '\\' '/')

    # Phase 2: Select target (what tex files to scan)
    local tex_folder=""
    local target_label=""

    while true; do
        bib_target_menu
        read -p "Choose option: " choice

        case $choice in
            1)
                tex_folder="$PAPERS_DIR/$paper"
                target_label="all versions of $paper"
                break
                ;;
            2)
                tex_folder="$PAPERS_DIR/$paper"
                target_label="main paper only: $paper"
                break
                ;;
            3)
                local versions
                versions=$("$SCRIPT_DIR/list-versions.sh" "$paper" 2>/dev/null)
                if [ -z "$versions" ]; then
                    echo "Error: No versions found for $paper"
                    read -p "Press enter to continue..."
                    continue
                fi
                local version
                version=$(echo "$versions" | select_option "Select version:")
                if [ -z "$version" ]; then
                    read -p "Press enter to continue..."
                    continue
                fi
                tex_folder="$PAPERS_DIR/$paper/versions/$version"
                target_label="$paper/versions/$version"
                break
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

    # Phase 3: Select bib — show only bibs that exist
    local bib_options=()
    local bib_paths=()

    local global_bib="$REPO_DIR/papers/references.bib"
    local paper_bib="$PAPERS_DIR/$paper/references.bib"

    [ -f "$global_bib" ] && bib_options+=("Global  ($global_bib)") && bib_paths+=("$global_bib")
    [ -f "$paper_bib"  ] && bib_options+=("Paper   ($paper_bib)")  && bib_paths+=("$paper_bib")

    # Version bib only available when checking a specific version
    if [[ "$choice" == "3" ]]; then
        local version_bib="$tex_folder/references.bib"
        [ -f "$version_bib" ] && bib_options+=("Version ($version_bib)") && bib_paths+=("$version_bib")
    fi

    if [ ${#bib_options[@]} -eq 0 ]; then
        echo "Error: No references.bib found"
        read -p "Press enter to continue..."
        return
    fi

    local selected_bib_label
    selected_bib_label=$(printf '%s\n' "${bib_options[@]}" | select_option "Select bibliography:")
    if [ -z "$selected_bib_label" ]; then
        return
    fi

    # Resolve selected label back to path
    local ref_bib=""
    for i in "${!bib_options[@]}"; do
        if [ "${bib_options[$i]}" = "$selected_bib_label" ]; then
            ref_bib="${bib_paths[$i]}"
            break
        fi
    done

    if [ -z "$ref_bib" ]; then
        echo "Error: Could not resolve bib path"
        read -p "Press enter to continue..."
        return
    fi

    # Run
    local shallow_flag=""
    [[ "$choice" == "2" ]] && shallow_flag="--shallow"

    echo ""
    echo "Checking: $target_label"
    echo "Using bib: $ref_bib"
    echo "This may take a moment..."
    echo ""
    bash "$SCRIPT_DIR/bib_checker.sh" -b "$ref_bib" -t "$tex_folder" $shallow_flag
    read -p "Press enter to continue..."
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
