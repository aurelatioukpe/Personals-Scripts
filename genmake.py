#!/usr/bin/env python3

import os
import subprocess
import re
from datetime import datetime
from bullet import Bullet, Check
from colorama import Fore, Style

# Configuration des couleurs
GREEN = Fore.GREEN
RED = Fore.RED
CYAN = Fore.CYAN
YELLOW = Fore.YELLOW
RESET = Style.RESET_ALL

def detect_project_name():
    """Détecte le nom du projet depuis Git ou le nom du dossier"""
    try:
        result = subprocess.run(
            ['git', 'config', '--get', 'remote.origin.url'],
            capture_output=True, text=True, check=True
        )
        if result.returncode == 0:
            repo_url = result.stdout.strip()
            project_name = os.path.basename(repo_url)
            return project_name.replace('.git', '')
    except:
        pass
    return os.path.basename(os.getcwd())

def select_files_interactively():
    """Sélection interactive des fichiers C avec Bullet"""
    c_files = []
    for root, dirs, files in os.walk("."):
        for file in files:
            if file.endswith(".c"):
                c_files.append(os.path.join(root, file))

    if not c_files:
        print(f"{RED}Aucun fichier .c trouvé !{RESET}")
        exit(1)

    cli = Bullet(
        prompt = f"{CYAN}Sélectionnez les fichiers sources :{RESET}",
        choices = c_files,
        bullet = "→",
        margin = 2,
        multiselect = True
    )
    return cli.launch()

def select_flags_interactively():
    """Sélection des flags de compilation avec Check"""
    flags = [
        '-Wextra',
        '-Werror',
        '-pedantic',
        '-g (debug)',
        '-O2 (optimisation)',
        '-I./include (headers)'
    ]

    cli = Check(
        prompt = f"{CYAN}Sélectionnez les flags de compilation :{RESET}",
        choices = flags,
        check = "✓",
        margin = 2
    )
    result = cli.launch()
    return [re.sub(r' \(.*?\)', '', flag) for flag in result]

def generate_makefile(project_name, source_files, binary_name, flags, add_tests=False):
    """Génère le contenu du Makefile"""
    current_year = datetime.now().year
    src_lines = ' \\\n\t\t'.join(source_files)

    # Section des tests unitaires
    test_section = ""
    if add_tests:
        test_section = """
# Tests unitaires
TEST_FLAGS = -lcriterion --coverage
TEST_NAME = unit_tests

TESTS = \\
\t\t$(filter-out main.c, $(SRCS)) \\
\t\t$(wildcard tests/*.c)

tests_run: $(TESTS:.c=.o)
\t$(CC) -o $(TEST_NAME) $^ $(TEST_FLAGS)
\t./$(TEST_NAME)

coverage: tests_run
\tgcovr -r . --exclude tests/
\tgcovr -r . --exclude tests/ --branches --html-details coverage.html

.PHONY: tests_run coverage
"""

    makefile_content = f"""##
## EPITECH PROJECT, {current_year}
## {project_name}
## File description:
## Makefile généré automatiquement
##

CC = gcc
RM = rm -f
SRCS = \\
\t\t{src_lines}

OBJS = $(SRCS:.c=.o)
NAME = {binary_name}

CFLAGS = -Wall {' '.join(flags)}

all: $(NAME)

$(NAME): $(OBJS)
\t$(CC) $(OBJS) -o $(NAME) $(CFLAGS)

clean:
\t$(RM) $(OBJS)
\t$(RM) *~
\t$(RM) *.gc*

fclean: clean
\t$(RM) $(NAME)

re: fclean all

{test_section}
.PHONY: all clean fclean re
"""

    with open("Makefile", "w") as f:
        f.write(makefile_content)

def main():
    print(f"{CYAN}=== Générateur de Makefile interactif ==={RESET}")

    # Détection automatique du nom
    auto_project = detect_project_name()
    project_name = input(f"{YELLOW}Nom du projet [{auto_project}]: {RESET}") or auto_project

    # Sélection des fichiers
    use_interactive = input(f"{YELLOW}Voulez-vous sélectionner les fichiers interactivement ? [Y/n]: {RESET}").lower() != 'n'
    source_files = select_files_interactively() if use_interactive else [
        f for f in input(f"{YELLOW}Fichiers sources (séparés par des espaces): {RESET}").split() if f.endswith('.c')
    ]

    if not source_files:
        print(f"{RED}Aucun fichier source sélectionné !{RESET}")
        exit(1)

    # Nom du binaire
    default_binary = project_name.lower().replace(' ', '_')
    binary_name = input(f"{YELLOW}Nom du binaire [{default_binary}]: {RESET}") or default_binary

    # Flags de compilation
    flags = select_flags_interactively()

    # Tests unitaires
    add_tests = input(f"{YELLOW}Ajouter le support des tests unitaires ? [y/N]: {RESET}").lower() == 'y'

    # Génération finale
    generate_makefile(project_name, source_files, binary_name, flags, add_tests)
    print(f"\n{GREEN}✓ Makefile généré avec succès !{RESET}")

if __name__ == "__main__":
    main()
