#!/bin/bash

echo "==============================="
echo "   Script de montage Windows   "
echo "==============================="

# Lister les partitions détectées
echo "Recherche des partitions Windows (NTFS)..."
PARTITIONS=$(lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT -r | grep -i ntfs)

if [ -z "$PARTITIONS" ]; then
    echo "Aucune partition Windows (NTFS) détectée."
    exit 1
fi

echo "Partitions détectées :"
echo "$PARTITIONS"
echo

while true; do
    read -p "Entrez le nom du périphérique (ex: sda1, nvme0n1p3) : " DEVICE_NAME
    DEVICE_PATH="/dev/$DEVICE_NAME"

    if [ -b "$DEVICE_PATH" ]; then
        echo "Périphérique sélectionné : $DEVICE_PATH"
        break
    else
        echo "Erreur : Le périphérique $DEVICE_PATH n'existe pas. Réessayez."
    fi
done

read -p "Entrez le chemin du point de montage (par exemple, /mnt/windows) : " MOUNT_POINT

if [ ! -d "$MOUNT_POINT" ]; then
    echo "Création du point de montage à $MOUNT_POINT..."
    sudo mkdir -p "$MOUNT_POINT"
fi

echo "Vérification de l'état du système de fichiers..."
NTFSFIX_OUTPUT=$(sudo ntfsfix "$DEVICE_PATH" 2>&1)

if echo "$NTFSFIX_OUTPUT" | grep -q "Windows is hibernated"; then
    echo "Erreur : Windows est en hibernation. Veuillez désactiver l'hibernation et le démarrage rapide sous Windows."
    echo "Pour désactiver l'hibernation :"
    echo " Essayez powercfg /h off sous Windows dans cmd"
    exit 1
elif echo "$NTFSFIX_OUTPUT" | grep -q "Refusing to operate"; then
    echo "Erreur : Le disque contient un système de fichiers non propre."
    echo "Veuillez démarrer sur Windows, réparer le disque, puis l'éteindre correctement."
    exit 1
fi

echo "Tentative de montage en lecture/écriture..."
if sudo mount -t ntfs-3g "$DEVICE_PATH" "$MOUNT_POINT"; then
    echo "Partition montée avec succès en lecture/écriture à $MOUNT_POINT."
else
    echo "Échec du montage en lecture/écriture. Tentative de montage en lecture seule..."
    if sudo mount -t ntfs-3g -o ro "$DEVICE_PATH" "$MOUNT_POINT"; then
        echo "Partition montée en lecture seule à $MOUNT_POINT."
    else
        echo "Échec du montage en lecture seule. Veuillez vérifier le périphérique ou les permissions."
        exit 1
    fi
fi

echo
read -p "Voulez-vous que cette partition soit montée automatiquement au démarrage ? (oui/non) : " AUTO_MOUNT
if [[ "$AUTO_MOUNT" =~ ^[Oo][Uu][Ii]$ ]]; then
    UUID=$(blkid -s UUID -o value "$DEVICE_PATH")
    
    if [ -z "$UUID" ]; then
        echo "Erreur : Impossible de récupérer l'UUID du périphérique. Annulation."
        exit 1
    fi
    
    echo "Ajout de l'entrée dans /etc/fstab..."
    FSTAB_ENTRY="UUID=$UUID $MOUNT_POINT ntfs-3g defaults 0 0"
    if ! grep -q "$UUID" /etc/fstab; then
        echo "$FSTAB_ENTRY" | sudo tee -a /etc/fstab > /dev/null
        echo "Entrée ajoutée avec succès à /etc/fstab."
    else
        echo "Cette partition est déjà configurée pour le montage automatique."
    fi
fi

echo "Contenu de $MOUNT_POINT :"
ls "$MOUNT_POINT"

exit 0
