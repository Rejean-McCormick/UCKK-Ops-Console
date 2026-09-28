# 12 — Contrat technique du code

## 1. Rôle de ce document

Ce document définit le contrat technique du code de la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il sert à empêcher l’IA de coder une application qui fonctionne une fois, mais devient ensuite impossible à comprendre, maintenir ou sécuriser.

Il complète les documents précédents :

```text
docs/00_ARCHITECTURE_DES_FICHIERS.md
docs/01_PRINCIPES_DE_L_APPLICATION.md
docs/02_VOCABULAIRE_OBLIGATOIRE.md
docs/03_INTERFACE_ACCUEIL.md
docs/04_INTERFACE_ONGLETS_SPECIALISES.md
docs/05_CONFIGURATION_ET_CHEMINS.md
docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md
docs/07_WORKFLOW_LOCAL_GIT_SERVEUR.md
docs/08_MEDIATHEQUE_CONTRAT.md
docs/09_DONNEES_MOODLE_CONTRAT.md
docs/10_RAPPORTS_LOGS_ERREURS.md
docs/11_LEGACY_ET_RECOVERY.md
```

Ce document est un contrat de construction.

Il n’est pas une liste de tâches.

## 2. Principe central

Le code doit être organisé selon cette règle :

```text
interface mince ;
modules spécialisés ;
configuration centralisée ;
résultats structurés ;
rapports lisibles ;
logs techniques séparés ;
sécurité obligatoire.
```

Définitions :

```text
Interface mince = interface qui affiche, déclenche et résume, mais ne contient pas la logique métier.

Module spécialisé = fichier ou dossier qui gère un seul domaine clair.

Configuration centralisée = chemins, URLs et paramètres lus depuis un fichier de configuration unique.

Résultat structuré = objet de sortie qui décrit le statut, les messages, les changements, les erreurs et le rapport.

Logique métier = règles réelles d’une opération, par exemple appliquer la Médiathèque ou publier sur serveur.
```

Règle :

```text
L’interface ne doit pas devenir le lieu où toute la logique est codée.
```

## 3. Architecture technique officielle

L’architecture officielle est :

```text
UCKK_ops_console/
  README.md
  config/
  docs/
  app/
  lib/
  modules/
  reports/
  logs/
  legacy/
  recovery/
```

Chaque dossier a un rôle précis.

Aucun code normal ne doit être placé directement dans la racine si un dossier officiel existe pour son rôle.

## 4. Rôle du dossier `app/`

Le dossier :

```text
app/
```

contient l’interface visible.

Définition :

```text
Interface visible = fenêtres, onglets, boutons, descriptions, confirmations et zones de résultat que l’utilisateur voit.
```

Le code dans `app/` peut :

```text
charger la configuration ;
afficher les onglets ;
afficher les boutons ;
demander les confirmations ;
appeler les modules ;
afficher les résultats ;
ouvrir les rapports ;
ouvrir les logs si demandé.
```

Le code dans `app/` ne doit pas :

```text
contenir la logique complète de publication serveur ;
contenir la logique complète Médiathèque ;
écrire directement dans la base Moodle ;
exécuter directement une récupération destructive ;
contenir des chemins codés en dur ;
contourner les modules spécialisés.
```

Règle :

```text
Un bouton appelle une fonction d’action.
Il ne contient pas lui-même toute l’action.
```

## 5. Rôle du dossier `lib/`

Le dossier :

```text
lib/
```

contient les fonctions communes utilisées par plusieurs domaines.

Définition :

```text
Fonction commune = fonction réutilisable qui ne dépend pas d’un domaine métier particulier.
```

Exemples de responsabilités de `lib/` :

```text
charger la configuration ;
valider la configuration ;
normaliser les chemins ;
exécuter une commande ;
exécuter une commande SSH ;
créer un résultat structuré ;
écrire un rapport ;
écrire un log ;
demander une confirmation ;
masquer les secrets ;
ouvrir un fichier ou une URL ;
gérer les erreurs.
```

Le dossier `lib/` ne doit pas devenir un fourre-tout.

Définition :

```text
Fourre-tout = fichier ou dossier qui contient des fonctions sans lien clair.
```

Règle :

```text
Si une fonction appartient à un domaine comme Médiathèque ou Git, elle va dans modules/, pas dans lib/.
```

## 6. Rôle du dossier `modules/`

Le dossier :

```text
modules/
```

contient les domaines spécialisés.

Structure officielle :

```text
modules/
  local/
  git/
  server/
  mediatheque/
  moodle-data/
  tests/
```

Chaque module doit être responsable d’un seul domaine.

Définition :

```text
Domaine = zone fonctionnelle claire, par exemple Git ou Médiathèque.
```

## 7. Module `local`

Rôle :

```text
Gérer ce qui se passe sur l’ordinateur de développement.
```

Responsabilités :

```text
vérifier les chemins locaux ;
synchroniser source vers Moodle local ;
purger les caches locaux ;
démarrer ou ouvrir Moodle local ;
tester les pages locales ;
produire des résultats et rapports locaux.
```

Interdictions :

```text
modifier le serveur ;
écrire dans la base Moodle serveur ;
faire des commits Git ;
appliquer la Médiathèque serveur ;
lancer des outils recovery.
```

## 8. Module `git`

Rôle :

```text
Gérer l’état Git et les actions Git.
```

Responsabilités :

```text
vérifier l’état Git ;
afficher les différences ;
détecter des fichiers sensibles ;
créer un commit Git ;
envoyer les changements vers Git ;
récupérer depuis Git si prévu ;
produire des rapports Git.
```

Interdictions :

```text
publier directement sur serveur ;
modifier la base Moodle ;
appliquer la Médiathèque ;
faire une récupération ;
ignorer la confirmation avant commit ou push.
```

## 9. Module `server`

Rôle :

```text
Gérer les actions qui concernent uckk.org.
```

Responsabilités :

```text
tester la connexion serveur ;
vérifier l’état serveur ;
récupérer dernier code sur serveur ;
synchroniser source serveur vers Moodle serveur ;
mettre à jour Moodle serveur si nécessaire ;
purger les caches serveur ;
recharger PHP-FPM ;
vérifier uckk.org ;
produire des rapports serveur.
```

Interdictions :

```text
faire un wipe ;
faire un rebuild complet ;
copier directement des tables ;
modifier la base Moodle serveur sans confirmation ;
utiliser des chemins serveur codés en dur ;
lancer des scripts legacy comme publication normale.
```

## 10. Module `mediatheque`

Rôle :

```text
Gérer le workflow normal de la Médiathèque.
```

Workflow obligatoire :

```text
manifeste → simulation → appliquer → vérifier
```

Responsabilités :

```text
ouvrir le manifeste ;
valider le manifeste ;
simuler localement ;
appliquer localement ;
vérifier localement ;
simuler serveur ;
appliquer serveur ;
vérifier serveur ;
produire des rapports Médiathèque.
```

Interdictions :

```text
utiliser un export public comme source normale ;
utiliser media_original pour les références externes ;
faire un dump SQL brut ;
copier directement des tables ;
faire un wipe/rebuild dans le workflow normal ;
ignorer les tags ;
ignorer les collections ;
coder archiveId/courseId/cmId/contextId en dur.
```

## 11. Module `moodle-data`

Rôle :

```text
Gérer les Données Moodle hors Médiathèque.
```

Workflow obligatoire :

```text
fichier source → validation → simulation → appliquer → vérifier
```

Responsabilités :

```text
valider les fichiers JSON Moodle ;
simuler les catégories ;
appliquer les catégories ;
simuler les cours ;
appliquer les cours ;
simuler les programmes ;
appliquer les programmes ;
simuler les parcours ;
appliquer les parcours ;
gérer plus tard rôles, permissions, badges ou compétences si documentés ;
produire des rapports Données Moodle.
```

Interdictions :

```text
utiliser SQL brut comme workflow normal ;
copier directement des tables ;
gérer des données personnelles sans contrat ;
appliquer serveur sans simulation ni confirmation ;
mélanger Données Moodle et Médiathèque.
```

## 12. Module `tests`

Rôle :

```text
Exécuter les vérifications automatiques ou semi-automatiques.
```

Responsabilités :

```text
tester les pages locales ;
tester les pages serveur ;
tester la Médiathèque locale ;
tester la Médiathèque serveur ;
tester l’index des cours ;
produire des rapports de test.
```

Règle :

```text
Un test lit ou vérifie.
Un test ne modifie pas de données.
```

Si une action modifie des données, elle ne doit pas être dans `modules/tests`.

## 13. Dossiers `legacy/` et `recovery/`

Le dossier :

```text
legacy/
```

contient les anciens outils conservés pour référence.

Le dossier :

```text
recovery/
```

contient les outils de récupération.

Règle :

```text
Le code normal ne doit pas appeler directement legacy ou recovery.
```

Exception :

```text
L’onglet Récupération peut appeler une action recovery documentée, confirmée, sauvegardée et rapportée.
```

## 14. Fichier de configuration unique

Le fichier de configuration principal est :

```text
./config/uckk-ops-console.config.json
```

Le code doit lire les chemins, URLs et paramètres depuis ce fichier.

Interdictions :

```text
écrire C:\mycode\... directement dans un module ;
écrire /var/www/... directement dans un module ;
écrire https://uckk.org partout dans le code ;
écrire archiveId/courseId/cmId/contextId en dur ;
écrire utilisateur SSH ou host serveur en dur.
```

Ces valeurs peuvent apparaître dans :

```text
config ;
docs ;
rapports ;
logs.
```

Mais elles ne doivent pas être dispersées dans la logique.

## 15. Chargement de configuration

Le chargement de configuration doit produire un résultat structuré.

Il doit vérifier :

```text
fichier présent ;
JSON valide ;
sections attendues présentes ;
chemins requis présents ;
URLs valides ;
paramètres serveur présents ;
paramètres de sécurité activés ;
dossiers reports/logs disponibles ou créables.
```

Si la configuration est invalide, l’application doit refuser les actions dépendantes.

Message recommandé :

```text
Action refusée.
Cause : configuration absente ou invalide.
Prochaine étape : vérifier ./config/uckk-ops-console.config.json.
```

## 16. Normalisation des chemins

Avant utilisation, les chemins doivent être normalisés.

Définition :

```text
Normaliser un chemin = transformer un chemin en forme claire et utilisable par le système.
```

Le code doit distinguer :

```text
chemins Windows locaux ;
chemins Linux serveur ;
URLs ;
chemins relatifs ;
chemins absolus.
```

Règle :

```text
Ne jamais utiliser un chemin Windows dans une commande SSH serveur.
Ne jamais utiliser un chemin Linux serveur comme chemin local.
```

## 17. Objet résultat standard

Toute fonction d’action doit retourner un résultat structuré.

Nom conceptuel :

```text
ActionResult
```

Définition :

```text
ActionResult = objet qui décrit le résultat d’une action de manière stable.
```

Champs obligatoires :

```text
success
status
action
domain
target
dangerLevel
mode
summary
warnings
errors
nextStep
reportPath
logPath
data
```

## 18. Définition des champs `ActionResult`

### 18.1 `success`

Définition :

```text
success = indique si l’action a réussi sans erreur bloquante.
```

Valeurs :

```text
true
false
```

### 18.2 `status`

Définition :

```text
status = statut visible final.
```

Valeurs officielles :

```text
Prêt
En cours
Réussi
Réussi avec avertissements
Échoué
Annulé
À vérifier dans le navigateur
```

### 18.3 `action`

Définition :

```text
action = nom lisible de l’action lancée.
```

Exemple :

```text
Simulation Médiathèque serveur
```

### 18.4 `domain`

Définition :

```text
domain = domaine de l’action.
```

Valeurs officielles :

```text
local
git
server
mediatheque
moodle-data
tests
history
recovery
configuration
```

### 18.5 `target`

Définition :

```text
target = cible de l’action.
```

Exemples :

```text
local
serveur
Git
base Moodle locale
base Moodle serveur
Médiathèque locale
Médiathèque serveur
aucune cible modifiée
```

### 18.6 `dangerLevel`

Définition :

```text
dangerLevel = niveau de danger selon docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md.
```

Valeurs :

```text
0
1
2
3
4
5
6
7
```

### 18.7 `mode`

Définition :

```text
mode = façon dont l’action a été lancée.
```

Valeurs officielles :

```text
navigation
vérification
simulation
application
publication
récupération
test
annulation
```

### 18.8 `summary`

Définition :

```text
summary = résumé lisible de l’action.
```

### 18.9 `warnings`

Définition :

```text
warnings = liste des avertissements non bloquants.
```

### 18.10 `errors`

Définition :

```text
errors = liste des erreurs bloquantes ou importantes.
```

### 18.11 `nextStep`

Définition :

```text
nextStep = prochaine action recommandée.
```

### 18.12 `reportPath`

Définition :

```text
reportPath = chemin du rapport lisible produit par l’action.
```

### 18.13 `logPath`

Définition :

```text
logPath = chemin du log technique produit par l’action.
```

### 18.14 `data`

Définition :

```text
data = données structurées propres à l’action.
```

Exemples :

```text
nombre de références Médiathèque ;
nombre de fichiers modifiés Git ;
liste de pages testées ;
compteurs de tables.
```

## 19. Règle sur les retours de fonction

Une fonction d’action ne doit pas retourner seulement du texte brut.

Mauvais exemple :

```text
"done"
```

Bon exemple conceptuel :

```json
{
  "success": true,
  "status": "Réussi",
  "action": "Vérifier Git",
  "domain": "git",
  "target": "Git",
  "dangerLevel": 1,
  "mode": "vérification",
  "summary": "Git ne signale aucun changement.",
  "warnings": [],
  "errors": [],
  "nextStep": "Aucune action requise.",
  "reportPath": "./reports/...",
  "logPath": "./logs/...",
  "data": {}
}
```

## 20. Gestion des erreurs dans le code

Le code doit attraper les erreurs attendues et les transformer en résultat lisible.

Définition :

```text
Attraper une erreur = détecter une erreur technique et la gérer au lieu de laisser l’application planter.
```

Format utilisateur obligatoire :

```text
L’action a échoué.
Cause probable : ...
Prochaine étape : ...
Détail technique : ...
```

Le détail complet va dans le log technique.

L’interface ne doit pas afficher une trace complète comme message principal.

## 21. Commandes système

Une commande système est une commande lancée par l’ordinateur.

Définition :

```text
Commande système = instruction exécutée par le système d’exploitation.
```

Toute commande système doit passer par une fonction commune.

Nom conceptuel :

```text
Invoke-UckkCommand
```

ou équivalent dans le langage choisi.

Cette fonction doit gérer :

```text
commande ;
arguments ;
dossier de travail ;
timeout ;
sortie standard ;
sortie erreur ;
code de retour ;
log ;
masquage des secrets.
```

Définition :

```text
Timeout = durée maximale avant qu’une commande soit arrêtée.
```

## 22. Interdiction des commandes construites dangereusement

Le code ne doit pas construire une commande dangereuse en concaténant du texte non vérifié.

Définition :

```text
Concaténer = coller plusieurs morceaux de texte ensemble.
```

Exemple dangereux :

```text
commande = "ssh " + userInput
```

Règle :

```text
Les arguments doivent être validés, échappés ou passés séparément quand le langage le permet.
```

Définition :

```text
Échapper = transformer un texte pour éviter qu’il soit interprété comme une commande.
```

## 23. Commandes SSH

Les commandes serveur doivent passer par une fonction commune.

Nom conceptuel :

```text
Invoke-UckkSshCommand
```

Cette fonction doit utiliser la configuration :

```text
server.sshUser
server.sshHost
server.sshTarget
paths.serverMoodleSource
paths.serverMoodleRuntime
paths.serverMoodleRoot
```

Elle doit produire :

```text
résultat structuré ;
rapport si action importante ;
log technique ;
erreur lisible en cas d’échec.
```

Règle :

```text
Aucune commande serveur ne doit être cachée dans l’interface.
```

## 24. Écriture des rapports

Toute action importante doit utiliser une fonction commune d’écriture de rapport.

Nom conceptuel :

```text
Write-UckkReport
```

Cette fonction doit :

```text
créer un nom de fichier stable ;
écrire en Markdown ;
inclure les sections obligatoires ;
lier le log technique ;
éviter les secrets ;
retourner le chemin du rapport.
```

Elle doit respecter :

```text
docs/10_RAPPORTS_LOGS_ERREURS.md
```

## 25. Écriture des logs

Toute action importante doit utiliser une fonction commune d’écriture de log.

Nom conceptuel :

```text
Write-UckkLog
```

Cette fonction doit :

```text
écrire le timestamp ;
écrire l’action ;
écrire la cible ;
écrire les commandes ;
écrire les sorties techniques ;
écrire les codes de retour ;
masquer les secrets ;
lier le rapport si disponible.
```

## 26. Masquage des secrets

Le code doit masquer les secrets avant d’écrire un rapport ou un log.

Définition :

```text
Secret = mot de passe, token, clé privée ou autre information sensible.
```

Exemples à masquer :

```text
password
passwd
token
secret
apikey
api_key
private_key
config.php serveur
cookie
session
```

Format recommandé :

```text
[masqué]
```

Règle :

```text
Un secret ne doit jamais être écrit dans un rapport ou un log.
```

## 27. Confirmations

Toute action sensible doit passer par une fonction commune de confirmation.

Nom conceptuel :

```text
Confirm-UckkAction
```

Cette fonction doit recevoir :

```text
action ;
target ;
dangerLevel ;
message ;
requiresBackup ;
wouldModifyServer ;
wouldWriteDatabase ;
wouldModifyGit.
```

Elle doit retourner :

```text
confirmé ;
annulé.
```

Si l’utilisateur refuse :

```text
status = Annulé
summary = Annulé — aucune modification n’a été faite.
```

## 28. Niveaux de danger dans le code

Le code doit utiliser les niveaux officiels :

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
Une action sans niveau de danger ne doit pas être exposée dans l’interface.
```

## 29. Actions et métadonnées

Chaque action exposée dans l’interface doit être déclarée avec des métadonnées.

Définition :

```text
Métadonnées = informations qui décrivent une action.
```

Métadonnées obligatoires :

```text
id
label
description
domain
target
dangerLevel
mode
requiresConfirmation
requiresSimulation
requiresBackup
producesReport
producesLog
handler
```

Définition :

```text
handler = fonction appelée quand l’action est lancée.
```

## 30. Exemple conceptuel de déclaration d’action

Exemple :

```json
{
  "id": "mediatheque.simulate.server",
  "label": "Simulation Médiathèque serveur",
  "description": "Vérifie ce qui serait écrit dans la base Moodle serveur, sans modifier les données.",
  "domain": "mediatheque",
  "target": "base Moodle serveur",
  "dangerLevel": 1,
  "mode": "simulation",
  "requiresConfirmation": false,
  "requiresSimulation": false,
  "requiresBackup": false,
  "producesReport": true,
  "producesLog": true,
  "handler": "Invoke-MediathequeSimulationServer"
}
```

Règle :

```text
L’interface doit être générée ou contrôlée à partir d’actions déclarées clairement.
```

## 31. Handlers

Un handler est la fonction réelle appelée par une action.

Définition :

```text
Handler = fonction qui exécute l’action demandée.
```

Un handler doit :

```text
recevoir la configuration ;
recevoir le contexte d’exécution ;
valider les préconditions ;
demander confirmation si nécessaire ;
exécuter l’action ;
produire rapport/log si nécessaire ;
retourner un ActionResult.
```

Définition :

```text
Précondition = condition qui doit être vraie avant de continuer.
```

## 32. Préconditions

Chaque action sensible doit vérifier ses préconditions.

Exemples :

```text
configuration chargée ;
chemins présents ;
source existe ;
cible existe ;
Git propre ou état compris ;
simulation faite si obligatoire ;
sauvegarde présente si recovery ;
confirmation obtenue ;
serveur accessible si action serveur.
```

Règle :

```text
Précondition manquante = action refusée.
```

Message :

```text
Action refusée.
Cause : précondition manquante.
Prochaine étape : ...
```

## 33. Simulation avant application

Pour les domaines Données Moodle et Médiathèque, le code doit séparer :

```text
simulation ;
application.
```

Une simulation ne doit pas écrire dans la base Moodle.

Une application écrit réellement.

Règle :

```text
Le même moteur de calcul doit être utilisé pour simulation et application, avec un mode différent.
```

Définition :

```text
Moteur de calcul = partie du code qui compare la source et la cible pour déterminer les changements.
```

Cela évite que la simulation annonce une chose et que l’application fasse autre chose.

## 34. Mode dry-run

Le terme technique `dry-run` peut exister dans le code.

Dans l’interface, utiliser :

```text
Simulation
```

Règle :

```text
Le mot visible principal ne doit pas être dry-run.
```

## 35. Idempotence

Les actions d’application doivent être idempotentes quand elles créent ou mettent à jour des données.

Définition :

```text
Idempotent = une action peut être relancée sans créer de doublons ou de dégâts.
```

Le code doit utiliser des identifiants stables.

Exemples :

```text
slug ;
idnumber ;
shortname ;
URL ;
identifiant externe ;
clé métier.
```

Définition :

```text
Clé métier = valeur qui identifie une donnée selon le domaine, pas selon l’identifiant interne de la base.
```

Règle :

```text
Ne pas se fier seulement aux identifiants internes Moodle pour reconnaître les données entre local et serveur.
```

## 36. Upsert

Les applications normales doivent privilégier l’opération :

```text
upsert
```

Définition :

```text
Upsert = créer si absent, mettre à jour si déjà présent.
```

Règle :

```text
Un workflow normal ne doit pas supprimer par défaut.
```

## 37. Suppression

La suppression doit être explicite.

Définition :

```text
Suppression = action qui retire une donnée existante.
```

Règle :

```text
L’absence d’un élément dans un fichier source ne doit pas automatiquement supprimer cet élément dans Moodle.
```

Si un mode de suppression existe plus tard, il doit être documenté comme dangereux.

## 38. Base Moodle

Toute écriture dans la base Moodle doit passer par un module spécialisé.

L’interface ne doit jamais écrire directement dans la base.

Règle :

```text
Pas d’écriture DB depuis app/.
```

Définition :

```text
DB = base de données.
```

Dans l’interface, utiliser :

```text
Base Moodle
```

## 39. SQL brut

Le SQL brut ne doit pas être un workflow normal.

Définition :

```text
SQL brut = commande SQL lancée directement sans workflow contrôlé.
```

Le SQL brut peut être utilisé dans :

```text
diagnostic ;
test technique ;
récupération documentée.
```

Mais pas dans :

```text
Médiathèque normale ;
Données Moodle normales ;
Accueil ;
workflow de publication normal.
```

## 40. Copie directe de tables

La copie directe de tables est interdite comme workflow normal.

Définition :

```text
Copie directe de tables = transfert manuel de tables de base de données d’un environnement à un autre.
```

Raison :

```text
Les identifiants Moodle peuvent être différents entre local et serveur.
```

## 41. Tests techniques du code

Chaque module doit avoir au minimum des actions de vérification.

Le module `tests` peut regrouper les tests visibles.

Types de tests :

```text
test de configuration ;
test de chemins ;
test de page locale ;
test de page serveur ;
test de service Médiathèque ;
test de validation JSON ;
test de rapport généré.
```

Règle :

```text
Un test ne doit pas modifier les données.
```

Si un test écrit quelque chose, il doit être renommé et classé selon son niveau réel.

## 42. Sorties techniques

Les sorties techniques doivent être capturées.

Définition :

```text
Sortie technique = texte brut produit par une commande ou un programme.
```

Elles vont dans le log.

L’interface affiche un résumé.

Règle :

```text
Ne pas afficher stdout/stderr comme résultat principal.
```

Définitions :

```text
stdout = sortie standard d’une commande.

stderr = sortie erreur d’une commande.
```

## 43. Codes de retour

Chaque commande doit vérifier son code de retour.

Définition :

```text
Code de retour = nombre donné par une commande pour indiquer si elle a réussi ou échoué.
```

Règle générale :

```text
0 = réussite habituelle.
autre valeur = erreur ou situation spéciale.
```

Le code doit traduire les codes en messages lisibles.

## 44. Timeouts

Les commandes longues doivent avoir un timeout.

Définition :

```text
Timeout = durée maximale avant qu’une commande soit arrêtée.
```

Règle :

```text
Une action ne doit pas rester bloquée sans retour visible.
```

Si un timeout arrive :

```text
status = Échoué
summary = L’action a dépassé le temps maximal prévu.
nextStep = Lire le log technique et relancer seulement si la cause est comprise.
```

## 45. États en cours

Une action longue doit afficher :

```text
En cours
```

Elle doit indiquer l’étape actuelle.

Exemple :

```text
En cours — synchronisation source serveur vers Moodle serveur.
```

Règle :

```text
L’utilisateur ne doit pas croire que l’application est gelée.
```

Définition :

```text
Gelée = qui ne répond plus visiblement.
```

## 46. Écriture atomique des fichiers

Pour les rapports et fichiers générés, utiliser une écriture atomique si possible.

Définition :

```text
Écriture atomique = écrire d’abord dans un fichier temporaire, puis renommer vers le nom final.
```

But :

```text
éviter les fichiers partiellement écrits.
```

## 47. Encodage des fichiers

Les fichiers texte générés doivent utiliser :

```text
UTF-8
```

Définition :

```text
UTF-8 = encodage de texte compatible avec les accents français.
```

Règle :

```text
Les rapports et fichiers de configuration doivent supporter les accents.
```

## 48. Langue de l’interface

L’interface visible doit être en français.

Le code interne peut utiliser des noms anglais si cela reste cohérent.

Exemple acceptable dans le code :

```text
ActionResult
LoadConfig
WriteReport
```

Exemple visible à l’utilisateur :

```text
Rapport
Configuration
Simulation
Appliquer
```

Règle :

```text
Le vocabulaire visible doit respecter docs/02_VOCABULAIRE_OBLIGATOIRE.md.
```

## 49. Noms de fonctions

Les noms de fonctions doivent dire leur rôle.

Exemples conceptuels :

```text
Load-UckkConfig
Test-UckkConfig
Invoke-UckkCommand
Invoke-UckkSshCommand
New-UckkActionResult
Write-UckkReport
Write-UckkLog
Confirm-UckkAction
Invoke-UckkLocalSync
Invoke-UckkServerPublish
Test-UckkMediathequeManifest
Invoke-UckkMediathequeSimulation
Invoke-UckkMediathequeApply
```

Éviter :

```text
Run
DoIt
Fix
SyncStuff
NewScript
FinalWorking
Test2
```

## 50. Noms de fichiers de code

Un fichier de code doit avoir un rôle clair.

Exemples conceptuels :

```text
lib/config.*
lib/result.*
lib/report.*
lib/log.*
lib/command.*
lib/security.*
modules/local/local.*
modules/git/git.*
modules/server/server.*
modules/mediatheque/mediatheque.*
modules/moodle-data/moodle-data.*
modules/tests/tests.*
```

L’extension dépend du langage choisi.

Règle :

```text
Un fichier ne doit pas devenir un mélange de domaines.
```

## 51. Choix du langage

Ce document ne force pas un seul langage si une décision technique explicite n’a pas été prise.

Mais le langage choisi doit respecter :

```text
interface locale utilisable sur Windows ;
lecture JSON fiable ;
exécution de commandes locales ;
exécution SSH ;
écriture de rapports Markdown ;
gestion claire des erreurs ;
support UTF-8 ;
organisation en modules.
```

Si l’application est construite en PowerShell, les règles restent les mêmes.

Si elle est construite dans un autre langage, les règles restent les mêmes.

Règle :

```text
Le contrat d’architecture prime sur le langage.
```

## 52. Si PowerShell est utilisé

Si PowerShell est utilisé, respecter :

```text
fonctions nommées Verbe-Nom ;
modules séparés ;
pas de logique massive dans le fichier GUI ;
objets PSCustomObject pour les résultats ;
ConvertFrom-Json pour la configuration ;
Start-Process seulement pour ouvrir ;
& ou Start-Process contrôlé pour les commandes ;
try/catch pour erreurs ;
Set-StrictMode si compatible ;
encodage UTF-8.
```

Définition :

```text
GUI = interface graphique.
```

Règle :

```text
Le fichier GUI ne doit pas contenir toute la logique.
```

## 53. Si une interface graphique est utilisée

L’interface graphique doit appeler les actions déclarées.

Elle doit :

```text
afficher les onglets officiels ;
afficher les boutons officiels ;
afficher les descriptions ;
afficher les confirmations ;
afficher le dernier résultat ;
ouvrir les rapports ;
ne pas afficher de pile technique comme message principal.
```

Définition :

```text
Pile technique / stack trace = détail des appels internes d’un programme au moment d’une erreur.
```

## 54. Thread ou tâche longue

Si une action longue est lancée, l’interface ne doit pas devenir inutilisable.

Définition :

```text
Tâche longue = action qui peut prendre plusieurs secondes ou minutes.
```

Règle conceptuelle :

```text
L’interface doit montrer que l’action est en cours.
```

Elle doit empêcher les doubles clics qui relancent la même action dangereuse.

Définition :

```text
Double clic dangereux = lancement involontaire de la même action deux fois.
```

## 55. Verrouillage des actions sensibles

Pendant une action sensible, l’application doit bloquer les relances dangereuses.

Exemples :

```text
ne pas permettre deux publications serveur en même temps ;
ne pas permettre deux applications Médiathèque serveur en même temps ;
ne pas permettre une récupération pendant une application normale.
```

Définition :

```text
Verrouillage = protection qui empêche deux actions incompatibles de s’exécuter en même temps.
```

## 56. Prévention des états incohérents

Le code doit éviter les états incohérents.

Définition :

```text
État incohérent = situation où une partie de l’application croit qu’une action a réussi alors qu’une autre partie sait qu’elle a échoué.
```

Règle :

```text
Le résultat final doit être dérivé des étapes exécutées.
```

Si une étape critique échoue, l’action globale ne doit pas être marquée comme réussie.

## 57. Étapes d’action

Une action complexe doit être divisée en étapes.

Définition :

```text
Étape = sous-action nommée dans un workflow.
```

Chaque étape doit avoir :

```text
nom ;
statut ;
résumé ;
erreur éventuelle ;
détail technique éventuel.
```

Exemple :

```text
- Réussi — tester connexion serveur.
- Réussi — récupérer dernier code.
- Échoué — synchroniser source serveur vers Moodle serveur.
- Ignoré — purger caches serveur.
```

## 58. Action en chaîne

Une action en chaîne exécute plusieurs étapes.

Définition :

```text
Action en chaîne = bouton qui exécute plusieurs étapes dans un ordre prévu.
```

Exemple :

```text
Publier sur serveur
```

Règle :

```text
Une action en chaîne doit s’arrêter si une étape critique échoue.
```

Elle doit produire un rapport avec toutes les étapes.

## 59. Accès navigateur

Pour ouvrir une URL, utiliser une fonction commune.

Nom conceptuel :

```text
Open-UckkUrl
```

Cette fonction doit :

```text
valider l’URL ;
ouvrir le navigateur par défaut ;
retourner un ActionResult ;
ne pas modifier les données.
```

## 60. Accès fichiers et dossiers

Pour ouvrir un fichier ou dossier, utiliser une fonction commune.

Nom conceptuel :

```text
Open-UckkPath
```

Cette fonction doit :

```text
valider le chemin ;
vérifier l’existence ;
ouvrir le chemin ;
retourner un ActionResult ;
afficher une erreur lisible si introuvable.
```

## 61. Validation des URLs

Une URL doit être validée avant utilisation.

Définition :

```text
URL = adresse d’une page web.
```

Règle :

```text
Une URL vide ou mal formée doit bloquer l’action qui en dépend.
```

## 62. Validation des JSON

Tout fichier JSON utilisé comme source doit être validé avant application.

Définition :

```text
JSON = fichier texte structuré qui décrit des données.
```

La validation doit distinguer :

```text
fichier absent ;
fichier illisible ;
JSON invalide ;
champs manquants ;
valeurs incohérentes ;
doublons.
```

## 63. Base de données Moodle

Le code qui écrit dans Moodle doit être isolé.

Règle :

```text
Les écritures Moodle passent par des fonctions clairement nommées et rapportées.
```

Une écriture Moodle doit indiquer :

```text
source ;
cible ;
mode ;
confirmation ;
simulation préalable si nécessaire ;
résumé des changements ;
rapport.
```

## 64. Migrations et upgrade Moodle

Une mise à jour Moodle peut modifier la base.

Définition :

```text
Mise à jour Moodle = étape où Moodle applique les changements nécessaires après modification du code ou de la structure.
```

Règle :

```text
Mettre à jour Moodle serveur doit être traité comme action sensible.
```

Confirmation :

```text
Cette action peut modifier la base Moodle serveur. Continuer ?
```

## 65. Cache Moodle

Définition :

```text
Cache Moodle = mémoire temporaire utilisée par Moodle pour accélérer son fonctionnement.
```

Purger les caches est une action utile mais doit être explicite.

Libellés :

```text
Purger les caches locaux
Purger les caches serveur
```

Ne pas utiliser seulement :

```text
Purge
```

## 66. PHP-FPM

Définition :

```text
PHP-FPM = service du serveur qui exécute le code PHP de Moodle.
```

Recharger PHP-FPM doit être une action serveur confirmée.

Libellé :

```text
Recharger PHP-FPM
```

Cette action ne doit pas redémarrer toute la machine.

## 67. Séparation des environnements

Le code doit toujours distinguer :

```text
local ;
serveur.
```

Règle :

```text
Une fonction qui modifie une cible doit recevoir explicitement la cible.
```

Mauvais nom :

```text
ApplyMediatheque
```

Meilleur nom :

```text
ApplyMediathequeLocal
ApplyMediathequeServer
```

ou une fonction commune avec paramètre validé :

```text
ApplyMediatheque(target = local/server)
```

## 68. Paramètre cible

Si une fonction accepte un paramètre de cible, elle doit valider les valeurs possibles.

Valeurs possibles :

```text
local
server
```

Interdit :

```text
prod
live
remote
default
auto
```

sauf si ces termes sont documentés.

Règle :

```text
Pas de cible implicite pour une action d’écriture.
```

## 69. Valeurs par défaut

Les valeurs par défaut sont autorisées seulement si elles sont non dangereuses.

Acceptables :

```text
reports.dir = ./reports
logs.dir = ./logs
reports.format = markdown
logs.level = normal
```

Interdit :

```text
serverMoodleRuntime absent → utiliser /var/www/html
target absent → server
confirmServerActions absent → false
```

Règle :

```text
Une valeur manquante ne doit pas rendre une action dangereuse silencieusement.
```

## 70. Compatibilité avec les documents

Le code doit respecter les libellés officiels des documents.

Exemples :

```text
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
Vérifier fichiers JSON Moodle
Synchroniser source vers Moodle local
Publier sur serveur
```

Règle :

```text
Le code ne doit pas inventer de nouveaux libellés visibles sans mise à jour documentaire.
```

## 71. Aucun backlog dans le code

Ce projet de documentation n’est pas un backlog.

Le code ne doit pas contenir de grandes listes TODO vagues.

Acceptable :

```text
TODO: gérer le cas d’erreur X dans cette fonction.
```

À éviter :

```text
TODO: refaire toute la Médiathèque plus tard.
TODO: ajouter plein d’outils.
TODO: améliorer sécurité.
```

Règle :

```text
Les commentaires doivent expliquer le code, pas devenir un plan flou.
```

## 72. Commentaires utiles

Un commentaire utile explique pourquoi une règle existe.

Exemple :

```text
# Ne pas utiliser l’export public comme source : il peut être partiel.
```

Un commentaire inutile répète le code.

Exemple inutile :

```text
# increment i
```

Règle :

```text
Commenter les décisions, pas les évidences.
```

## 73. Dépendances

Toute dépendance externe doit être justifiée.

Définition :

```text
Dépendance = logiciel, bibliothèque ou outil externe nécessaire au fonctionnement.
```

Règle :

```text
Ne pas ajouter une dépendance pour une tâche simple.
```

Une dépendance doit être documentée dans le README ou la configuration si elle est nécessaire.

## 74. Portabilité

L’application cible d’abord l’environnement Windows local de développement.

Mais elle doit savoir exécuter des commandes sur un serveur Linux par SSH.

Règle :

```text
Le code local et le code serveur ne doivent pas supposer le même système de fichiers.
```

## 75. Sécurité serveur

Toute action serveur doit être explicite.

Le code doit indiquer :

```text
action ;
serveur ciblé ;
chemins serveur utilisés ;
confirmation obtenue ;
rapport produit.
```

Règle :

```text
Une action serveur ne doit jamais s’exécuter par accident au chargement de l’application.
```

## 76. Aucune action dangereuse au démarrage

Au démarrage, l’application peut :

```text
charger la configuration ;
valider la configuration ;
afficher l’état non vérifié ;
créer reports/logs si autorisé ;
afficher l’interface.
```

Au démarrage, l’application ne doit pas :

```text
publier ;
synchroniser ;
appliquer ;
purger ;
mettre à jour Moodle ;
écrire dans la base ;
faire un commit ;
faire un push ;
lancer recovery.
```

## 77. Historique

L’onglet Historique lit les rapports et logs.

Il ne doit pas relancer une action automatiquement.

Règle :

```text
Lire l’historique n’est pas réexécuter l’historique.
```

## 78. Erreurs de configuration

Une erreur de configuration doit bloquer les actions dépendantes.

Exemple :

```text
paths.serverMoodleRuntime manquant
```

bloque :

```text
Synchroniser source serveur vers Moodle serveur
```

Mais ne bloque pas forcément :

```text
Vérifier Git
```

Règle :

```text
Bloquer seulement ce qui dépend de la configuration manquante.
```

## 79. Dégradation contrôlée

Définition :

```text
Dégradation contrôlée = l’application reste utilisable partiellement même si une partie est indisponible.
```

Exemple :

```text
Si le serveur est inaccessible, les onglets Local et Git peuvent rester utilisables.
```

Règle :

```text
Une erreur serveur ne doit pas rendre toute l’application inutilisable.
```

## 80. Refus d’action

Le code doit refuser une action si elle viole un contrat.

Exemples :

```text
action serveur sans confirmation ;
recovery sans sauvegarde ;
application serveur sans simulation obligatoire ;
source Médiathèque partielle ;
configuration cible ambiguë ;
outil legacy appelé comme normal.
```

Format :

```text
Action refusée.
Cause : ...
Prochaine étape : ...
```

## 81. Rapport même pour refus sensible

Si une action sensible est refusée, produire un rapport si possible.

But :

```text
garder une trace de la protection.
```

Exemple :

```text
Rapport — Action refusée : Appliquer Médiathèque serveur
Cause : aucune simulation serveur récente disponible.
```

## 82. Simulation récente

Pour certaines actions, il peut être nécessaire de vérifier qu’une simulation récente existe.

Définition :

```text
Simulation récente = simulation faite avec la même source et la même cible avant application.
```

Règle conceptuelle :

```text
Appliquer serveur ne doit pas utiliser une simulation faite sur une source différente.
```

Le rapport doit indiquer la source de la simulation.

## 83. Checksums ou empreintes

Option technique recommandée pour relier simulation et application :

```text
empreinte de source
```

Définition :

```text
Empreinte = valeur calculée depuis un fichier pour détecter s’il a changé.
```

Exemple :

```text
hash SHA-256 du manifeste Médiathèque
```

Définition :

```text
Hash = résultat d’un calcul qui identifie le contenu d’un fichier.
```

Cette option n’est pas obligatoire au départ, mais elle est recommandée pour les actions serveur sensibles.

## 84. Gestion des gros résultats

Si une action produit beaucoup de détails, l’interface doit afficher un résumé et écrire le détail dans le rapport.

Exemple :

```text
Résumé : 128 références analysées, 2 mises à jour.
Rapport : ouvrir.
```

Règle :

```text
L’interface ne doit pas devenir illisible.
```

## 85. Données personnelles

Le code ne doit pas manipuler des données personnelles sans contrat spécifique.

Définition :

```text
Donnée personnelle = information liée à une personne identifiable.
```

Exemples :

```text
nom complet ;
courriel ;
notes ;
historique d’activité ;
réponses d’utilisateur ;
identifiants privés.
```

Règle :

```text
Les workflows normaux visent la structure et les références, pas les données personnelles.
```

## 86. Vérification navigateur

Le code doit distinguer :

```text
test HTTP ;
test service ;
vérification navigateur.
```

Définitions :

```text
HTTP 200 = réponse technique indiquant qu’une page a répondu.

Service = fonction appelée par une page pour obtenir des données.

Vérification navigateur = vérification visuelle dans Chrome, Edge ou Firefox.
```

Règle :

```text
Pour les pages AJAX, HTTP 200 ne suffit pas.
```

## 87. Service Médiathèque

Le nom technique actuel du service Médiathèque est :

```text
mod_uckkarchive_search_mediatheque
```

Le code doit lire ce nom depuis :

```text
mediatheque.serviceName
```

Règle :

```text
Ne pas coder le nom du service en dur dans plusieurs endroits.
```

## 88. Identifiants Médiathèque

Les identifiants suivants doivent venir de la configuration :

```text
localArchiveId
localCourseId
localCmId
localContextId
serverArchiveId
serverCourseId
serverCmId
serverContextId
```

Ils ne doivent pas être écrits en dur dans le module Médiathèque.

## 89. Protection 128 → 5

Le code Médiathèque doit protéger contre les sources partielles.

Règle :

```text
Si une source contient beaucoup moins de références que la cible connue, afficher un avertissement fort ou refuser selon le mode.
```

Exemple :

```text
Avertissement fort — la source contient 5 références alors que la cible en contient 128.
Action refusée sauf récupération explicitement confirmée.
```

Définition :

```text
Source partielle = source incomplète qui peut écraser ou réduire un état correct.
```

## 90. Classes d’outils

Tout outil doit être classé :

```text
normal
legacy
recovery
test
```

Le code normal ne lance que :

```text
normal
```

et les tests depuis :

```text
test
```

L’onglet Récupération peut lancer :

```text
recovery
```

avec protections.

Règle :

```text
Un outil non classé ne doit pas être lancé.
```

## 91. Documentation intégrée dans le code

Chaque module doit pouvoir être compris avec :

```text
son nom ;
ses fonctions publiques ;
ses commentaires de décision ;
le contrat documentaire lié.
```

Exemple :

```text
modules/mediatheque
contrat lié : docs/08_MEDIATHEQUE_CONTRAT.md
```

## 92. Fonctions publiques et internes

Une fonction publique est appelée par l’interface ou un autre module.

Définition :

```text
Fonction publique = fonction exposée pour être utilisée ailleurs.
```

Une fonction interne aide seulement dans son fichier ou module.

Définition :

```text
Fonction interne = fonction auxiliaire non destinée à être appelée directement par l’interface.
```

Règle :

```text
Les fonctions publiques doivent retourner ActionResult.
```

Les fonctions internes peuvent retourner des valeurs plus simples si elles sont utilisées de manière contrôlée.

## 93. Entrées et sorties

Chaque fonction publique doit documenter :

```text
entrées attendues ;
sorties produites ;
erreurs possibles ;
effets de bord.
```

Définition :

```text
Effet de bord = modification produite par une fonction en dehors de sa valeur de retour.
```

Exemples d’effets de bord :

```text
écrire un fichier ;
modifier la base Moodle ;
lancer une commande ;
ouvrir une URL ;
écrire un rapport.
```

## 94. Fonctions sans effet de bord

Quand c’est possible, séparer :

```text
calcul ;
écriture.
```

Définition :

```text
Fonction sans effet de bord = fonction qui calcule une valeur sans modifier le système.
```

Exemple :

```text
Comparer manifeste et état Moodle
```

peut être sans effet de bord.

Puis :

```text
Appliquer changements
```

écrit réellement.

Règle :

```text
La séparation calcul/écriture rend la simulation plus fiable.
```

## 95. Validation avant action

Une action doit valider ses entrées avant d’écrire.

Exemples :

```text
manifeste valide avant apply Médiathèque ;
JSON valide avant apply Données Moodle ;
chemin serveur défini avant sync serveur ;
Git vérifié avant commit ;
backup vérifié avant recovery.
```

## 96. Backups dans le code

Une action qui exige une sauvegarde doit vérifier son existence.

Définition :

```text
Backup / sauvegarde = copie conservée avant une action risquée pour pouvoir revenir en arrière.
```

Règle :

```text
Ne pas seulement afficher “faites une sauvegarde”.
Le code doit savoir qu’une sauvegarde existe ou en créer une si c’est son rôle.
```

## 97. Récupération

Le code recovery doit être plus strict que le code normal.

Règles :

```text
confirmation forte ;
sauvegarde ;
rapport obligatoire ;
log obligatoire ;
source claire ;
cible claire ;
pas d’exécution depuis Accueil ;
pas d’exécution silencieuse.
```

## 98. Aucun réseau non nécessaire

Le code ne doit pas appeler Internet ou des services externes sans raison liée à l’action.

Actions acceptables :

```text
vérifier uckk.org ;
ouvrir une référence externe ;
tester le serveur ;
vérifier une URL de Médiathèque si documenté.
```

Règle :

```text
Une action locale ne doit pas dépendre d’un service externe inutile.
```

## 99. Robustesse

Définition :

```text
Robustesse = capacité du code à gérer les erreurs prévisibles sans casser l’application.
```

Le code doit gérer :

```text
fichier absent ;
JSON invalide ;
chemin introuvable ;
URL invalide ;
commande échouée ;
serveur inaccessible ;
permission refusée ;
rapport impossible à écrire ;
log impossible à écrire ;
annulation utilisateur.
```

## 100. Messages utilisateur

Les messages visibles doivent respecter :

```text
docs/02_VOCABULAIRE_OBLIGATOIRE.md
docs/10_RAPPORTS_LOGS_ERREURS.md
```

Règle :

```text
Pas de jargon non défini dans l’interface.
```

Mauvais :

```text
Process exited with code 1.
```

Bon :

```text
L’action a échoué.
Cause probable : la commande n’a pas réussi.
Prochaine étape : ouvrir le rapport.
Détail technique : code de retour 1.
```

## 101. Anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
mettre toute la logique dans l’interface ;
coder des chemins en dur ;
inventer un second fichier de configuration principal ;
retourner seulement du texte brut ;
ignorer ActionResult ;
ignorer les rapports ;
ignorer les logs ;
lancer une action serveur sans confirmation ;
écrire dans la base Moodle sans confirmation ;
utiliser legacy comme normal ;
placer recovery dans Accueil ;
utiliser SQL brut comme workflow normal ;
faire une copie directe de tables ;
mélanger local et serveur ;
ignorer les préconditions ;
afficher une stack trace comme message principal ;
créer plusieurs outils normaux pour la même tâche ;
changer les libellés visibles sans mettre à jour la documentation ;
créer des TODO vagues au lieu de règles codées.
```

Si une règle bloque une implémentation, l’IA doit proposer une modification documentaire explicite avant de coder contre le contrat.

## 102. Critère final de qualité

Le code est acceptable si une personne peut comprendre :

```text
où est la configuration ;
quel module gère quel domaine ;
quelle action est lancée par quel bouton ;
quelle cible est modifiée ;
quel niveau de danger s’applique ;
quelle confirmation protège l’action ;
quel rapport sera écrit ;
quel log sera écrit ;
quoi faire en cas d’erreur ;
pourquoi legacy et recovery ne sont pas dans le workflow normal.
```

Si ces points ne sont pas clairs, le code ne respecte pas ce document.

## 103. Résumé obligatoire

Règles finales :

```text
Interface mince.
Modules spécialisés.
Configuration centralisée.
Aucun chemin codé en dur.
Actions déclarées.
Niveaux de danger obligatoires.
Confirmations obligatoires.
ActionResult obligatoire pour les actions publiques.
Rapports lisibles.
Logs techniques séparés.
Secrets masqués.
Simulation séparée de l’application.
Aucune récupération dans le workflow normal.
Aucun legacy lancé comme outil normal.
Aucune action dangereuse au démarrage.
Aucun faux succès.
```

Règle ultime :

```text
Le code doit rendre le bon chemin facile et le mauvais chemin difficile.
