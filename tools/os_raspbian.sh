#!/bin/bash

# Définition de la fonction os_raspbian
function os_raspbian()
{
	raspbian_check=$(cat /etc/*-release | grep "ID=raspbian" | wc -l)
	arm_check=$(uname -a | egrep "aarch64|arm64|armv7" | wc -l)
	if [ ${raspbian_check} == 1 ] || [ ${arm_check} == 1 ]
	then
		return 0  # Système est Raspbian ou ARM
	else
		return 1  # Système n'est pas Raspbian ou ARM
	fi
}

# Appeler la fonction os_raspbian
os_raspbian

# Stocker le code de retour de la fonction
result=$?

# Afficher le code de retour
echo "The return code of os_raspbian() is: ${result}"

# Utiliser le code de retour pour faire une action conditionnelle
if [ ${result} -eq 0 ]; then
	echo "The system is Raspbian or running on ARM architecture."
else
	echo "The system is not Raspbian and not running on ARM architecture."
fi
