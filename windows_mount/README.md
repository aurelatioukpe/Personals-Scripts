
# Script de Montage Windows sous Linux

## Description

Ce script Bash permet de monter facilement une partition Windows (format NTFS) sous Linux, même en cas de problèmes tels que l'hibernation ou un système de fichiers non propre. Il guide l'utilisateur à travers les étapes nécessaires pour monter la partition et configure le montage automatique au démarrage si désiré.

---

## Fonctionnalités

1. Détection automatique des partitions NTFS.
2. Vérification de l'état du système de fichiers avec `ntfsfix`.
3. Gestion des erreurs liées à l'hibernation ou au démarrage rapide de Windows.
4. Création automatique du point de montage si nécessaire.
5. Montage en lecture/écriture (ou en lecture seule en cas de problème).
6. Configuration du montage automatique via `/etc/fstab`.

---

## Prérequis

- **Paquet `ntfs-3g` installé** : Utilisé pour monter les partitions NTFS en lecture/écriture.
  ```bash
  sudo apt update && sudo apt install ntfs-3g
  ```

---

## Instructions d'utilisation

### 1. Lancer le script
Téléchargez le script et donnez lui les permissions avec :
```bash
chmod +x mount_windows.sh
```
Puis exécutez le script avec :
```bash
./mount_windows.sh
```

### 2. Étapes guidées par le script
- **Sélectionnez la partition** : Le script liste toutes les partitions NTFS détectées.
- **Indiquez un point de montage** : Si le répertoire n'existe pas, il sera créé.
- **Résolution des erreurs** :
  - Si Windows est en hibernation, désactivez-la avec la commande suivante sous Windows :
    ```cmd
    powercfg /h off
    ```
  - Assurez-vous que le disque est correctement éteint via Windows (pas en mode "démarrage rapide").

### 3. Montage automatique (optionnel)
Le script peut ajouter la partition au fichier `/etc/fstab` pour un montage automatique au démarrage :
- Le fichier est modifié uniquement si l'utilisateur accepte.
- L'UUID de la partition est utilisé pour un montage fiable.

---

## Exemple de sortie

```
===============================
   Script de montage Windows   
===============================
Recherche des partitions Windows (NTFS)...
Partitions détectées :
sda1 ntfs 100G /mnt/windows

Entrez le nom du périphérique (ex: sda1, nvme0n1p3) : sda1
Entrez le chemin du point de montage (par exemple, /mnt/windows) : /mnt/windows
Vérification de l'état du système de fichiers...
Partition montée avec succès en lecture/écriture à /mnt/windows.
Voulez-vous que cette partition soit montée automatiquement au démarrage ? (oui/non) : oui
Entrée ajoutée avec succès à /etc/fstab.
```

---

## Dépannage

- **"Windows is hibernated"** :
  - Désactivez l'hibernation et le démarrage rapide sous Windows.
- **"Impossible de récupérer l'UUID"** :
  - Vérifiez que le périphérique sélectionné existe et contient un système de fichiers valide.

---

## Avertissements

- Modifiez `/etc/fstab` avec prudence. Une erreur peut empêcher votre système de démarrer correctement.
- Utilisez ce script uniquement si vous comprenez les implications des montages NTFS sous Linux.

---

## Auteur
GNANDI Salem
