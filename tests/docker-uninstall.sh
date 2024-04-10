#!/bin/bash

# Fonction pour afficher les erreurs
output_error() {
    echo "Error: $1" >&2
}

# Arrêter le service Docker
sudo systemctl stop docker || { output_error "Failed to stop Docker service."; exit 1; }

# Désactiver le service Docker
sudo systemctl disable docker || { output_error "Failed to disable Docker service."; exit 1; }

# Désinstaller Docker Engine, CLI, et Containerd
sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli containerd containerd.io || { output_error "Failed to purge Docker packages."; exit 1; }

# Supprimer les fichiers de configuration et les données
sudo rm -rf /var/lib/docker /var/lib/containerd || { output_error "Failed to remove Docker data."; exit 1; }

# Supprimer les dépendances inutilisées
sudo apt-get autoremove -y || { output_error "Failed to remove unused dependencies."; exit 1; }

# Supprimer l'utilisateur du groupe Docker
sudo deluser $(whoami) docker || { output_error "Failed to remove user from Docker group."; exit 1; }

# Supprimer le groupe Docker si nécessaire
# sudo groupdel docker || { output_error "Failed to delete Docker group."; exit 1; }

# Redémarrage du système pour appliquer tous les changements
echo "Docker has been uninstalled. Rebooting the system to complete the process."
sudo reboot
