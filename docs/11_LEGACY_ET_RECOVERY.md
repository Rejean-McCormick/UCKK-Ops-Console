# 11 — Legacy et récupération

## 1. Rôle de ce document

Ce document définit comment la nouvelle application doit traiter :

```text
les anciens outils ;
les scripts historiques ;
les scripts de test ;
les outils de récupération ;
les réparations dangereuses ;
les workflows normaux.
```

Application concernée :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Ce document sert à empêcher l’IA de réintroduire dans l’application normale des scripts qui ont été créés pour dépanner une situation précise.

Définition :

```text
Legacy = ancien outil conservé pour référence, mais qui ne doit pas être utilisé dans le workflow normal.
```

Définition :

```text
Récupération = action spéciale utilisée quand l’état normal est cassé.
```

Définition :

```text
Workflow normal = suite d’étapes utilisée régulièrement pour faire une opération prévue.
```

Règle principale :

```text
Un outil ancien, temporaire ou dangereux ne doit pas devenir un bouton normal simplement parce qu’il existe.
```

## 2. Problème à éviter

L’ancien environnement contient plusieurs scripts qui se ressemblent, mais qui ne partent pas toujours de la même source et ne produisent pas toujours le même résultat.

Le risque est que l’IA ou l’utilisateur choisisse le mauvais script.

Exemple de problème :

```text
un outil voit 128 références ;
un autre outil n’en voit que 5 ;
un troisième reconstruit des tables ;
un quatrième importe des fichiers media_original ;
l’utilisateur ne sait plus lequel est le workflow normal.
```

Ce document empêche cette confusion.

Règle :

```text
L’existence d’un script ne prouve pas qu’il doit être utilisé.
```

## 3. Classes officielles des outils

Chaque outil, script ou commande doit appartenir à une seule classe officielle :

```text
normal ;
legacy ;
recovery ;
test.
```

Aucune autre classe ne doit être inventée sans modification documentée de ce fichier.

## 4. Classe `normal`

### 4.1 Définition

```text
Normal = outil utilisé dans le workflow quotidien.
```

Un outil normal est :

```text
documenté ;
nommé clairement ;
appelé par l’interface normale ;
sécurisé selon son niveau de danger ;
capable de produire un rapport ;
basé sur une source de vérité claire ;
idempotent quand il applique des données.
```

Définition :

```text
Idempotent = une action peut être relancée sans créer de doublons ou de dégâts.
```

### 4.2 Exemples d’outils normaux attendus

Exemples conceptuels :

```text
Vérifier les chemins locaux
Synchroniser source vers Moodle local
Vérifier Git
Publier sur serveur
Vérifier uckk.org
Vérifier manifeste Médiathèque
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
```

### 4.3 Règle

Un outil normal peut apparaître dans les onglets normaux :

```text
Accueil ;
Local ;
Git ;
Serveur ;
Médiathèque ;
Données Moodle ;
Tests ;
Historique.
```

Mais seulement si l’action correspond au rôle de l’onglet.

## 5. Classe `legacy`

### 5.1 Définition

```text
Legacy = ancien outil conservé pour référence, mais qui ne doit pas être utilisé dans le workflow normal.
```

Un outil legacy peut être utile pour comprendre :

```text
une ancienne décision ;
une ancienne migration ;
un ancien format ;
une ancienne tentative ;
un morceau de logique à réintégrer proprement.
```

Mais il ne doit pas être lancé comme action normale.

### 5.2 Exemples de legacy

Exemples conceptuels :

```text
anciens imports /play ;
scripts final-working ;
scripts sourceitemid0 ;
scripts v9 ;
anciens imports media_original ;
anciens scripts créés pour une migration ponctuelle.
```

### 5.3 Règle

Un outil legacy :

```text
ne va pas dans Accueil ;
ne va pas dans Médiathèque normale ;
ne va pas dans Données Moodle normales ;
ne doit pas être appelé automatiquement par un module normal ;
ne doit pas être présenté comme recommandé.
```

Il peut être conservé dans :

```text
./legacy
```

ou documenté depuis l’onglet :

```text
Récupération
```

mais il ne doit pas être exécuté automatiquement.

## 6. Classe `recovery`

### 6.1 Définition

```text
Recovery / récupération = outil utilisé pour réparer une situation cassée.
```

Une récupération peut modifier beaucoup de données.

Elle peut être utile, mais elle est dangereuse.

### 6.2 Exemples de recovery

Exemples :

```text
wipe ;
rebuild complet ;
restauration depuis sauvegarde ;
reconstruction de tables ;
reconstruction de liens media/media_source ;
reconstruction de collections ;
import depuis une sauvegarde ;
comparaison profonde local/serveur ;
réparation de compteurs ;
copie contrôlée depuis external_work.
```

Définitions :

```text
Wipe = suppression volontaire d’un ensemble de données avant reconstruction.

Rebuild = reconstruction complète d’un état à partir d’une autre source.

Sauvegarde = copie conservée avant une action risquée pour pouvoir revenir en arrière.

Compteur = nombre d’éléments trouvés dans une table, un service ou un rapport.
```

### 6.3 Règle

Un outil recovery doit être isolé dans :

```text
./recovery
```

et dans l’onglet :

```text
Récupération
```

Il ne doit pas apparaître dans les workflows normaux.

### 6.4 Conditions obligatoires

Toute action recovery qui modifie des données doit :

```text
demander confirmation forte ;
exiger ou créer une sauvegarde ;
produire un rapport ;
indiquer la source utilisée ;
indiquer la cible modifiée ;
indiquer les données supprimées, modifiées ou reconstruites ;
indiquer comment vérifier le résultat.
```

Message obligatoire :

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

## 7. Classe `test`

### 7.1 Définition

```text
Test = outil utilisé pour vérifier une hypothèse technique.
```

Un test peut servir pendant le développement ou le diagnostic.

Il ne doit pas devenir un workflow normal.

### 7.2 Exemples de tests

Exemples :

```text
test d’écriture dans la base Moodle ;
test de connexion DB ;
test de schéma ;
test AJAX brut ;
test d’un mapping ;
test d’un service Moodle ;
test d’un import minimal.
```

Définition :

```text
Mapping = correspondance entre une donnée source et une donnée cible.
```

### 7.3 Règle

Un outil test :

```text
ne doit pas apparaître dans Accueil ;
ne doit pas être présenté comme solution normale ;
doit être clairement nommé comme test ;
doit être isolé des workflows normaux.
```

Si un test devient utile de façon permanente, il doit être transformé en action normale documentée.

## 8. Dossiers officiels

Les dossiers officiels sont :

```text
./legacy
./recovery
```

### 8.1 Dossier `legacy`

Rôle :

```text
Contenir les anciens outils conservés pour référence.
```

Il peut contenir des sous-dossiers par domaine.

Exemples :

```text
legacy/mediatheque
legacy/moodle-data
legacy/imports
legacy/play
```

### 8.2 Dossier `recovery`

Rôle :

```text
Contenir les outils de réparation.
```

Il peut contenir des sous-dossiers par domaine.

Exemples :

```text
recovery/mediatheque
recovery/moodle-data
recovery/server
```

### 8.3 Règle

Les dossiers `legacy` et `recovery` ne sont pas des endroits où mettre du code normal.

Si un outil devient normal, il doit être intégré dans :

```text
./modules
```

et documenté dans le contrat correspondant.

## 9. Relation avec les modules normaux

Les modules normaux vivent dans :

```text
./modules
```

Exemples :

```text
modules/local
modules/git
modules/server
modules/mediatheque
modules/moodle-data
modules/tests
```

Règle :

```text
Un module normal ne doit pas appeler directement un outil legacy.
```

Si une logique legacy est nécessaire, elle doit être réécrite ou intégrée proprement dans le module normal.

Définition :

```text
Intégrer proprement = reprendre la logique utile, la sécuriser, la documenter, la configurer et la faire produire des rapports.
```

## 10. Quand un ancien outil peut être réutilisé

Un ancien outil peut être réutilisé comme matière première si :

```text
son rôle est compris ;
sa source de données est claire ;
sa cible est claire ;
ses risques sont identifiés ;
il ne contourne pas le workflow normal ;
il est adapté à la nouvelle configuration ;
il produit des rapports lisibles ;
il respecte les confirmations ;
il est renommé si son ancien nom est ambigu.
```

Règle :

```text
Réutiliser du code n’est pas réutiliser le vieux workflow.
```

## 11. Quand un ancien outil ne doit pas être réutilisé

Un ancien outil ne doit pas être réutilisé comme action normale s’il :

```text
lit une source partielle ;
fait un wipe ;
fait un rebuild complet ;
importe media_original pour des références externes ;
exporte depuis la page publique comme source de vérité ;
copie des tables directement ;
utilise des chemins codés en dur ;
écrit dans la base Moodle sans simulation ;
écrit dans le serveur sans confirmation ;
ne produit pas de rapport lisible ;
ne distingue pas local et serveur.
```

Définition :

```text
Source partielle = source incomplète qui peut écraser ou réduire un état correct.
```

## 12. Médiathèque : règles legacy et recovery

La Médiathèque a une règle stricte.

Workflow normal :

```text
manifeste → simulation → appliquer → vérifier
```

Source de vérité normale :

```text
Manifeste Médiathèque
```

Sont legacy ou recovery, pas normal :

```text
export depuis page publique ;
export depuis service public comme source ;
dump SQL brut ;
copie directe de tables ;
import media_original ;
wipe/reimport ;
rebuild complet depuis une table ;
anciens scripts /play non intégrés ;
scripts datés créés pendant une réparation.
```

Règle :

```text
Aucun de ces chemins ne doit être appelé par l’onglet Médiathèque normal.
```

## 13. Données Moodle : règles legacy et recovery

Workflow normal :

```text
fichier source → validation → simulation → appliquer → vérifier
```

Sont legacy ou recovery, pas normal :

```text
SQL brut ;
dump SQL ;
copie directe de tables ;
réparation manuelle ;
scripts non classés ;
imports sans simulation ;
application silencieuse dans la base Moodle.
```

Règle :

```text
L’onglet Données Moodle ne doit pas lancer d’outil non classé.
```

## 14. Serveur : règles legacy et recovery

Le serveur public est :

```text
uckk.org
```

Les actions serveur normales doivent passer par :

```text
Git ;
source serveur ;
runtime serveur ;
mise à jour Moodle si nécessaire ;
purge caches ;
vérification.
```

Sont recovery, pas normal :

```text
modification manuelle directe sur serveur ;
copie de fichiers hors workflow ;
remplacement massif non documenté ;
restauration serveur ;
rollback manuel non documenté ;
suppression de runtime ;
réparation sans rapport.
```

Définition :

```text
Rollback = retour à une version précédente après un problème.
```

Un rollback peut être recovery ou action serveur spécialisée, mais il doit être documenté avant d’être codé.

## 15. Classification obligatoire avant utilisation

Avant qu’un outil existant soit utilisé par la nouvelle app, il doit être classé.

Fiche minimale de classification :

```text
Nom de l’outil :
Chemin :
Classe : normal / legacy / recovery / test
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

Règle :

```text
Un outil non classé ne doit pas être appelé par l’interface.
```

## 16. Niveaux de danger

Les outils legacy et recovery doivent respecter les niveaux du document :

```text
docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md
```

Rappel des niveaux :

```text
0 — Navigation
1 — Lecture / vérification
2 — Modification locale simple
3 — Git
4 — Base Moodle locale
5 — Serveur public
6 — Base Moodle serveur
7 — Récupération
```

Règle :

```text
Tout outil recovery est niveau 7 s’il peut modifier ou reconstruire des données.
```

## 17. Confirmation forte

Une confirmation forte est obligatoire pour recovery.

Message obligatoire :

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

Si l’action est destructive :

```text
Cette action peut supprimer, remplacer ou reconstruire des données existantes.
Elle ne doit être lancée que si une sauvegarde existe.
Continuer ?
```

Définition :

```text
Destructive = qui peut supprimer, remplacer ou reconstruire des données existantes.
```

## 18. Sauvegarde obligatoire

Une sauvegarde est obligatoire avant toute action recovery destructive.

Actions qui exigent une sauvegarde :

```text
wipe ;
rebuild ;
restauration ;
copie directe de tables ;
suppression massive ;
reconstruction de plusieurs tables ;
remplacement de données serveur ;
réparation qui écrit dans la base Moodle serveur.
```

Règle :

```text
Pas de sauvegarde vérifiée = pas d’action destructive.
```

Un simple avertissement ne suffit pas.

## 19. Rapports obligatoires

Toute action recovery doit produire un rapport.

Le rapport doit contenir :

```text
raison de la récupération ;
outil utilisé ;
classe de l’outil ;
niveau de danger ;
sauvegarde utilisée ou créée ;
source lue ;
cible modifiée ;
données créées ;
données mises à jour ;
données supprimées ;
avertissements ;
erreurs ;
résultat final ;
prochaine vérification ;
moyen de retour arrière si possible.
```

Définition :

```text
Retour arrière = façon de revenir à l’état précédent.
```

## 20. Ouvrir un outil legacy

L’application peut permettre d’ouvrir le dossier legacy.

Bouton possible :

```text
Ouvrir dossier legacy
```

Cette action est une navigation.

Elle ne lance rien.

Règle :

```text
Ouvrir un outil legacy ne signifie pas le recommander.
```

Si l’utilisateur veut lancer un outil legacy, l’application doit exiger une classification ou une migration vers normal/recovery.

## 21. Ouvrir un outil recovery

L’application peut permettre d’ouvrir le dossier recovery.

Bouton possible :

```text
Ouvrir dossier recovery
```

Cette action est une navigation.

Elle ne lance rien.

L’exécution d’une récupération doit passer par une action documentée.

## 22. Interdiction des boutons vagues

Les boutons suivants sont interdits :

```text
Run old import
Fix
Repair
Rebuild
Wipe
Sync old
Import legacy
Use previous script
```

Boutons acceptables seulement si documentés :

```text
Comparer Médiathèque locale et serveur
Créer sauvegarde avant récupération
Reconstruire collections Médiathèque
Restaurer depuis sauvegarde sélectionnée
```

Règle :

```text
Un bouton recovery doit dire ce qu’il répare, quelle cible il touche et quel danger il représente.
```

## 23. Règle contre les outils datés comme workflows

Un outil daté est un outil créé pour une intervention précise dans le temps.

Exemples de noms datés :

```text
mediatheque-sync-20260609_104050
mediatheque-public-sync-20260609_104704
mediatheque-rebuild-from-external-work-20260609_105041
```

Définition :

```text
Outil daté = outil dont le nom indique qu’il a été créé pour une intervention ponctuelle.
```

Règle :

```text
Un outil daté ne doit pas devenir workflow normal.
```

Il doit être classé legacy ou recovery.

## 24. Règle contre `final-working`

Un fichier nommé `final-working` est ambigu.

Il signifie seulement qu’à un moment donné il a semblé fonctionner.

Il ne prouve pas que le workflow est correct.

Règle :

```text
Un outil nommé final-working doit être classé avant toute réutilisation.
```

Il doit être renommé s’il devient un outil normal.

## 25. Règle contre les versions `v9`, `old`, `copy`, `backup`

Les noms suivants indiquent un risque de confusion :

```text
v9
old
copy
backup
final
working
tmp
test
sourceitemid0
```

Règle :

```text
Un outil normal ne doit pas garder un nom de dépannage ou de version historique.
```

Si le code est repris, il doit recevoir un nom fonctionnel clair.

## 26. Nommer les outils normaux

Un outil normal doit avoir un nom qui indique son rôle.

Exemples :

```text
Sync-UckkMediatheque
Validate-UckkMediathequeManifest
Apply-UckkMoodleData
Test-UckkServerPages
```

Le nom doit éviter :

```text
final ;
working ;
old ;
v9 ;
tmp ;
fix ;
random ;
manual.
```

## 27. Promotion d’un outil legacy vers normal

Un outil legacy peut devenir normal seulement si toutes les conditions sont remplies :

```text
source de vérité claire ;
cible claire ;
configuration centralisée ;
pas de chemins codés en dur ;
simulation si nécessaire ;
confirmations selon danger ;
rapports lisibles ;
logs techniques ;
séparation local/serveur ;
idempotence si données ;
tests minimaux ;
documentation mise à jour.
```

Définition :

```text
Promotion = changement de classe d’un outil vers un statut plus officiel.
```

Règle :

```text
La promotion d’un outil legacy n’est pas automatique.
```

## 28. Déclassement d’un outil normal

Un outil normal doit être déclassé si :

```text
il devient ambigu ;
il est remplacé par un workflow plus clair ;
il produit des résultats partiels dangereux ;
il ne respecte plus les confirmations ;
il contourne une source de vérité ;
il crée des doublons ;
il dépend d’un état temporaire.
```

Définition :

```text
Déclassement = retrait d’un outil du workflow normal.
```

Classes possibles après déclassement :

```text
legacy ;
recovery ;
test ;
supprimé si décision explicite.
```

## 29. Suppression d’un ancien outil

La suppression d’un ancien outil n’est pas obligatoire au départ.

Mais si un outil est supprimé, il faut conserver une trace de la décision.

Trace minimale :

```text
nom de l’outil ;
raison de suppression ;
outil ou workflow qui le remplace ;
date ;
risques connus.
```

Règle :

```text
Ne pas supprimer un outil historique sans comprendre son rôle.
```

## 30. Relation avec l’interface Accueil

L’Accueil ne doit jamais afficher :

```text
legacy ;
recovery ;
wipe ;
rebuild ;
dump SQL ;
copie directe de tables ;
réparation automatique ;
scripts datés.
```

Règle :

```text
L’Accueil est pour les opérations fréquentes et sûres.
```

## 31. Relation avec l’onglet Récupération

L’onglet Récupération peut afficher :

```text
actions recovery documentées ;
liens vers rapports recovery ;
liens vers dossiers legacy ;
liens vers dossiers recovery ;
comparaisons et diagnostics.
```

Mais il ne doit pas transformer les anciens scripts en boutons sans contrat.

Règle :

```text
Même dans Récupération, une action destructive doit être documentée, confirmée et rapportée.
```

## 32. Relation avec les rapports

Un rapport doit indiquer si un outil est :

```text
normal ;
legacy ;
recovery ;
test.
```

Pour recovery, le rapport doit indiquer :

```text
niveau de danger : 7 — Récupération
confirmation forte : oui
sauvegarde : oui / non
```

Si une action legacy est ouverte mais non exécutée, le rapport n’est pas obligatoire.

Si une action legacy est exécutée, elle doit être traitée comme recovery sauf classification contraire.

## 33. Protection contre les sources partielles

Une source partielle est dangereuse.

Définition :

```text
Source partielle = source incomplète qui peut écraser ou réduire un état correct.
```

Exemple :

```text
un export public local qui ne contient que 5 références alors que la Médiathèque complète en contient 128.
```

Règle :

```text
Une source partielle ne doit pas être utilisée comme source normale.
```

Si un outil lit une source partielle, il est recovery ou test, pas normal.

## 34. Protection contre la confusion local/serveur

Un ancien outil qui ne distingue pas clairement local et serveur est dangereux.

Règle :

```text
Un outil doit dire sa cible avant d’être utilisable.
```

Cibles possibles :

```text
local ;
serveur ;
base Moodle locale ;
base Moodle serveur ;
fichiers locaux ;
fichiers serveur.
```

Un outil qui modifie le serveur sans le dire clairement ne peut pas être normal.

## 35. Protection contre les chemins codés en dur

Un outil legacy peut contenir des chemins codés en dur.

Définition :

```text
Chemin codé en dur = chemin écrit directement dans le code au lieu d’être lu depuis la configuration.
```

Règle :

```text
Un outil normal ne doit pas dépendre de chemins codés en dur.
```

Avant promotion, les chemins doivent venir de :

```text
./config/uckk-ops-console.config.json
```

## 36. Protection contre la duplication

La duplication crée de la confusion.

Définition :

```text
Duplication = plusieurs outils qui font presque la même tâche avec des différences difficiles à comprendre.
```

Règle :

```text
Un domaine doit avoir un seul chemin normal.
```

Pour la Médiathèque :

```text
manifeste → simulation → appliquer → vérifier
```

Pour Données Moodle :

```text
fichier source → validation → simulation → appliquer → vérifier
```

Les autres chemins doivent être classés.

## 37. Tableau de décision

| Question | Si oui | Classe probable |
|---|---|---|
| Est-ce utilisé tous les jours ou régulièrement ? | Oui | normal |
| Est-ce un ancien script conservé pour référence ? | Oui | legacy |
| Est-ce que cela répare un état cassé ? | Oui | recovery |
| Est-ce que cela vérifie une hypothèse technique ? | Oui | test |
| Est-ce que cela supprime ou reconstruit des données ? | Oui | recovery |
| Est-ce que cela lit une source partielle ? | Oui | recovery ou test |
| Est-ce que cela utilise SQL brut ? | Oui | recovery ou test |
| Est-ce que cela copie des tables ? | Oui | recovery |
| Est-ce que cela ne produit pas de rapport ? | Oui | pas normal |
| Est-ce que la cible est ambiguë ? | Oui | pas normal |

## 38. Messages obligatoires

### 38.1 Legacy

Message si l’utilisateur tente d’utiliser un outil legacy :

```text
Cet outil est classé legacy.
Il est conservé pour référence, mais ne fait pas partie du workflow normal.
Pour l’utiliser, il doit être reclassé ou intégré proprement.
```

### 38.2 Recovery

Message avant récupération :

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

### 38.3 Test

Message pour un test technique :

```text
Cet outil est un test technique.
Il sert au diagnostic et ne doit pas être utilisé comme workflow normal.
```

### 38.4 Action refusée

Message si une action ne respecte pas ce contrat :

```text
Action refusée.
Cause : l’outil n’est pas classé comme action normale ou récupération documentée.
Prochaine étape : classer l’outil ou utiliser le workflow normal.
```

## 39. Exemple de classification Médiathèque

Exemple :

```text
Nom de l’outil : export depuis service public local
Classe : recovery ou test
Domaine : Médiathèque
Source lue : page/service public local
Cible modifiée : aucune si export seulement ; base Moodle serveur si utilisé ensuite
Danger : source partielle possible
Peut apparaître dans l’interface normale : non
Raison : le service public peut ne retourner que 5 références et ne doit pas être source de vérité.
```

Exemple :

```text
Nom de l’outil : Sync-UckkMediatheque
Classe : normal
Domaine : Médiathèque
Source lue : manifeste Médiathèque
Cible modifiée : base Moodle locale ou serveur selon action
Danger : niveau 4 ou 6 selon cible
Simulation possible : oui
Rapport requis : oui
Peut apparaître dans l’interface normale : oui
Raison : correspond au workflow officiel manifeste → simulation → appliquer → vérifier.
```

## 40. Exemple de classification Données Moodle

Exemple :

```text
Nom de l’outil : import SQL direct de cours
Classe : recovery
Domaine : Données Moodle
Source lue : dump SQL
Cible modifiée : base Moodle
Danger : copie brute et identifiants Moodle possiblement incompatibles
Peut apparaître dans l’interface normale : non
```

Exemple :

```text
Nom de l’outil : Appliquer cours serveur
Classe : normal
Domaine : Données Moodle
Source lue : fichier JSON versionné
Cible modifiée : base Moodle serveur
Danger : niveau 6
Simulation possible : oui
Rapport requis : oui
Peut apparaître dans l’interface normale : oui
```

## 41. Anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
appeler un script legacy depuis un module normal ;
placer un outil recovery dans l’Accueil ;
utiliser un outil daté comme workflow normal ;
lancer un script non classé ;
réutiliser un vieux nom ambigu ;
cacher un wipe ou rebuild derrière “fix” ;
copier des tables comme synchronisation normale ;
utiliser un export public comme source normale ;
réintroduire media_original pour les références externes ;
ignorer l’exigence de sauvegarde ;
ignorer la confirmation forte ;
oublier le rapport recovery ;
supprimer un ancien outil sans trace de décision ;
créer plusieurs chemins normaux pour la même tâche.
```

Si un ancien outil semble nécessaire, l’IA doit d’abord proposer sa classification.

## 42. Résumé obligatoire

Classes officielles :

```text
normal ;
legacy ;
recovery ;
test.
```

Règles finales :

```text
Un outil normal est documenté, clair, sécurisé et rapporté.
Un outil legacy est conservé, mais non recommandé.
Un outil recovery répare, mais reste dangereux.
Un outil test diagnostique, mais ne devient pas workflow normal.
Un outil non classé ne doit pas être lancé par l’interface.
Aucun ancien script ne doit contaminer les workflows normaux.
