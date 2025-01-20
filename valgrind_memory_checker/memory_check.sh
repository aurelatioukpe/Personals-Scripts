#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'

echo -e "${RED}████████╗██████╗  █████╗ ███████╗███████╗██╗   ██╗       ██╗       ███████╗ ${GREEN}██████╗ ${YELLOW}██████╗ ${CYAN}██████╗ ${WHITE}██████╗ ${MAGENTA}██╗███████╗███████╗███████╗${NC}"
echo -e "${RED}╚══██╔══╝██╔══██╗██╔══██╗██╔════╝██╔════╝╚██╗ ██╔╝       ██║       ██╔════╝██╔════╝██╔═══██╗██╔══██╗██╔══██╗██║╚════██║╚════██║╚════██║${NC}"
echo -e "${RED}   ██║   ██████╔╝███████║█████╗  █████╗   ╚████╔╝     ████████╗    ███████╗██║     ██║   ██║██████╔╝██████╔╝██║    ██╔╝    ██╔╝    ██╔╝${NC}"
echo -e "${RED}   ██║   ██╔══██╗██╔══██║██╔══╝  ██╔══╝    ╚██╔╝      ██╔═██╔═╝    ╚════██║██║     ██║   ██║██╔══██╗██╔═══╝ ██║   ██╔╝    ██╔╝    ██╔╝ ${NC}"
echo -e "${RED}   ██║   ██║  ██║██║  ██║██║     ██║        ██║       ██████║      ███████║╚██████╗╚██████╔╝██║  ██║██║     ██║   ██║     ██║     ██║${NC}"
echo -e "${RED}   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝        ╚═╝       ╚═════╝      ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚═╝     ╚═╝   ╚═╝     ╚═╝     ╚═╝${NC}"


if ! command -v valgrind &> /dev/null
then
    echo "valgrind could not be found. Do you want to install Valgrind ? (y/n)"
    read -r answer
    if [[ "$answer" == "y" || "$answer" == "Y" || "$answer" == "yes" ]]; then
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            if [[ "$ID" == "ubuntu"  || "$ID" == "debian" ]]; then
                sudo apt-get update
                sudo apt-get install valgrind
            elif [ "$ID" == "fedora" ]; then
                sudo dnf install valgrind -y
            elif [ "$ID" == "arch" ]; then    
                sudo pacman -S valgrind
            elif [[ "$ID" == "rhel" || "$ID" == "centos" ]]; then
                sudo yum install valgrind -y
            else
                echo "Unsupported OS. Please install valgrind manually."
                exit 1
            fi
        else
            echo "Unsupported OS. Please install valgrind manually."
            exit 1
        fi
    else
        echo "Valgrind installation cancelled."
        exit 1
    fi
fi

echo -e "Please enter the path of the file to check:"
read -r file_path

if [ ! -f "$file_path"]; then
    echo "File does not exist. Please verify the path or the permissions."
    exit 1
fi

echo "Starting valgrind analysis..."
valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes --verbose $file_path

echo "Analysis complete."
