#!/bin/bash

# Strict error handling
set -euo pipefail

# Configuration des couleurs
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# Script version
readonly SCRIPT_VERSION="2.1.0"

# Fonction d'aide étendue
show_help() {
    echo -e "${YELLOW}Git Push Assistant v${SCRIPT_VERSION}${NC}"
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 [OPTIONS] <commit_message>"
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help       Show this help message and exit"
    echo "  -v, --version    Show version information"
    echo "  -f, --force      Force push without confirmation"
    echo "  -b, --branch     Specify a particular branch"
    echo "  -r, --remote     Specify remote (default: origin)"
    echo "  -s, --select     Interactive file selection mode"
    echo "  -d, --dry-run    Show what would be done without executing"
    echo "  --uncommit       Undo the last commit (keep changes)"
    echo "  --remove-file    Remove a file from the last commit"
    echo "  --check-deps     Check and install dependencies"
    echo -e "\n${YELLOW}Examples:${NC}"
    echo "  $0 'My commit message' -s"
    echo "  $0 'Hotfix' -b hotfix -r upstream"
    echo "  $0 --uncommit"
    echo "  $0 --remove-file"
    echo "  $0 --dry-run 'Test commit'"
    exit 0
}

# Détection du système d'exploitation
detect_os() {
    local os_name=""
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        os_name="macOS"
    elif [[ -f /etc/os-release ]]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        os_name="$NAME"
    elif command -v lsb_release >/dev/null 2>&1; then
        os_name=$(lsb_release -si)
    elif [[ -f /etc/lsb-release ]]; then
        # shellcheck disable=SC1091
        . /etc/lsb-release
        os_name="$DISTRIB_ID"
    elif [[ -f /etc/debian_version ]]; then
        os_name="Debian"
    elif [[ -f /etc/redhat-release ]]; then
        os_name=$(cut -d ' ' -f 1 /etc/redhat-release)
    else
        os_name=$(uname -s)
    fi
    
    echo "$os_name"
}

# Installation de fzf en fonction du système d'exploitation
install_fzf() {
    local os_name
    os_name=$(detect_os)
    
    echo -e "${YELLOW}Installing fzf for ${os_name}...${NC}"
    
    # Check for Homebrew first (works on macOS and Linux)
    if command -v brew >/dev/null 2>&1; then
        brew install fzf
        return 0
    fi
    
    case "$os_name" in
        "Ubuntu"|"Debian"|"Linux Mint"|*"buntu"*)
            sudo apt update && sudo apt install -y fzf
            ;;
        "Fedora"|"Fedora Linux")
            sudo dnf install -y fzf
            ;;
        "CentOS"*|"Red Hat"*|"Rocky Linux"|"AlmaLinux")
            # Try dnf first (newer versions), fallback to yum
            if command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y fzf
            else
                sudo yum install -y fzf
            fi
            ;;
        "Arch Linux"|"Manjaro"*|"EndeavourOS"|"Garuda Linux")
            sudo pacman -S --noconfirm fzf
            ;;
        "openSUSE"*|"SUSE"*)
            sudo zypper install -y fzf
            ;;
        "Alpine"*)
            sudo apk add fzf
            ;;
        "macOS")
            echo -e "${RED}Homebrew not found. Please install Homebrew first:${NC}"
            echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            exit 1
            ;;
        *)
            echo -e "${RED}Unsupported operating system: ${os_name}${NC}"
            echo -e "${YELLOW}Please install fzf manually:${NC}"
            echo "  - Debian/Ubuntu: apt install fzf"
            echo "  - Fedora: dnf install fzf"  
            echo "  - Arch: pacman -S fzf"
            echo "  - macOS: brew install fzf"
            echo "  - Or compile from source: https://github.com/junegunn/fzf"
            exit 1
            ;;
    esac
}

# Vérification des dépendances
check_dependencies() {
    local missing_deps=()
    
    # Check for required commands
    if ! command -v git >/dev/null 2>&1; then
        missing_deps+=("git")
    fi
    
    if ! command -v fzf >/dev/null 2>&1; then
        missing_deps+=("fzf")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${RED}Missing dependencies: ${missing_deps[*]}${NC}"
        
        if [[ " ${missing_deps[*]} " =~ " git " ]]; then
            echo -e "${YELLOW}Git is required and must be installed manually.${NC}"
            exit 1
        fi
        
        if [[ " ${missing_deps[*]} " =~ " fzf " ]]; then
            echo -e "${YELLOW}fzf is required for interactive file selection.${NC}"
            read -p "Install fzf automatically? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                install_fzf
                echo -e "${GREEN}✓ fzf installed successfully${NC}"
            else
                echo -e "${RED}Cannot continue without fzf${NC}"
                exit 1
            fi
        fi
    fi
}

# Vérification du dépôt Git
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "${RED}Error: This directory is not a Git repository!${NC}"
        echo -e "${YELLOW}Initialize a Git repository with: git init${NC}"
        exit 1
    fi
    
    # Check if there are any commits
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo -e "${RED}Error: No commits found in this repository!${NC}"
        echo -e "${YELLOW}Make an initial commit first.${NC}"
        exit 1
    fi
}

# Validation de la branche
validate_branch() {
    local branch="$1"
    local remote="${2:-origin}"
    
    # Check if branch exists locally
    if ! git show-ref --verify --quiet "refs/heads/$branch"; then
        echo -e "${YELLOW}Branch '$branch' does not exist locally.${NC}"
        read -p "Create new branch '$branch'? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git checkout -b "$branch"
            echo -e "${GREEN}✓ Created and switched to branch '$branch'${NC}"
        else
            exit 1
        fi
    fi
    
    # Check if remote exists
    if ! git remote get-url "$remote" >/dev/null 2>&1; then
        echo -e "${RED}Error: Remote '$remote' does not exist!${NC}"
        echo -e "${YELLOW}Available remotes:${NC}"
        git remote -v
        exit 1
    fi
}

# Sélection interactive des fichiers
select_files() {
    echo -e "${CYAN}Interactive file selection mode${NC}"
    
    # Check if there are any changes
    if ! git status --porcelain | grep -q .; then
        echo -e "${YELLOW}No changes detected in the repository.${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}Select files to stage (Tab for multi-selection, Enter to confirm):${NC}"
    
    local files
    files=$(git -c color.status=always status --short | \
        fzf --ansi --multi --height 60% --reverse \
        --preview 'if [[ {1} == "??" ]]; then bat --color=always --style=numbers --line-range=:50 {2} 2>/dev/null || cat {2} 2>/dev/null || echo "Binary file or preview unavailable"; else git diff --color=always -- {2} 2>/dev/null || echo "No diff available"; fi' \
        --preview-window=right:50% \
        --header "↓↑ navigate | Tab multi-select | Enter confirm | Ctrl-C cancel" \
        --bind 'ctrl-d:preview-page-down,ctrl-u:preview-page-up' | \
        awk '{print $2}')
    
    if [[ -n "$files" ]]; then
        echo -e "${BLUE}Selected files for staging:${NC}"
        while IFS= read -r file; do
            echo -e "  ${GREEN}✓ $file${NC}"
        done <<< "$files"
        
        # Add files to staging area
        echo "$files" | xargs git add
        echo -e "${GREEN}✓ Files staged successfully${NC}"
    else
        echo -e "${RED}No files selected. Exiting.${NC}"
        exit 1
    fi
}

# Annulation du dernier commit
uncommit() {
    echo -e "${YELLOW}Undoing the last commit...${NC}"
    
    # Check if there are commits to undo
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo -e "${RED}No commits to undo!${NC}"
        exit 1
    fi
    
    # Show what will be undone
    echo -e "${BLUE}Last commit to be undone:${NC}"
    git --no-pager log -1 --oneline --color=always
    
    read -p "Confirm uncommit? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git reset --soft HEAD~1
        echo -e "${GREEN}✓ Last commit undone (changes preserved in staging area)${NC}"
        echo -e "${YELLOW}Files now staged:${NC}"
        git --no-pager diff --cached --name-only | sed 's/^/  /'
    else
        echo -e "${YELLOW}Uncommit cancelled${NC}"
    fi
    exit 0
}

# Retrait d'un fichier d'un commit
remove_file() {
    echo -e "${CYAN}Remove file from last commit${NC}"
    
    # Check if there are commits
    if ! git rev-parse --verify HEAD >/dev/null 2>&1; then
        echo -e "${RED}No commits found!${NC}"
        exit 1
    fi
    
    # Get files from the last commit
    local files_in_commit
    files_in_commit=$(git show --name-only --pretty=format: HEAD)
    
    if [[ -z "$files_in_commit" ]]; then
        echo -e "${RED}No files in the last commit!${NC}"
        exit 1
    fi
    
    echo -e "${YELLOW}Select file(s) to remove from the last commit:${NC}"
    local files_to_remove
    files_to_remove=$(echo "$files_in_commit" | \
        fzf --multi --height 40% --reverse \
        --preview 'git show --color=always HEAD:{1}' \
        --header "Select files to remove | Tab for multi-select | Enter to confirm")
    
    if [[ -n "$files_to_remove" ]]; then
        local commit_message
        commit_message=$(git log -1 --pretty=%B)
        
        echo -e "${BLUE}Files to remove:${NC}"
        while IFS= read -r file; do
            echo -e "  ${RED}- $file${NC}"
        done <<< "$files_to_remove"
        
        read -p "Confirm removal? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            # Reset to previous commit
            git reset --soft HEAD~1
            
            # Remove selected files from staging
            while IFS= read -r file; do
                git restore --staged "$file" 2>/dev/null || true
            done <<< "$files_to_remove"
            
            # Re-commit with the same message
            if git diff --cached --quiet; then
                echo -e "${YELLOW}All files removed - no commit created${NC}"
            else
                git commit -m "$commit_message"
                echo -e "${GREEN}✓ Commit updated successfully${NC}"
            fi
        else
            echo -e "${YELLOW}Operation cancelled${NC}"
        fi
    else
        echo -e "${RED}No files selected!${NC}"
    fi
    exit 0
}

# Confirmation avant push
confirm_action() {
    local remote="$1"
    local branch="$2"
    local dry_run="${3:-false}"
    
    if [[ "$FORCE" == "false" && "$dry_run" == "false" ]]; then
        echo -e "${YELLOW}Summary of changes to push:${NC}"
        echo -e "${BLUE}Target: ${remote}/${branch}${NC}"
        
        # Show staged changes if any
        if git diff --cached --quiet; then
            echo -e "${YELLOW}No staged changes${NC}"
        else
            echo -e "${CYAN}Staged changes:${NC}"
            git --no-pager diff --stat --cached
        fi
        
        # Show commits to be pushed
        local commits_ahead
        commits_ahead=$(git rev-list --count "@{u}"..)  2>/dev/null || commits_ahead="unknown"
        
        if [[ "$commits_ahead" != "0" && "$commits_ahead" != "unknown" ]]; then
            echo -e "${CYAN}Commits to push ($commits_ahead):${NC}"
            git --no-pager log --oneline "@{u}".."@" 2>/dev/null || echo "  Cannot determine commits ahead"
        fi
        
        echo
        read -p "Confirm push to ${remote}/${branch}? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${RED}Push cancelled by user${NC}"
            exit 0
        fi
    elif [[ "$dry_run" == "true" ]]; then
        echo -e "${YELLOW}DRY RUN - No changes will be made${NC}"
        echo -e "${BLUE}Would push to: ${remote}/${branch}${NC}"
        if ! git diff --cached --quiet; then
            echo -e "${CYAN}Would stage and commit:${NC}"
            git --no-pager diff --stat --cached
        fi
    fi
}

# Show version information
show_version() {
    echo -e "${YELLOW}Git Push Assistant${NC}"
    echo -e "Version: ${GREEN}${SCRIPT_VERSION}${NC}"
    echo -e "Author: Updated script with modern features"
    echo -e "Repository: Enhanced with better error handling and UX"
    exit 0
}

# Check dependencies only (for --check-deps option)
check_deps_only() {
    echo -e "${YELLOW}Checking dependencies...${NC}"
    check_dependencies
    echo -e "${GREEN}✓ All dependencies satisfied${NC}"
    exit 0
}

# Workflow principal
main() {
    # Initialize variables
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    local remote="origin"
    local force=false
    local select_mode=false
    local dry_run=false
    local message=""
    local target_branch="$current_branch"

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -v|--version)
                show_version
                ;;
            --check-deps)
                check_deps_only
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -b|--branch)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo -e "${RED}Error: --branch requires a branch name${NC}"
                    exit 1
                fi
                target_branch="$2"
                shift 2
                ;;
            -r|--remote)
                if [[ -z "$2" || "$2" == -* ]]; then
                    echo -e "${RED}Error: --remote requires a remote name${NC}"
                    exit 1
                fi
                remote="$2"
                shift 2
                ;;
            -s|--select)
                select_mode=true
                shift
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            --uncommit)
                check_git_repo
                uncommit
                ;;
            --remove-file)
                check_git_repo
                remove_file
                ;;
            -*)
                echo -e "${RED}Unknown option: $1${NC}"
                echo -e "${YELLOW}Use --help for usage information${NC}"
                exit 1
                ;;
            *)
                if [[ -z "$message" ]]; then
                    message="$1"
                else
                    echo -e "${RED}Error: Multiple commit messages provided${NC}"
                    echo -e "${YELLOW}Wrap your message in quotes if it contains spaces${NC}"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Set global variables for other functions
    FORCE="$force"

    # Dependency and repository checks
    if [[ "$select_mode" == true ]]; then
        check_dependencies
    fi
    check_git_repo

    # Validate branch and remote
    validate_branch "$target_branch" "$remote"

    # Switch to target branch if different from current
    if [[ "$target_branch" != "$current_branch" ]]; then
        echo -e "${YELLOW}Switching to branch '$target_branch'${NC}"
        git checkout "$target_branch"
    fi

    # Handle file selection
    if [[ "$select_mode" == true ]]; then
        select_files
        # Ask for commit message after file selection if not provided
        if [[ -z "$message" ]]; then
            read -p "${CYAN}Enter commit message: ${NC}" message
            if [[ -z "$message" ]]; then
                echo -e "${RED}Error: Commit message is required${NC}"
                exit 1
            fi
        fi
    else
        # Check if there are changes to add
        if git status --porcelain | grep -q .; then
            echo -e "${GREEN}Adding all changes...${NC}"
            git add .
        else
            echo -e "${YELLOW}No changes to commit${NC}"
            # Check if there are commits to push
            local commits_ahead
            commits_ahead=$(git rev-list --count "@{u}"..)  2>/dev/null || commits_ahead="0"
            if [[ "$commits_ahead" -gt 0 ]]; then
                echo -e "${BLUE}Found $commits_ahead unpushed commit(s)${NC}"
                confirm_action "$remote" "$target_branch" "$dry_run"
                if [[ "$dry_run" == false ]]; then
                    echo -e "${GREEN}Pushing existing commits to ${BLUE}${remote}/${target_branch}${NC}..."
                    git push "$remote" "$target_branch"
                    echo -e "${GREEN}✓ Push successful!${NC}"
                fi
            else
                echo -e "${YELLOW}Nothing to commit or push${NC}"
            fi
            exit 0
        fi
    fi

    # Validate commit message
    if [[ -z "$message" ]]; then
        echo -e "${RED}Error: Commit message is required${NC}"
        echo -e "${YELLOW}Usage: $0 'your commit message' [options]${NC}"
        exit 1
    fi

    # Show confirmation
    confirm_action "$remote" "$target_branch" "$dry_run"

    # Exit early for dry run
    if [[ "$dry_run" == true ]]; then
        echo -e "${GREEN}✓ Dry run completed${NC}"
        exit 0
    fi

    # Create commit
    echo -e "${GREEN}Creating commit...${NC}"
    if git commit -m "$message"; then
        echo -e "${GREEN}✓ Commit created successfully${NC}"
    else
        echo -e "${RED}Error: Failed to create commit${NC}"
        echo -e "${YELLOW}This might happen if there are no changes to commit${NC}"
        exit 1
    fi

    # Push to remote
    echo -e "${GREEN}Pushing to ${BLUE}${remote}/${target_branch}${NC}..."
    if git push "$remote" "$target_branch"; then
        echo -e "${GREEN}✓ Push completed successfully!${NC}"
        
        # Show summary
        local repo_url
        repo_url=$(git remote get-url "$remote" 2>/dev/null || echo "unknown")
        echo -e "${BLUE}Repository: $repo_url${NC}"
        echo -e "${BLUE}Branch: $target_branch${NC}"
        echo -e "${BLUE}Commit: $(git log -1 --oneline)${NC}"
    else
        echo -e "${RED}Error: Push failed${NC}"
        echo -e "${YELLOW}This might happen if:${NC}"
        echo -e "  • The remote branch has new commits (try: git pull)"
        echo -e "  • You don't have push permissions"
        echo -e "  • The remote repository doesn't exist"
        exit 1
    fi
}

# Execution with error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi