
#!/bin/sh

#sauvegarde
mv /usr/share/svxlink/events.d/local/Logic.tcl /usr/share/svxlink/events.d/local/Logic.old
cp /etc/spotnik/svxlink.cfg /etc/spotnik/svxlink.old

#copie des fichiers sons

cd /usr/share/svxlink/sounds
git clone https://github.com/F8ASB/fr_FR_Agnes.git

#sauvegarde des anciens fichiers
mv /usr/share/svxlink/sounds/fr_FR /usr/share/svxlink/sounds/fr_FR_Old 
mv /usr/share/svxlink/sounds/fr_FR_Agnes /usr/share/svxlink/sounds/fr_FR 

#recuperation de l'indicatif 
indicatif=$(grep CALLSIGN /etc/spotnik/svxlink.cfg | head -1| sed 's/.\{9\}//')
echo "Indicatif du Hotspot: "$indicatif

#changement du nom du repertoire sons perso
mv /usr/share/svxlink/sounds/fr_FR/INDICATIF_RELAIS /usr/share/svxlink/sounds/fr_FR/$indicatif

#copie des fichiers Logic et RepeaterLogic dans le dossier local
wget -N -P /usr/share/svxlink/events.d/local https://raw.githubusercontent.com/F8ASB/patch_relais/main/RepeaterLogic.tcl
wget -N -P /usr/share/svxlink/events.d/local https://raw.githubusercontent.com/F8ASB/patch_relais/main/Logic.tcl
wget -N -P /etc/spotnik/ https://raw.githubusercontent.com/F8ASB/patch_relais/main/data_reapeater.cfg

#personnalisation du svxlink.cfg pour le mode relais
sed -i -r 's/.* LOGICS=SimplexLogic,ReflectorLogic.*/ LOGICS=RepeaterLogic,ReflectorLogic/g' /etc/spotnik/svxlink.cfg

#ajout indicatif
sed -i "s/^CALLSIGN=.*/CALLSIGN=$indicatif/" /etc/spotnik/data_reapeater.cfg

#ajout des parametres RepeaterLogic dans svxlink.cfg
sed -i '/LINKS=ALLlink/ { n ; 
r /etc/spotnik/data_reapeater.cfg
}' /etc/spotnik/svxlink.cfg

