#!/usr/bin/env bash

# Configuration des couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Dossiers
INSTALL_DIR="$HOME/devtools"
BIN_DIR="$HOME/.local/bin"
PYTHON_VENV="$HOME/venv"  # Chemin de l'environnement virtuel

# Vérifier et configurer le PATH
ensure_path() {
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo -e "${YELLOW}Ajout de $BIN_DIR à votre PATH...${NC}"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> ~/.bashrc
        export PATH="$BIN_DIR:$PATH"
        echo -e "${GREEN}✓ PATH mis à jour. Redémarrez votre terminal ou exécutez 'source ~/.bashrc'${NC}"
    fi
}

# Activer l'environnement Python
activate_python_env() {
    if [ ! -d "$PYTHON_VENV" ]; then
        echo -e "${CYAN}Création d'un environnement Python virtuel...${NC}"
        python3 -m venv "$PYTHON_VENV"
    fi
    
    source "$PYTHON_VENV/bin/activate"
    echo -e "${GREEN}✓ Environnement Python activé${NC}"
}

# Outils disponibles
declare -A TOOLS=(
    ["banned-checker"]="Vérificateur de fonctions interdites (Python)"
    ["genmake"]="Générateur de Makefile interactif (Python)"
    ["push-that"]="Assistant Git avancé (Bash)"
    ["repo-organiser"]="Organisateur de dépôt (Bash)"
    ["memcheck"]="Vérificateur de mémoire avec Valgrind (Bash)"
    ["mount-win"]="Outil de montage de partitions Windows (Bash)"
    ["code-stats"]="Analyseur de statistiques de code (Bash)"
)

# Installer les dépendances Python
install_python_deps() {
    echo -e "${CYAN}Installation des dépendances Python...${NC}"
    pip install colorama bullet
}

# Installer un outil spécifique
install_tool() {
    local tool_name=$1
    case $tool_name in
        "banned-checker")
            cp banned_function_checker.py "$INSTALL_DIR/"
            chmod +x "$INSTALL_DIR/banned_function_checker.py"
            ln -sf "$INSTALL_DIR/banned_function_checker.py" "$BIN_DIR/banned-checker"
            ;;
        "genmake")
            cp genmake.py "$INSTALL_DIR/"
            chmod +x "$INSTALL_DIR/genmake.py"
            ln -sf "$INSTALL_DIR/genmake.py" "$BIN_DIR/genmake"
            ;;
        *)  # Pour les scripts Bash
            cp "${tool_name//-/_}.sh" "$INSTALL_DIR/"
            chmod +x "$INSTALL_DIR/${tool_name//-/_}.sh"
            ln -sf "$INSTALL_DIR/${tool_name//-/_}.sh" "$BIN_DIR/$tool_name"
            ;;
    esac
}

# Menu d'installation interactif
interactive_install() {
    echo -e "\n${CYAN}Outils disponibles :${NC}"
    local i=1
    local tool_names=()
    for tool in "${!TOOLS[@]}"; do
        echo -e "${GREEN}$i.${NC} $tool - ${TOOLS[$tool]}"
        tool_names+=("$tool")
        ((i++))
    done

    echo -e "\n${YELLOW}Entrez les numéros des outils à installer (séparés par des espaces) :${NC}"
    read -r -a selections

    for num in "${selections[@]}"; do
        if [[ $num =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#TOOLS[@]}" ]; then
            local selected_tool="${tool_names[$((num-1))]}"
            echo -e "\n${BLUE}Installation de $selected_tool...${NC}"
            install_tool "$selected_tool"
            echo -e "${GREEN}✓ $selected_tool installé${NC}"
        fi
    done
}

# Initialisation
ensure_path
activate_python_env
install_python_deps

# Menu principal
while true; do
    echo -e "${CYAN}╔════════════════════════════════════════════╗"
    echo -e "║       GESTIONNAIRE D'OUTILS DE DÉVELOPPEMENT      ║"
    echo -e "╠════════════════════════════════════════════╣"
    echo -e "║ ${GREEN}1.${CYAN} Lister et installer des outils           ║"
    echo -e "║ ${GREEN}2.${CYAN} Mettre à jour tous les outils            ║"
    echo -e "║ ${GREEN}3.${CYAN} Désinstaller                            ║"
    echo -e "║ ${GREEN}4.${CYAN} Quitter                                 ║"
    echo -e "╚════════════════════════════════════════════╝${NC}"
    echo -e "\n${YELLOW}Choisissez une option (1-4): ${NC}"
    read -r choice

    case $choice in
        1) interactive_install ;;
        2) update_tools ;;
        3) uninstall_tools ;;
        4) 
            deactivate 2>/dev/null
            echo -e "${GREEN}Au revoir!${NC}"
            exit 0
            ;;
        *) echo -e "${RED}Option invalide${NC}" ;;
    esac
done