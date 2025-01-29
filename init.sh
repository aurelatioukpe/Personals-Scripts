#!/bin/bash

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher l'aide
show_help() {
    echo -e "${YELLOW}Usage:${NC}"
    echo "  $0 [OPTIONS]"
    echo -e "${YELLOW}Options:${NC}"
    echo "  -h, --help       Show this help message"
    echo "  -a, --all        Install all available scripts"
    echo -e "\nThis script will guide you through installing scripts to /usr/bin and updating the README.md."
    exit 0
}

# Fonction pour vérifier les dépendances
check_dependencies() {
    if ! command -v git &> /dev/null; then
        echo -e "${RED}Error: git is not installed!${NC}"
        exit 1
    fi
}

# Fonction pour installer un script
install_script() {
    local script_name=$1
    local script_path="./$script_name/$script_name.sh"

    if [ -f "$script_path" ]; then
        echo -e "${BLUE}Installing $script_name...${NC}"
        sudo cp "$script_path" "/usr/bin/$script_name"
        sudo chmod +x "/usr/bin/$script_name"
        echo -e "${GREEN}✓ $script_name installed successfully!${NC}"
    else
        echo -e "${RED}Error: Script $script_name not found!${NC}"
    fi
}

# Fonction principale
main() {
    check_dependencies

    # Liste des scripts disponibles
    scripts=("Banned-Function-Checker" "Makefile-Generator" "Push_That" "Repo_Organiser" "Valgrind-Memory-Checker" "Windows-Mount")

    # Traitement des arguments
    if [[ $# -eq 0 ]]; then
        echo -e "${YELLOW}Which script(s) do you want to install?${NC}"
        for i in "${!scripts[@]}"; do
            echo "$((i+1)). ${scripts[$i]}"
        done
        echo -e "${BLUE}Enter the numbers (comma-separated) or 'all' to install everything:${NC}"
        read -r selection

        if [[ "$selection" == "all" ]]; then
            for script in "${scripts[@]}"; do
                install_script "$script"
            done
        else
            IFS=',' read -r -a selected_indices <<< "$selection"
            for index in "${selected_indices[@]}"; do
                if [[ $index -ge 1 && $index -le ${#scripts[@]} ]]; then
                    install_script "${scripts[$((index-1))]}"
                    update_readme "${scripts[$((index-1))]}"
                else
                    echo -e "${RED}Invalid selection: $index${NC}"
                fi
            done
        fi
    else
        case $1 in
            -h|--help)
                show_help
                ;;
            -a|--all)
                for script in "${scripts[@]}"; do
                    install_script "$script"
                done
                ;;
            *)
                echo -e "${RED}Error: Invalid option!${NC}"
                show_help
                ;;
        esac
    fi
}

# Exécution
main "$@"