#!/usr/bin/env bash

# Crée les répertoires nécessaires
mkdir -p include src

# Crée les fichiers
touch src/main.c include/my.h

# Ouvre le fichier include/my.h dans VSCode
code include/my.h &

# Attendre que VSCode soit lancé avant de continuer (ajuster le délai si nécessaire)
sleep 5

# Utilisation de xdotool pour envoyer des raccourcis clavier
xdotool key --clearmodifiers Ctrl+Shift+h
sleep 0.5
xdotool key --clearmodifiers Return
sleep 0.5
xdotool key --clearmodifiers Return
sleep 0.5
xdotool key --clearmodifiers Return

# Ouvre src/main.c dans VSCode
code src/main.c &

# Attendre un peu que VSCode soit prêt à recevoir les commandes
sleep 2

# Utilisation de xdotool pour envoyer des raccourcis clavier à main.c
xdotool key --clearmodifiers Ctrl+Shift+h
sleep 0.5
xdotool key --clearmodifiers Return
sleep 0.5
xdotool key --clearmodifiers Return

# Message indiquant que le dépôt a été initialisé
echo "Repository initialized!"

# Demander à l'utilisateur s'il souhaite générer le Makefile
read -p "Do you want to generate your Makefile right now? (y/n): " answer

# Vérifie la réponse de l'utilisateur
if [[ "$answer" =~ ^[Yy]$ ]]; then
    # Appel à la génération du Makefile
    genmake
fi

# Organiser le dépôt
repo_organizer
