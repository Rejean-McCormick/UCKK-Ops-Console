# Legacy — anciens outils conservés pour référence

## Rôle de ce dossier

Ce dossier contient les anciens outils, scripts ou fragments de code conservés pour comprendre l’historique du projet UCKK.

Ce dossier n’est pas un dossier de workflows normaux.

Définition :

```text
Legacy = ancien outil conservé pour référence, mais qui ne doit pas être utilisé dans le workflow normal.
```

## Règle principale

```text
Un fichier placé dans legacy/ ne doit pas être lancé par l’application normale.
```

Il peut être lu pour comprendre une ancienne logique.

Il ne doit pas être utilisé directement comme solution officielle.

## Ce qui peut être placé ici

Exemples :

```text
anciens scripts d’import ;
anciens scripts Médiathèque ;
anciens scripts /play ;
anciens scripts final-working ;
anciens scripts sourceitemid0 ;
anciens scripts v9 ;
anciens fichiers de migration ponctuelle ;
anciens essais conservés pour analyse.
```

## Ce qui ne doit pas être placé ici

Ne pas placer ici :

```text
code normal de l’application ;
module actif ;
configuration principale ;
rapport ;
log ;
sauvegarde active ;
outil recovery actif.
```

Le code normal doit aller dans :

```text
modules/
lib/
app/
```

Les outils de récupération doivent aller dans :

```text
recovery/
```

## Interdictions

Un outil legacy ne doit pas :

```text
apparaître dans l’Accueil ;
être appelé par un bouton normal ;
être appelé automatiquement au démarrage ;
être utilisé comme source de vérité ;
modifier uckk.org ;
écrire dans la base Moodle ;
remplacer le workflow normal ;
être présenté comme recommandé.
```

## Avant toute réutilisation

Avant de réutiliser un outil legacy, il faut le classer.

Fiche minimale :

```text
Nom de l’outil :
Chemin :
Classe proposée : normal / legacy / recovery / test
Domaine :
Source lue :
Cible modifiée :
Modifie des données : oui / non
Niveau de danger :
Simulation possible : oui / non
Sauvegarde requise : oui / non
Rapport requis : oui / non
Peut apparaître dans l’interface normale : oui / non
Raison :
```

## Si un outil legacy devient utile

Un outil legacy peut inspirer un nouveau module normal.

Mais il doit être réintégré proprement.

Définition :

```text
Réintégrer proprement = reprendre la logique utile, la sécuriser, la documenter, la configurer et la faire produire des rapports.
```

Conditions minimales :

```text
source de vérité claire ;
cible claire ;
configuration centralisée ;
pas de chemins codés en dur ;
simulation si nécessaire ;
confirmations selon danger ;
rapports lisibles ;
logs techniques séparés ;
séparation local/serveur ;
documentation mise à jour.
```

## Règle finale

```text
Legacy sert à comprendre.
Legacy ne sert pas à piloter l’application.
```
