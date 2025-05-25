#!/bin/bash

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Fonction d'aide étendue
show_help() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 [OPTIONS] <commit_message>"
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help       Show this help message"
    echo "  -f, --force      Force push without confirmation"
    echo "  -b, --branch     Specify a particular branch"
    echo "  -s, --select     Interactive file selection mode"
    echo "  --uncommit       Undo the last commit (keep changes)"
    echo "  --remove-file    Remove a file from the last commit"
    echo -e "\n${YELLOW}Examples:${NC}"
    echo "  $0 'My commit' -s"
    echo "  $0 --uncommit"
    echo "  $0 --remove-file"
    exit 0
}

# Détection du système d'exploitation
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
    elif [ -f /etc/debian_version ]; then
        OS=Debian
    elif [ -f /etc/redhat-release ]; then
        OS=$(cat /etc/redhat-release | cut -d ' ' -f 1)
    else
        OS=$(uname -s)
    fi
    echo $OS
}

# Installation de fzf en fonction du système d'exploitation
install_fzf() {
    OS=$(detect_os)
    case $OS in
        "Ubuntu" | "Debian" | "Linux Mint")
            sudo apt update && sudo apt install -y fzf
            ;;
        "Fedora")
            sudo dnf install -y fzf
            ;;
        "CentOS" | "Red Hat Enterprise Linux")
            sudo yum install -y fzf
            ;;
        "Arch Linux" | "Manjaro Linux")
            sudo pacman -S --noconfirm fzf
            ;;
        "macOS")
            brew install fzf
            ;;
        *)
            echo -e "${RED}Error: Unsupported operating system!${NC}"
            exit 1
            ;;
    esac
}

# Vérification des dépendances
check_dependencies() {
    if ! command -v fzf &> /dev/null; then
        echo -e "${RED}Error: fzf is not installed!${NC}"
        read -p "${GREEN}Do you want to install it? (yes/no) " answer
        case "$answer" in
            [yY]es)
                install_fzf
                ;;
            [Nn]o)
                exit 1
                ;;
        esac
    fi
}

# Vérification du dépôt Git
check_git_repo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo -e "${RED}Error: This directory is not a Git repository!${NC}"
        exit 1
    fi
}

# Sélection interactive des fichiers
select_files() {
    echo -e "${CYAN}Select files (Tab for multi-selection):${NC}"
    local files
    files=$(git -c color.status=always status --short | \
        fzf --ansi --multi --height 40% --reverse \
        --preview 'git diff --color=always -- {-1}' \
        --header "↓↑ navigation | Tab selection | Ctrl-C cancel" | \
        awk '{print $2}')
    
    if [ -n "$files" ]; then
        echo -e "${BLUE}Selected files:${NC}"
        echo "$files" | xargs -I{} echo -e " - ${GREEN}{}${NC}"
        git add $files
    else
        echo -e "${RED}No files selected!${NC}"
        exit 1
    fi
}

# Annulation du dernier commit
uncommit() {
    echo -e "${YELLOW}Undoing the last commit...${NC}"
    git reset --soft HEAD~1
    echo -e "${GREEN}✓ Last commit undone (changes preserved)${NC}"
    exit 0
}

# Retrait d'un fichier d'un commit
remove_file() {
    echo -e "${CYAN}Choose a file to remove:${NC}"
    local file=$(git show --name-only --pretty=format: | fzf --height 40% --reverse)
    
    if [ -n "$file" ]; then
        git reset HEAD~1 --soft
        git restore --staged "$file"
        git commit -m "$(git log -1 --pretty=%B)" > /dev/null
        echo -e "${GREEN}✓ File '${MAGENTA}$file${GREEN}' removed from the commit${NC}"
    else
        echo -e "${RED}No file selected!${NC}"
    fi
    exit 0
}

# Confirmation avant push
confirm_action() {
    if [ "$FORCE" = false ]; then
        echo -e "${YELLOW}Changes to push to ${BLUE}${TARGET_BRANCH}${YELLOW}:${NC}"
        git --no-pager diff --stat --cached
        read -p "Confirm push? (y/N) " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo -e "${RED}Push canceled!${NC}"
            exit 0
        fi
    fi
}

# Workflow principal
main() {
    check_dependencies
    check_git_repo

    CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
    REMOTE="origin"
    FORCE=false
    SELECT_MODE=false
    MESSAGE=""
    TARGET_BRANCH="$CURRENT_BRANCH"

    # Traitement des arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--branch)
                TARGET_BRANCH="$2"
                shift
                shift
                ;;
            -s|--select)
                SELECT_MODE=true
                shift
                ;;
            --uncommit)
                uncommit
                ;;
            --remove-file)
                remove_file
                ;;
            *)
                MESSAGE="$1"
                shift
                ;;
        esac
    done

    # Ajout des fichiers
    if [ "$SELECT_MODE" = true ]; then
        select_files
        # Demander le message de commit après la sélection des fichiers
        if [ -z "$MESSAGE" ]; then
            read -p "${RED}Enter commit message: ${NC}" MESSAGE
            if [ -z "$MESSAGE" ]; then
                echo -e "${RED}Error: Commit message is required!${NC}"
                exit 1
            fi
        fi
    else
        echo -e "${GREEN}Adding all changes...${NC}"
        git add .
    fi

    # Validation du message
    if [ -z "$MESSAGE" ]; then
        echo -e "${RED}Error: Commit message is required!${NC}"
        show_help
        exit 1
    fi

    # Confirmation
    confirm_action

    # Commit
    echo -e "${GREEN}Creating commit...${NC}"
    if ! git commit -m "$MESSAGE"; then
        echo -e "${RED}Error during commit!${NC}"
        exit 1
    fi

    # Push
    echo -e "${GREEN}Pushing to ${BLUE}${REMOTE}/${TARGET_BRANCH}${GREEN}...${NC}"
    if ! git push "${REMOTE}" "${TARGET_BRANCH}"; then
        echo -e "${RED}Error during push!${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Push successful!${NC}"
}

# Exécution
main "$@"