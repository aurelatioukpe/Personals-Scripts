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

# ASCII Art
show_ascii_art() {
    echo -e "${CYAN}"
    echo "    ╔═════════════════════════════════════════════════════════════════╗"
    echo "    ║                                                                 ║"
    echo "    ║    ███████╗ ██████╗ ██████╗ ██████╗ ██████╗ ██╗███████╗███████╗ ║"
    echo "    ║    ██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║╚════██║╚════██║ ║"
    echo "    ║    ███████╗██║     ██║   ██║██████╔╝██████╔╝██║    ██╔╝    ██╔╝ ║"
    echo "    ║    ╚════██║██║     ██║   ██║██╔══██╗██╔═══╝ ██║   ██╔╝    ██╔╝  ║"
    echo "    ║    ███████║╚██████╗╚██████╔╝██║  ██║██║     ██║  ██╔╝    ██╔╝   ║"
    echo "    ║    ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝     ╚═╝    ║"
    echo "    ║                                                                 ║"
    echo "    ║                              ✖                                 ║"
    echo "    ║                                                                 ║"
    echo "    ║    ████████╗██████╗  █████╗ ███████╗███████╗██╗   ██╗          ║"
    echo "    ║    ╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝╚██╗ ██╔╝          ║"
    echo "    ║       ██║   ██████╔╝███████║█████╗  █████╗   ╚████╔╝           ║"
    echo "    ║       ██║   ██╔══██╗██╔══██║██╔══╝  ██╔══╝    ╚██╔╝            ║"
    echo "    ║       ██║   ██║  ██║██║  ██║██║     ██║        ██║             ║"
    echo "    ║       ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝        ╚═╝             ║"
    echo "    ║                                                                 ║"
    echo "    ║                Git Push Assistant v${SCRIPT_VERSION}                    ║"
    echo "    ║                                                                 ║"
    echo "    ╚═════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo
}

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
    echo "  -i, --interactive Start interactive menu mode"
    echo "  -d, --dry-run    Show what would be done without executing"
    echo "  --uncommit       Undo the last commit (keep changes)"
    echo "  --remove-file    Remove a file from the last commit"
    echo "  --check-deps     Check and install dependencies"
    echo -e "\n${YELLOW}Examples:${NC}"
    echo "  $0                              # Interactive menu mode"
    echo "  $0 -i                           # Interactive menu mode"
    echo "  $0 'My commit message' -s       # File selection mode"
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
    echo -e "Author: Scorpi777 X Traffy"
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

# Menu interactif principal
interactive_menu() {
    clear
    show_ascii_art
    check_dependencies
    check_git_repo
    
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
    
    # Configuration par défaut
    local config_remote="origin"
    local config_branch="$current_branch"
    local config_force="false"
    local config_dry_run="false"
    local config_select_files="false"
    
    while true; do
        # Status du repository
        local status_info=""
        local changes_count
        changes_count=$(git status --porcelain 2>/dev/null | wc -l)
        local commits_ahead
        commits_ahead=$(git rev-list --count "@{u}"..) 2>/dev/null || commits_ahead="0"
        
        if [[ $changes_count -gt 0 ]]; then
            status_info="${YELLOW}📝 $changes_count uncommitted changes${NC}"
        elif [[ $commits_ahead -gt 0 ]]; then
            status_info="${BLUE}📤 $commits_ahead unpushed commits${NC}"
        else
            status_info="${GREEN}✓ Repository is clean${NC}"
        fi
        
        # Menu principal
        local menu_options=(
            "🚀 Commit & Push|Standard commit and push workflow"
            "📁 Select Files & Push|Interactive file selection mode"
            "🌿 Branch Management|Create, switch, merge, and delete branches"
            "📜 Commit History|View and interact with commit history"
            "📊 Repository Status|Detailed repository status and information"
            "↩️  Undo Last Commit|Reset last commit (keep changes)"
            "🗑️  Remove File from Commit|Remove specific files from last commit"
            "🔧 Configure Options|Set branch, remote, and other options"
            "❓ Help|Show help and usage information"
            "🚪 Exit|Exit the program"
        )
        
        echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${YELLOW}🔧 Git Push Assistant v${SCRIPT_VERSION}${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo -e "📂 Repository: $(basename "$(git rev-parse --show-toplevel)")"
        echo -e "🌿 Branch: ${GREEN}$current_branch${NC} → ${BLUE}$config_remote/$config_branch${NC}"
        echo -e "📊 Status: $status_info"
        echo -e "⚙️  Config: Force=${config_force} | Dry-run=${config_dry_run} | Select-files=${config_select_files}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}\n"
        
        local selected_option
        selected_option=$(printf "%s\n" "${menu_options[@]}" | \
            fzf --ansi --height 50% --reverse \
            --header "Select an action (↓↑ navigate | Enter select | Ctrl-C exit)" \
            --preview 'echo -e "$(echo {} | cut -d"|" -f2)\n\nCurrent configuration:\n• Remote: '"$config_remote"'\n• Branch: '"$config_branch"'\n• Force: '"$config_force"'\n• Dry run: '"$config_dry_run"'\n• Select files: '"$config_select_files"'"' \
            --preview-window=right:40% \
            --border=rounded \
            --prompt="🔧 Action: ")
        
        [[ -z "$selected_option" ]] && break
        
        local action
        action=$(echo "$selected_option" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        case "$action" in
            "🚀 Commit & Push")
                echo -e "${CYAN}Standard Commit & Push Workflow${NC}"
                read -p "📝 Enter commit message: " commit_message
                if [[ -z "$commit_message" ]]; then
                    echo -e "${RED}❌ Commit message is required${NC}"
                    read -p "Press Enter to continue..."
                    continue
                fi
                
                # Execute workflow
                FORCE="$config_force"
                validate_branch "$config_branch" "$config_remote"
                
                if [[ "$config_branch" != "$current_branch" ]]; then
                    git checkout "$config_branch"
                fi
                
                if git status --porcelain | grep -q .; then
                    git add .
                    echo -e "${GREEN}✓ Added all changes${NC}"
                fi
                
                confirm_action "$config_remote" "$config_branch" "$config_dry_run"
                
                if [[ "$config_dry_run" == "false" ]]; then
                    git commit -m "$commit_message"
                    git push "$config_remote" "$config_branch"
                    echo -e "${GREEN}✅ Successfully pushed to $config_remote/$config_branch${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
                
            "📁 Select Files & Push")
                echo -e "${CYAN}Interactive File Selection Mode${NC}"
                if ! git status --porcelain | grep -q .; then
                    echo -e "${YELLOW}⚠️  No changes to commit${NC}"
                    read -p "Press Enter to continue..."
                    continue
                fi
                
                select_files
                
                read -p "📝 Enter commit message: " commit_message
                if [[ -z "$commit_message" ]]; then
                    echo -e "${RED}❌ Commit message is required${NC}"
                    read -p "Press Enter to continue..."
                    continue
                fi
                
                FORCE="$config_force"
                confirm_action "$config_remote" "$config_branch" "$config_dry_run"
                
                if [[ "$config_dry_run" == "false" ]]; then
                    git commit -m "$commit_message"
                    git push "$config_remote" "$config_branch"
                    echo -e "${GREEN}✅ Successfully pushed selected files${NC}"
                fi
                read -p "Press Enter to continue..."
                ;;
                
            "↩️  Undo Last Commit")
                uncommit
                ;;
                
            "🗑️  Remove File from Commit")
                remove_file
                ;;
                
            "🔧 Configure Options")
                configure_options_menu
                ;;
                
            "🌿 Branch Management")
                branch_management_menu
                ;;
                
            "📜 Commit History")
                show_commit_history_menu
                ;;
                
            "📊 Repository Status")
                show_repository_status_menu
                ;;
                
            "❓ Help")
                show_help
                read -p "Press Enter to return to main menu..."
                ;;
                
            "🚪 Exit")
                echo -e "${GREEN}👋 Goodbye!${NC}"
                exit 0
                ;;
        esac
    done
}

# Configuration options submenu
configure_options_menu() {
    while true; do
        local config_menu=(
            "🌿 Change Target Branch ($config_branch)|Modify the target branch for commits"
            "🔗 Change Remote ($config_remote)|Change the remote repository"
            "💪 Toggle Force Push ($config_force)|Enable/disable force push"
            "🔍 Toggle Dry Run ($config_dry_run)|Enable/disable dry run mode"
            "📁 Toggle File Selection ($config_select_files)|Enable/disable interactive file selection"
            "↩️  Back to Main Menu|Return to the main menu"
        )
        
        echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${YELLOW}⚙️  Configuration Options${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        
        local config_selection
        config_selection=$(printf "%s\n" "${config_menu[@]}" | \
            fzf --ansi --height 50% --reverse \
            --header "Configure Options (↓↑ navigate | Enter select | Ctrl-C back)" \
            --preview 'echo -e "$(echo {} | cut -d"|" -f2)\n\nCurrent Settings:\n• Branch: '"$config_branch"'\n• Remote: '"$config_remote"'\n• Force: '"$config_force"'\n• Dry-run: '"$config_dry_run"'\n• Select-files: '"$config_select_files"'"' \
            --preview-window=right:40% \
            --border=rounded \
            --prompt="⚙️  Option: ")
        
        [[ -z "$config_selection" ]] && break
        
        local action
        action=$(echo "$config_selection" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        case "$action" in
            "🌿 Change Target Branch"*)
                echo -e "${YELLOW}Available branches:${NC}"
                git branch -a | grep -v HEAD
                echo
                read -p "Enter target branch name (or press Enter to cancel): " new_branch
                if [[ -n "$new_branch" ]]; then
                    config_branch="$new_branch"
                    echo -e "${GREEN}✓ Target branch set to: $config_branch${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            "🔗 Change Remote"*)
                echo -e "${YELLOW}Available remotes:${NC}"
                git remote -v
                echo
                read -p "Enter remote name (or press Enter to cancel): " new_remote
                if [[ -n "$new_remote" ]]; then
                    config_remote="$new_remote"
                    echo -e "${GREEN}✓ Remote set to: $config_remote${NC}"
                    read -p "Press Enter to continue..."
                fi
                ;;
            "💪 Toggle Force Push"*)
                config_force=$([[ "$config_force" == "true" ]] && echo "false" || echo "true")
                echo -e "${GREEN}✓ Force push: $config_force${NC}"
                read -p "Press Enter to continue..."
                ;;
            "🔍 Toggle Dry Run"*)
                config_dry_run=$([[ "$config_dry_run" == "true" ]] && echo "false" || echo "true")
                echo -e "${GREEN}✓ Dry run: $config_dry_run${NC}"
                read -p "Press Enter to continue..."
                ;;
            "📁 Toggle File Selection"*)
                config_select_files=$([[ "$config_select_files" == "true" ]] && echo "false" || echo "true")
                echo -e "${GREEN}✓ File selection mode: $config_select_files${NC}"
                read -p "Press Enter to continue..."
                ;;
            "↩️  Back to Main Menu"|*)
                break
                ;;
        esac
    done
}

# Repository information display
show_repository_info() {
    echo -e "${CYAN}📊 Repository Information${NC}"
    echo -e "${YELLOW}═════════════════════════${NC}"
    echo -e "📂 Repository: $(basename "$(git rev-parse --show-toplevel)")"
    echo -e "📍 Location: $(git rev-parse --show-toplevel)"
    echo -e "🌿 Current Branch: $(git symbolic-ref --short HEAD)"
    echo -e "🔗 Remotes:"
    git remote -v | sed 's/^/  /'
    echo -e "📝 Recent Commits:"
    git --no-pager log --oneline -5 | sed 's/^/  /'
    echo -e "📊 Status:"
    git status --short | sed 's/^/  /' || echo "  Working directory clean"
    echo -e "${YELLOW}═════════════════════════${NC}"
}

# Commit history menu with interactive options
show_commit_history_menu() {
    while true; do
        local history_menu=(
            "📋 View Recent Commits (10)|Show the last 10 commits with details"
            "📜 View All Commits|Browse complete commit history with pager"
            "🔍 Search in History|Search commits by message, author, or hash"
            "📊 Commit Statistics|Show repository statistics and metrics"
            "🔄 Cherry-pick Commit|Pick a specific commit to apply"
            "🔀 Compare Commits|Compare differences between commits"
            "↩️  Back to Main Menu|Return to the main menu"
        )
        
        echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${YELLOW}📜 Commit History Management${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        
        local history_selection
        history_selection=$(printf "%s\n" "${history_menu[@]}" | \
            fzf --ansi --height 50% --reverse \
            --header "Commit History Options (↓↑ navigate | Enter select | Ctrl-C back)" \
            --preview 'echo -e "$(echo {} | cut -d"|" -f2)\n\nRepository: '"$(basename "$(git rev-parse --show-toplevel)")"'\nCurrent Branch: '"$(git symbolic-ref --short HEAD)"'\nTotal Commits: '"$(git rev-list --count HEAD 2>/dev/null || echo "N/A")"'"' \
            --preview-window=right:40% \
            --border=rounded \
            --prompt="📜 Action: ")
        
        [[ -z "$history_selection" ]] && break
        
        local action
        action=$(echo "$history_selection" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        case "$action" in
            "📋 View Recent Commits (10)")
                echo -e "${CYAN}📋 Recent Commits (Last 10)${NC}"
                echo -e "${YELLOW}══════════════════════════════════${NC}"
                git --no-pager log --oneline --graph --decorate -10
                echo -e "${YELLOW}══════════════════════════════════${NC}"
                read -p "Press Enter to continue..."
                ;;
            "📜 View All Commits")
                echo -e "${CYAN}📜 Complete Commit History${NC}"
                git log --oneline --graph --decorate --all
                read -p "Press Enter to continue..."
                ;;
            "🔍 Search in History")
                search_in_history
                ;;
            "📊 Commit Statistics")
                show_commit_statistics
                ;;
            "🔄 Cherry-pick Commit")
                cherry_pick_interactive
                ;;
            "🔀 Compare Commits")
                compare_commits_interactive
                ;;
            "↩️  Back to Main Menu"|*)
                break
                ;;
        esac
    done
}

# Repository status with detailed information
show_repository_status_menu() {
    while true; do
        local status_menu=(
            "📊 Full Status|Complete repository status with all details"
            "🌿 Branch Information|Detailed branch status and tracking info"
            "📝 Working Directory|Show all changes in working directory"
            "📦 Staging Area|Show files in staging area"
            "🔗 Remote Status|Check status with all remotes"
            "📈 File Statistics|Statistics about files and changes"
            "↩️  Back to Main Menu|Return to the main menu"
        )
        
        echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${YELLOW}📊 Repository Status${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        
        local status_selection
        status_selection=$(printf "%s\n" "${status_menu[@]}" | \
            fzf --ansi --height 50% --reverse \
            --header "Repository Status Options (↓↑ navigate | Enter select | Ctrl-C back)" \
            --preview 'echo -e "$(echo {} | cut -d"|" -f2)"' \
            --preview-window=right:40% \
            --border=rounded \
            --prompt="📊 View: ")
        
        [[ -z "$status_selection" ]] && break
        
        local action
        action=$(echo "$status_selection" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        case "$action" in
            "📊 Full Status")
                show_full_repository_status
                ;;
            "🌿 Branch Information")
                show_branch_information
                ;;
            "📝 Working Directory")
                show_working_directory_status
                ;;
            "📦 Staging Area")
                show_staging_area_status
                ;;
            "🔗 Remote Status")
                show_remote_status
                ;;
            "📈 File Statistics")
                show_file_statistics
                ;;
            "↩️  Back to Main Menu"|*)
                break
                ;;
        esac
    done
}

# Search in commit history
search_in_history() {
    echo -e "${CYAN}🔍 Search in Commit History${NC}"
    echo -e "Search options:"
    echo -e "1. Search by commit message"
    echo -e "2. Search by author"
    echo -e "3. Search by file changes"
    echo -e "4. Search by commit hash"
    echo
    read -p "Choose search type (1-4): " search_type
    
    case "$search_type" in
        1)
            read -p "Enter search term for commit messages: " search_term
            if [[ -n "$search_term" ]]; then
                echo -e "${YELLOW}Commits matching message '$search_term':${NC}"
                git --no-pager log --oneline --grep="$search_term" -i
            fi
            ;;
        2)
            read -p "Enter author name or email: " author_term
            if [[ -n "$author_term" ]]; then
                echo -e "${YELLOW}Commits by author '$author_term':${NC}"
                git --no-pager log --oneline --author="$author_term" -i
            fi
            ;;
        3)
            read -p "Enter filename or path: " file_term
            if [[ -n "$file_term" ]]; then
                echo -e "${YELLOW}Commits affecting '$file_term':${NC}"
                git --no-pager log --oneline -- "$file_term"
            fi
            ;;
        4)
            read -p "Enter commit hash (partial): " hash_term
            if [[ -n "$hash_term" ]]; then
                echo -e "${YELLOW}Commits matching hash '$hash_term':${NC}"
                git --no-pager log --oneline | grep -i "$hash_term"
            fi
            ;;
        *)
            echo -e "${RED}Invalid option${NC}"
            ;;
    esac
    read -p "Press Enter to continue..."
}

# Show commit statistics
show_commit_statistics() {
    echo -e "${CYAN}📊 Repository Statistics${NC}"
    echo -e "${YELLOW}═══════════════════════════════════${NC}"
    
    # Basic stats
    local total_commits=$(git rev-list --count HEAD 2>/dev/null || echo "0")
    local contributors=$(git shortlog -sn --all | wc -l)
    local branches=$(git branch -a | wc -l)
    local tags=$(git tag | wc -l)
    
    echo -e "📈 General Statistics:"
    echo -e "  • Total commits: $total_commits"
    echo -e "  • Contributors: $contributors"
    echo -e "  • Branches: $branches"
    echo -e "  • Tags: $tags"
    echo
    
    # Top contributors
    echo -e "👥 Top Contributors:"
    git shortlog -sn --all | head -5 | sed 's/^/  /'
    echo
    
    # Recent activity
    echo -e "📅 Recent Activity (last 30 days):"
    local recent_commits=$(git log --since="30 days ago" --oneline | wc -l)
    echo -e "  • Commits in last 30 days: $recent_commits"
    
    # File types
    echo -e "📁 File Types in Repository:"
    git ls-files | grep -E '\.[^.]*$' | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -5 | sed 's/^/  /'
    
    echo -e "${YELLOW}═══════════════════════════════════${NC}"
    read -p "Press Enter to continue..."
}

# Interactive cherry-pick
cherry_pick_interactive() {
    echo -e "${CYAN}🔄 Interactive Cherry-pick${NC}"
    echo -e "${YELLOW}Recent commits available for cherry-pick:${NC}"
    
    # Show recent commits with numbers
    git --no-pager log --oneline -10 | nl -w2 -s'. '
    echo
    
    read -p "Enter the commit hash to cherry-pick (or 'back' to return): " commit_hash
    
    if [[ "$commit_hash" == "back" || -z "$commit_hash" ]]; then
        return
    fi
    
    # Validate commit hash exists
    if git cat-file -e "$commit_hash" 2>/dev/null; then
        echo -e "${YELLOW}Cherry-picking commit: $commit_hash${NC}"
        git show --stat "$commit_hash"
        echo
        read -p "Proceed with cherry-pick? (y/N): " confirm
        
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            if git cherry-pick "$commit_hash"; then
                echo -e "${GREEN}✓ Cherry-pick successful${NC}"
            else
                echo -e "${RED}❌ Cherry-pick failed - resolve conflicts manually${NC}"
            fi
        fi
    else
        echo -e "${RED}❌ Invalid commit hash${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Compare commits interactively
compare_commits_interactive() {
    echo -e "${CYAN}🔀 Compare Commits${NC}"
    echo -e "${YELLOW}Recent commits:${NC}"
    
    git --no-pager log --oneline -10 | nl -w2 -s'. '
    echo
    
    read -p "Enter first commit hash: " commit1
    read -p "Enter second commit hash: " commit2
    
    if [[ -n "$commit1" && -n "$commit2" ]]; then
        if git cat-file -e "$commit1" 2>/dev/null && git cat-file -e "$commit2" 2>/dev/null; then
            echo -e "${YELLOW}Comparing $commit1 with $commit2:${NC}"
            git diff --stat "$commit1" "$commit2"
            echo
            read -p "Show detailed diff? (y/N): " show_diff
            
            if [[ "$show_diff" =~ ^[Yy]$ ]]; then
                git diff "$commit1" "$commit2"
            fi
        else
            echo -e "${RED}❌ One or both commit hashes are invalid${NC}"
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# Detailed repository status functions
show_full_repository_status() {
    echo -e "${CYAN}📊 Complete Repository Status${NC}"
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    
    # Repository info
    echo -e "📂 Repository: $(basename "$(git rev-parse --show-toplevel)")"
    echo -e "📍 Path: $(git rev-parse --show-toplevel)"
    echo -e "🌿 Current Branch: $(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")"
    echo
    
    # Status
    echo -e "📋 Git Status:"
    git status --short | sed 's/^/  /' || echo "  Working directory clean"
    echo
    
    # Remotes
    echo -e "🔗 Remotes:"
    git remote -v | sed 's/^/  /'
    echo
    
    # Recent commits
    echo -e "📜 Recent Commits:"
    git --no-pager log --oneline -5 | sed 's/^/  /'
    
    echo -e "${YELLOW}════════════════════════════════════════${NC}"
    read -p "Press Enter to continue..."
}

show_branch_information() {
    echo -e "${CYAN}🌿 Branch Information${NC}"
    echo -e "${YELLOW}═══════════════════════${NC}"
    
    echo -e "Current Branch: $(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")"
    echo
    
    echo -e "All Branches:"
    git branch -vv | sed 's/^/  /'
    echo
    
    echo -e "Remote Branches:"
    git branch -r | sed 's/^/  /'
    
    # Branch tracking info
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [[ -n "$current_branch" ]]; then
        echo
        echo -e "Tracking Information:"
        local upstream=$(git rev-parse --abbrev-ref "$current_branch@{upstream}" 2>/dev/null)
        if [[ -n "$upstream" ]]; then
            echo -e "  • Upstream: $upstream"
            local ahead=$(git rev-list --count "$current_branch" ^"$upstream" 2>/dev/null || echo "0")
            local behind=$(git rev-list --count "$upstream" ^"$current_branch" 2>/dev/null || echo "0")
            echo -e "  • Ahead: $ahead commits"
            echo -e "  • Behind: $behind commits"
        else
            echo -e "  • No upstream configured"
        fi
    fi
    
    echo -e "${YELLOW}═══════════════════════${NC}"
    read -p "Press Enter to continue..."
}

show_working_directory_status() {
    echo -e "${CYAN}📝 Working Directory Status${NC}"
    echo -e "${YELLOW}═══════════════════════════${NC}"
    
    if git status --porcelain | grep -q .; then
        echo -e "Modified Files:"
        git status --short | grep '^.M' | sed 's/^/  /'
        echo
        
        echo -e "Added Files:"
        git status --short | grep '^A' | sed 's/^/  /'
        echo
        
        echo -e "Deleted Files:"
        git status --short | grep '^.D' | sed 's/^/  /'
        echo
        
        echo -e "Untracked Files:"
        git status --short | grep '^??' | sed 's/^/  /'
    else
        echo -e "✓ Working directory is clean"
    fi
    
    echo -e "${YELLOW}═══════════════════════════${NC}"
    read -p "Press Enter to continue..."
}

show_staging_area_status() {
    echo -e "${CYAN}📦 Staging Area Status${NC}"
    echo -e "${YELLOW}═══════════════════════${NC}"
    
    if git diff --cached --name-only | grep -q .; then
        echo -e "Staged Files:"
        git diff --cached --name-status | sed 's/^/  /'
        echo
        
        echo -e "Staged Changes Summary:"
        git diff --cached --stat | sed 's/^/  /'
    else
        echo -e "📦 Staging area is empty"
    fi
    
    echo -e "${YELLOW}═══════════════════════${NC}"
    read -p "Press Enter to continue..."
}

show_remote_status() {
    echo -e "${CYAN}🔗 Remote Status${NC}"
    echo -e "${YELLOW}═════════════════${NC}"
    
    echo -e "Configured Remotes:"
    git remote -v | sed 's/^/  /'
    echo
    
    # Check connectivity
    echo -e "Remote Connectivity:"
    for remote in $(git remote); do
        echo -n "  • $remote: "
        if git ls-remote "$remote" HEAD &>/dev/null; then
            echo -e "${GREEN}✓ Connected${NC}"
        else
            echo -e "${RED}✗ Connection failed${NC}"
        fi
    done
    
    echo -e "${YELLOW}═════════════════${NC}"
    read -p "Press Enter to continue..."
}

show_file_statistics() {
    echo -e "${CYAN}📈 File Statistics${NC}"
    echo -e "${YELLOW}═══════════════════════════${NC}"
    
    # Total files
    local total_files=$(git ls-files | wc -l)
    echo -e "📊 Total tracked files: $total_files"
    echo
    
    # File extensions
    echo -e "📁 File types:"
    git ls-files | grep -E '\.[^.]*$' | sed 's/.*\.//' | sort | uniq -c | sort -nr | head -10 | sed 's/^/  /'
    echo
    
    # Repository size
    echo -e "💾 Repository size:"
    du -sh .git/ | sed 's/^/  Git directory: /'
    du -sh --exclude=.git . | sed 's/^/  Working directory: /'
    
    echo -e "${YELLOW}═══════════════════════════${NC}"
    read -p "Press Enter to continue..."
}

# Workflow principal
main() {
    # Si aucun argument n'est fourni, lancer le menu interactif
    if [[ $# -eq 0 ]]; then
        interactive_menu
        return 0
    fi
    
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
            -i|--interactive)
                interactive_menu
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

# Branch Management Menu
branch_management_menu() {
    while true; do
        local branch_menu=(
            "🌿 Switch Branch|Switch to a different branch"
            "➕ Create New Branch|Create and optionally switch to a new branch"
            "📋 List All Branches|Show all local and remote branches"
            "🔄 Merge Branches|Merge one branch into current branch"
            "🗑️  Delete Branch|Delete a local or remote branch"
            "🚀 Push Branch|Push current branch to remote"
            "⬇️  Pull Branch|Pull changes from remote branch"
            "🔄 Sync with Remote|Fetch and update branch information"
            "🏷️  Branch Info|Show detailed information about branches"
            "↩️  Back to Main Menu|Return to the main menu"
        )
        
        echo -e "\n${CYAN}═══════════════════════════════════════${NC}"
        echo -e "${YELLOW}🌿 Branch Management${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        echo -e "Current Branch: ${GREEN}$(git symbolic-ref --short HEAD 2>/dev/null || echo "HEAD detached")${NC}"
        echo -e "${CYAN}═══════════════════════════════════════${NC}"
        
        local branch_selection
        branch_selection=$(printf "%s\n" "${branch_menu[@]}" | \
            fzf --ansi --height 50% --reverse \
            --header "Branch Management Options (↓↑ navigate | Enter select | Ctrl-C back)" \
            --preview 'echo -e "$(echo {} | cut -d"|" -f2)\n\nCurrent Branch: '"$(git symbolic-ref --short HEAD 2>/dev/null)"'\nTotal Branches: '"$(git branch -a | wc -l)"'"' \
            --preview-window=right:40% \
            --border=rounded \
            --prompt="🌿 Action: ")
        
        [[ -z "$branch_selection" ]] && break
        
        local action
        action=$(echo "$branch_selection" | cut -d'|' -f1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        case "$action" in
            "🌿 Switch Branch")
                switch_branch_interactive
                ;;
            "➕ Create New Branch")
                create_branch_interactive
                ;;
            "📋 List All Branches")
                list_all_branches
                ;;
            "🔄 Merge Branches")
                merge_branches_interactive
                ;;
            "🗑️  Delete Branch")
                delete_branch_interactive
                ;;
            "🚀 Push Branch")
                push_branch_interactive
                ;;
            "⬇️  Pull Branch")
                pull_branch_interactive
                ;;
            "🔄 Sync with Remote")
                sync_with_remote
                ;;
            "🏷️  Branch Info")
                show_branch_detailed_info
                ;;
            "↩️  Back to Main Menu"|*)
                break
                ;;
        esac
    done
}

# Switch branch interactively
switch_branch_interactive() {
    echo -e "${CYAN}🌿 Switch Branch${NC}"
    echo -e "${YELLOW}Available branches:${NC}"
    
    # Show all branches with current branch highlighted
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    git branch -a | sed 's/^/  /'
    echo
    
    # Get list of branch names for selection
    local branches=($(git branch | sed 's/\*//g' | sed 's/^[[:space:]]*//'))
    
    if [[ ${#branches[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No branches available${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Add remote branches
    local remote_branches=($(git branch -r | grep -v HEAD | sed 's|origin/||' | sed 's/^[[:space:]]*//'))
    
    echo -e "${YELLOW}Select a branch:${NC}"
    local selected_branch
    selected_branch=$(printf "%s\n" "${branches[@]}" "${remote_branches[@]}" | \
        fzf --height 40% --reverse \
        --header "Select branch to switch to" \
        --prompt="🌿 Branch: ")
    
    if [[ -n "$selected_branch" && "$selected_branch" != "$current_branch" ]]; then
        if git show-ref --verify --quiet "refs/heads/$selected_branch"; then
            # Local branch exists
            git checkout "$selected_branch"
        elif git show-ref --verify --quiet "refs/remotes/origin/$selected_branch"; then
            # Remote branch exists, create local tracking branch
            git checkout -b "$selected_branch" "origin/$selected_branch"
        else
            echo -e "${RED}❌ Branch '$selected_branch' not found${NC}"
        fi
        
        if [[ $? -eq 0 ]]; then
            echo -e "${GREEN}✓ Switched to branch: $selected_branch${NC}"
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# Create new branch interactively
create_branch_interactive() {
    echo -e "${CYAN}➕ Create New Branch${NC}"
    
    read -p "Enter new branch name: " new_branch_name
    
    if [[ -z "$new_branch_name" ]]; then
        echo -e "${RED}❌ Branch name cannot be empty${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    # Check if branch already exists
    if git show-ref --verify --quiet "refs/heads/$new_branch_name"; then
        echo -e "${RED}❌ Branch '$new_branch_name' already exists${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "${YELLOW}Create branch from:${NC}"
    echo -e "1. Current branch ($(git symbolic-ref --short HEAD 2>/dev/null))"
    echo -e "2. Specific commit"
    echo -e "3. Remote branch"
    
    read -p "Choose option (1-3): " create_option
    
    case "$create_option" in
        1)
            git checkout -b "$new_branch_name"
            ;;
        2)
            echo -e "${YELLOW}Recent commits:${NC}"
            git --no-pager log --oneline -10
            read -p "Enter commit hash: " commit_hash
            if [[ -n "$commit_hash" ]]; then
                git checkout -b "$new_branch_name" "$commit_hash"
            fi
            ;;
        3)
            echo -e "${YELLOW}Remote branches:${NC}"
            git branch -r | grep -v HEAD | sed 's/^/  /'
            read -p "Enter remote branch (e.g., origin/main): " remote_branch
            if [[ -n "$remote_branch" ]]; then
                git checkout -b "$new_branch_name" "$remote_branch"
            fi
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            read -p "Press Enter to continue..."
            return
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Created and switched to branch: $new_branch_name${NC}"
        
        read -p "Push new branch to remote? (y/N): " push_remote
        if [[ "$push_remote" =~ ^[Yy]$ ]]; then
            git push -u origin "$new_branch_name"
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}✓ Branch pushed to remote${NC}"
            fi
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# List all branches with details
list_all_branches() {
    echo -e "${CYAN}📋 All Branches${NC}"
    echo -e "${YELLOW}══════════════════════════════════${NC}"
    
    echo -e "${GREEN}Local Branches:${NC}"
    git branch -vv | sed 's/^/  /'
    echo
    
    echo -e "${BLUE}Remote Branches:${NC}"
    git branch -r | sed 's/^/  /'
    echo
    
    # Branch statistics
    local total_local=$(git branch | wc -l)
    local total_remote=$(git branch -r | wc -l)
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    
    echo -e "📊 Statistics:"
    echo -e "  • Local branches: $total_local"
    echo -e "  • Remote branches: $total_remote"
    echo -e "  • Current branch: $current_branch"
    
    # Show tracking information
    if [[ -n "$current_branch" ]]; then
        local upstream=$(git rev-parse --abbrev-ref "$current_branch@{upstream}" 2>/dev/null)
        if [[ -n "$upstream" ]]; then
            echo -e "  • Current upstream: $upstream"
            local ahead=$(git rev-list --count "$current_branch" ^"$upstream" 2>/dev/null || echo "0")
            local behind=$(git rev-list --count "$upstream" ^"$current_branch" 2>/dev/null || echo "0")
            echo -e "  • Ahead: $ahead commits, Behind: $behind commits"
        fi
    fi
    
    echo -e "${YELLOW}══════════════════════════════════${NC}"
    read -p "Press Enter to continue..."
}

# Merge branches interactively
merge_branches_interactive() {
    echo -e "${CYAN}🔄 Merge Branches${NC}"
    
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    echo -e "Current branch: ${GREEN}$current_branch${NC}"
    echo
    
    echo -e "${YELLOW}Available branches to merge:${NC}"
    local branches=($(git branch | grep -v "* $current_branch" | sed 's/^[[:space:]]*//'))
    
    if [[ ${#branches[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No other branches available to merge${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    local selected_branch
    selected_branch=$(printf "%s\n" "${branches[@]}" | \
        fzf --height 40% --reverse \
        --header "Select branch to merge into $current_branch" \
        --prompt="🔄 Branch: ")
    
    if [[ -n "$selected_branch" ]]; then
        echo -e "${YELLOW}Merging '$selected_branch' into '$current_branch'${NC}"
        
        # Show what will be merged
        echo -e "\n${YELLOW}Changes to be merged:${NC}"
        git log --oneline "$current_branch".."$selected_branch" | head -5
        echo
        
        read -p "Proceed with merge? (y/N): " confirm_merge
        
        if [[ "$confirm_merge" =~ ^[Yy]$ ]]; then
            if git merge "$selected_branch"; then
                echo -e "${GREEN}✓ Merge successful${NC}"
                
                read -p "Delete merged branch '$selected_branch'? (y/N): " delete_branch
                if [[ "$delete_branch" =~ ^[Yy]$ ]]; then
                    git branch -d "$selected_branch"
                    echo -e "${GREEN}✓ Branch '$selected_branch' deleted${NC}"
                fi
            else
                echo -e "${RED}❌ Merge failed - resolve conflicts manually${NC}"
                echo -e "${YELLOW}Use 'git status' to see conflicted files${NC}"
            fi
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# Delete branch interactively  
delete_branch_interactive() {
    echo -e "${CYAN}🗑️  Delete Branch${NC}"
    
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    echo -e "Current branch: ${GREEN}$current_branch${NC} (cannot be deleted)"
    echo
    
    echo -e "${YELLOW}Available branches to delete:${NC}"
    local branches=($(git branch | grep -v "* $current_branch" | sed 's/^[[:space:]]*//'))
    
    if [[ ${#branches[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No other branches available to delete${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    local selected_branch
    selected_branch=$(printf "%s\n" "${branches[@]}" | \
        fzf --height 40% --reverse \
        --header "Select branch to delete (cannot delete current branch)" \
        --prompt="🗑️ Branch: ")
    
    if [[ -n "$selected_branch" ]]; then
        echo -e "${RED}⚠️  WARNING: This will permanently delete branch '$selected_branch'${NC}"
        
        # Check if branch is merged
        if git merge-base --is-ancestor "$selected_branch" "$current_branch"; then
            echo -e "${GREEN}✓ Branch is merged into current branch${NC}"
        else
            echo -e "${YELLOW}⚠️  Branch is NOT merged - commits may be lost!${NC}"
            read -p "Force delete unmerged branch? (y/N): " force_delete
            if [[ "$force_delete" =~ ^[Yy]$ ]]; then
                git branch -D "$selected_branch"
                if [[ $? -eq 0 ]]; then
                    echo -e "${GREEN}✓ Branch '$selected_branch' force-deleted${NC}"
                fi
                read -p "Press Enter to continue..."
                return
            fi
        fi
        
        read -p "Confirm deletion of branch '$selected_branch'? (y/N): " confirm_delete
        
        if [[ "$confirm_delete" =~ ^[Yy]$ ]]; then
            git branch -d "$selected_branch"
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}✓ Branch '$selected_branch' deleted${NC}"
                
                # Ask about remote branch
                if git ls-remote --heads origin "$selected_branch" | grep -q .; then
                    read -p "Delete remote branch 'origin/$selected_branch' too? (y/N): " delete_remote
                    if [[ "$delete_remote" =~ ^[Yy]$ ]]; then
                        git push origin --delete "$selected_branch"
                        if [[ $? -eq 0 ]]; then
                            echo -e "${GREEN}✓ Remote branch deleted${NC}"
                        fi
                    fi
                fi
            fi
        fi
    fi
    
    read -p "Press Enter to continue..."
}

# Push current branch
push_branch_interactive() {
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    echo -e "${CYAN}🚀 Push Branch: ${GREEN}$current_branch${NC}"
    
    # Check if there are commits to push
    local upstream=$(git rev-parse --abbrev-ref "$current_branch@{upstream}" 2>/dev/null)
    
    if [[ -n "$upstream" ]]; then
        local ahead=$(git rev-list --count "$current_branch" ^"$upstream" 2>/dev/null || echo "0")
        echo -e "Commits ahead of $upstream: $ahead"
    else
        echo -e "${YELLOW}No upstream configured${NC}"
    fi
    
    echo -e "\n${YELLOW}Push options:${NC}"
    echo -e "1. Push to origin (default)"
    echo -e "2. Push to specific remote"
    echo -e "3. Force push (dangerous)"
    echo -e "4. Set upstream and push"
    
    read -p "Choose option (1-4): " push_option
    
    case "$push_option" in
        1)
            git push origin "$current_branch"
            ;;
        2)
            echo -e "${YELLOW}Available remotes:${NC}"
            git remote -v
            read -p "Enter remote name: " remote_name
            if [[ -n "$remote_name" ]]; then
                git push "$remote_name" "$current_branch"
            fi
            ;;
        3)
            echo -e "${RED}⚠️  WARNING: Force push will overwrite remote history!${NC}"
            read -p "Are you sure? Type 'force' to confirm: " confirm_force
            if [[ "$confirm_force" == "force" ]]; then
                git push --force origin "$current_branch"
            fi
            ;;
        4)
            git push -u origin "$current_branch"
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Push successful${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Pull current branch
pull_branch_interactive() {
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    echo -e "${CYAN}⬇️  Pull Branch: ${GREEN}$current_branch${NC}"
    
    local upstream=$(git rev-parse --abbrev-ref "$current_branch@{upstream}" 2>/dev/null)
    
    if [[ -n "$upstream" ]]; then
        echo -e "Upstream: $upstream"
        local behind=$(git rev-list --count "$upstream" ^"$current_branch" 2>/dev/null || echo "0")
        echo -e "Commits behind: $behind"
        
        if [[ "$behind" -eq 0 ]]; then
            echo -e "${GREEN}✓ Already up to date${NC}"
            read -p "Press Enter to continue..."
            return
        fi
    else
        echo -e "${YELLOW}No upstream configured${NC}"
        read -p "Press Enter to continue..."
        return
    fi
    
    echo -e "\n${YELLOW}Pull options:${NC}"
    echo -e "1. Pull (merge)"
    echo -e "2. Pull with rebase"
    echo -e "3. Fetch only"
    
    read -p "Choose option (1-3): " pull_option
    
    case "$pull_option" in
        1)
            git pull origin "$current_branch"
            ;;
        2)
            git pull --rebase origin "$current_branch"
            ;;
        3)
            git fetch origin
            ;;
        *)
            echo -e "${RED}❌ Invalid option${NC}"
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Pull successful${NC}"
    fi
    
    read -p "Press Enter to continue..."
}

# Sync with remote
sync_with_remote() {
    echo -e "${CYAN}🔄 Sync with Remote${NC}"
    
    echo -e "${YELLOW}Fetching from all remotes...${NC}"
    git fetch --all
    
    echo -e "\n${YELLOW}Pruning deleted remote branches...${NC}"
    git remote prune origin
    
    echo -e "\n${GREEN}✓ Sync completed${NC}"
    
    # Show updated status
    echo -e "\n${YELLOW}Updated branch status:${NC}"
    git branch -vv | head -10
    
    read -p "Press Enter to continue..."
}

# Show detailed branch information
show_branch_detailed_info() {
    echo -e "${CYAN}🏷️  Detailed Branch Information${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════${NC}"
    
    local current_branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    
    echo -e "📍 Current Branch: ${GREEN}$current_branch${NC}"
    
    # Branch tracking info
    local upstream=$(git rev-parse --abbrev-ref "$current_branch@{upstream}" 2>/dev/null)
    if [[ -n "$upstream" ]]; then
        echo -e "🔗 Upstream: $upstream"
        local ahead=$(git rev-list --count "$current_branch" ^"$upstream" 2>/dev/null || echo "0")
        local behind=$(git rev-list --count "$upstream" ^"$current_branch" 2>/dev/null || echo "0")
        echo -e "📊 Status: Ahead $ahead, Behind $behind"
    else
        echo -e "🔗 Upstream: Not configured"
    fi
    
    # Last commit info
    echo -e "\n📝 Last Commit:"
    git --no-pager log -1 --pretty=format:"  %h - %s (%cr) <%an>" "$current_branch"
    echo
    
    # Branch creation info
    echo -e "\n🌱 Branch History:"
    echo -e "  Created from: $(git merge-base --fork-point main "$current_branch" 2>/dev/null | xargs git show --no-patch --format="%h - %s" 2>/dev/null || echo "Unknown")"
    
    # Files changed in this branch
    if [[ -n "$upstream" ]]; then
        echo -e "\n📁 Files Modified in This Branch:"
        git diff --name-only "$upstream"..."$current_branch" | head -10 | sed 's/^/  /'
    fi
    
    echo -e "\n${YELLOW}═══════════════════════════════════════${NC}"
    read -p "Press Enter to continue..."
}

# Execution with error handling
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi