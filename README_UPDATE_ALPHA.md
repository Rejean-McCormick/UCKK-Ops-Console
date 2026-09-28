# Mise à jour Ops Console — diagnostic PS7 + Moodle instable

Appliquer cet overlay sur la version Ops Console verbose/switcher courante.

Changements :
- diagnostic Moodle local lit `version.php` et affiche version/release/branche/maturité ;
- Alpha/Beta/RC sont signalés comme versions instables ;
- l'upgrade local ajoute `--allow-unstable` uniquement après la confirmation normale de l'action ;
- la maturité, le flag et la commande finale sont présents dans les résultats verboses/rapports/logs ;
- `tools/Diagnose-UckkMoodleLocal.ps1` fournit le même diagnostic en PowerShell 7 standalone et lecture seule.

Aucune politique PowerShell globale n'est changée.
