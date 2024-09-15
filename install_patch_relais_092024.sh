
#!/bin/sh

#sauvegarde
mv /usr/share/svxlink/events.d/local/Logic.tcl /usr/share/svxlink/events.d/local/Logic.old
cp /etc/svxlink/svxlink.cfg /etc/svxlink/svxlink.old

#copie des fichiers sons

cd /usr/share/svxlink/sounds
git clone https://github.com/F8ASB/fr_FR_Agnes.git

#sauvegarde des anciens fichiers
mv /usr/share/svxlink/sounds/fr_FR /usr/share/svxlink/sounds/fr_FR_Old 
mv /usr/share/svxlink/sounds/fr_FR_Agnes /usr/share/svxlink/sounds/fr_FR 

#recuperation de l'indicatif 
indicatif=$(grep CALLSIGN /etc/svxlink/svxlink.cfg | head -1| sed 's/.\{9\}//')
echo "Indicatif du Hotspot: "$indicatif

#changement du nom du repertoire sons perso
mv /usr/share/svxlink/sounds/fr_FR/INDICATIF_RELAIS /usr/share/svxlink/sounds/fr_FR/$indicatif

#copie des fichiers Logic et RepeaterLogic dans le dossier local
wget -N -P /usr/share/svxlink/events.d/local https://raw.githubusercontent.com/F8ASB/patch_relais/main/RepeaterLogic.tcl
wget -N -P /usr/share/svxlink/events.d/local https://raw.githubusercontent.com/F8ASB/patch_relais/main/Logic.tcl
wget -N -P /etc/svxlink/ https://raw.githubusercontent.com/F8ASB/patch_relais/main/data_reapeater.cfg

#personnalisation du svxlink.cfg pour le mode relais
sed -i -r 's/.* LOGICS=SimplexLogic,ReflectorLogic.*/ LOGICS=RepeaterLogic,ReflectorLogic/g' /etc/svxlink/svxlink.cfg

#ajout indicatif
sed -i "s/^CALLSIGN=.*/CALLSIGN=$indicatif/" /etc/svxlink/data_reapeater.cfg

#ajout des parametres RepeaterLogic dans svxlink.cfg
sed -i '/LINKS=ALLlink/ { n ; 
r /etc/svxlink/data_reapeater.cfg
}' /etc/svxlink/svxlink.cfg

#changement des parametres RepeaterLogic:
sed -i 's/LOGICS=SimplexLogic,ReflectorLogic/LOGICS=RepeaterLogic,ReflectorLogic/' /etc/svxlink/svxlink.cfg
sed -i 's/CONNECT_LOGICS=SimplexLogic:434MHZ:945,ReflectorLogic/CONNECT_LOGICS=RepeaterLogic:434MHZ:945,ReflectorLogic/' /etc/svxlink/svxlink.cfg
sed -i 's/TIMEOUT=300/TIMEOUT=0/' /etc/svxlink/svxlink.cfg
