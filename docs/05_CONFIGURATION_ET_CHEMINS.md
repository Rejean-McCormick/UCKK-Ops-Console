# 05 — Configuration et chemins

## 1. Rôle de ce document

Ce document définit la configuration et les chemins officiels de la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il sert à empêcher l’IA de disperser les chemins dans le code.

Il sert aussi à empêcher les scripts de fonctionner seulement sur une machine parce que des chemins ont été écrits directement dans un fichier de code.

Définition :

```text
Configuration = fichier de paramètres lu par l’application.
```

Définition :

```text
Chemin = adresse d’un fichier ou d’un dossier sur un ordinateur.
```

Définition :

```text
Codé en dur = écrit directement dans le code au lieu d’être lu depuis la configuration.
```

Règle principale :

```text
Si une valeur peut changer selon la machine, le serveur ou l’environnement, elle doit venir de la configuration.
```

## 2. Racine officielle de l’application

La racine officielle de la nouvelle application est :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Dans ce document, le mot “racine” désigne toujours ce dossier.

Quand un chemin commence par :

```text
./
```

cela signifie :

```text
C:\mycode\UCKK\UCKK_ops_console\
```

Exemple :

```text
./config/uckk-ops-console.config.json
```

signifie :

```text
C:\mycode\UCKK\UCKK_ops_console\config\uckk-ops-console.config.json
```

## 3. Fichier de configuration officiel

Le fichier de configuration officiel est :

```text
./config/uckk-ops-console.config.json
```

Chemin complet :

```text
C:\mycode\UCKK\UCKK_ops_console\config\uckk-ops-console.config.json
```

Aucun autre fichier de configuration principal ne doit être ajouté sans modification documentée de ce fichier.

## 4. Rôle du dossier `config/`

Le dossier :

```text
./config
```

contient les paramètres de l’application.

Il ne doit pas contenir :

```text
logs ;
rapports ;
scripts ;
sauvegardes ;
dumps SQL ;
secrets ;
anciens outils.
```

Il doit contenir seulement des fichiers de configuration nécessaires.

## 5. Secrets interdits dans la configuration

Le fichier de configuration ne doit pas contenir de secrets.

Définition :

```text
Secret = information sensible qui ne doit pas être stockée dans le code ou dans un fichier partagé.
```

Secrets interdits :

```text
mots de passe ;
clés SSH privées ;
tokens ;
mot de passe de base de données ;
config.php serveur ;
cookies de session ;
clés API privées ;
dumps SQL ;
identifiants personnels sensibles.
```

Si une action a besoin d’un secret, l’application doit utiliser une méthode externe sécurisée.

Exemples de méthodes acceptables :

```text
agent SSH déjà configuré ;
variables d’environnement locales ;
fichier privé explicitement ignoré par Git ;
demande interactive à l’utilisateur.
```

Définition :

```text
Variable d’environnement = valeur fournie par le système ou la session, sans être écrite dans le code.
```

## 6. Configuration versionnée et configuration privée

Il peut y avoir deux types de configuration :

```text
configuration modèle ;
configuration locale privée.
```

### 6.1 Configuration modèle

Nom recommandé :

```text
./config/uckk-ops-console.config.example.json
```

Rôle :

```text
Montrer la structure attendue sans contenir de secret.
```

Ce fichier peut être versionné dans Git.

Définition :

```text
Versionné = enregistré dans Git.
```

### 6.2 Configuration locale privée

Nom officiel :

```text
./config/uckk-ops-console.config.json
```

Rôle :

```text
Contenir les chemins réels de la machine locale.
```

Ce fichier peut contenir des chemins locaux, mais pas de secrets.

Selon le choix du projet, il peut être ignoré par Git si les chemins sont propres à une machine.

Règle :

```text
Si un fichier de configuration contient des valeurs propres à une machine, il ne doit pas être partagé aveuglément.
```

## 7. Sections officielles de la configuration

Le fichier de configuration doit être organisé en sections.

Sections officielles :

```text
app
paths
urls
server
git
moodle
mediatheque
reports
logs
safety
```

Aucune autre section principale ne doit être ajoutée sans modification documentée.

## 8. Section `app`

La section :

```json
"app": {}
```

décrit l’application elle-même.

Champs officiels :

```text
name
root
language
```

### 8.1 `app.name`

Nom de l’application.

Valeur officielle :

```text
UCKK Ops Console
```

### 8.2 `app.root`

Racine de l’application.

Valeur prévue :

```text
C:\mycode\UCKK\UCKK_ops_console
```

### 8.3 `app.language`

Langue visible principale.

Valeur officielle :

```text
fr
```

Définition :

```text
fr = français.
```

## 9. Section `paths`

La section :

```json
"paths": {}
```

contient les chemins principaux.

Un chemin doit être lisible et nommé selon son rôle.

Champs officiels :

```text
uckkMoodleSource
localMoodleRuntime
localMoodleRoot
serverMoodleSource
serverMoodleRoot
serverMoodleRuntime
reportsDir
logsDir
legacyDir
recoveryDir
```

## 10. Chemin `paths.uckkMoodleSource`

Nom officiel :

```text
uckkMoodleSource
```

Définition :

```text
Dossier source local du projet Moodle UCKK.
```

Valeur prévue :

```text
C:\mycode\UCKK\uckk-moodle
```

Ce chemin correspond au code source local que l’on modifie.

Il ne doit pas être confondu avec Moodle local exécuté.

## 11. Chemin `paths.localMoodleRuntime`

Nom officiel :

```text
localMoodleRuntime
```

Définition :

```text
Dossier local exécuté par Moodle.
```

Valeur prévue :

```text
C:\mycode\UCKK\moodle\moodle\public
```

Ce dossier est la cible de la synchronisation locale.

Quand l’application fait :

```text
Synchroniser source vers Moodle local
```

elle copie depuis :

```text
paths.uckkMoodleSource
```

vers :

```text
paths.localMoodleRuntime
```

selon les règles du module Local.

## 12. Chemin `paths.localMoodleRoot`

Nom officiel :

```text
localMoodleRoot
```

Définition :

```text
Racine Moodle locale.
```

Valeur prévue selon l’environnement local :

```text
C:\mycode\UCKK\moodle\moodle
```

ou, si le Moodle local utilise directement `public` comme racine technique :

```text
C:\mycode\UCKK\moodle\moodle\public
```

Règle :

```text
Le code doit utiliser le champ prévu pour l’action, pas deviner la racine à partir d’un autre chemin.
```

## 13. Chemin `paths.serverMoodleSource`

Nom officiel :

```text
serverMoodleSource
```

Définition :

```text
Dossier source du code UCKK sur le serveur.
```

Valeur prévue :

```text
/opt/uckk/uckk-moodle
```

Ce chemin est sur le serveur.

Il ne doit pas être utilisé comme chemin Windows local.

## 14. Chemin `paths.serverMoodleRoot`

Nom officiel :

```text
serverMoodleRoot
```

Définition :

```text
Racine Moodle sur le serveur.
```

Valeur prévue :

```text
/var/www/moodle
```

## 15. Chemin `paths.serverMoodleRuntime`

Nom officiel :

```text
serverMoodleRuntime
```

Définition :

```text
Dossier exécuté par Moodle sur le serveur.
```

Valeur prévue :

```text
/var/www/moodle/public
```

Ce dossier est la cible de la synchronisation serveur.

## 16. Chemin `paths.reportsDir`

Nom officiel :

```text
reportsDir
```

Définition :

```text
Dossier où l’application écrit les rapports lisibles.
```

Valeur prévue :

```text
./reports
```

## 17. Chemin `paths.logsDir`

Nom officiel :

```text
logsDir
```

Définition :

```text
Dossier où l’application écrit les logs techniques.
```

Valeur prévue :

```text
./logs
```

## 18. Chemin `paths.legacyDir`

Nom officiel :

```text
legacyDir
```

Définition :

```text
Dossier des anciens outils conservés pour référence.
```

Valeur prévue :

```text
./legacy
```

## 19. Chemin `paths.recoveryDir`

Nom officiel :

```text
recoveryDir
```

Définition :

```text
Dossier des outils de récupération.
```

Valeur prévue :

```text
./recovery
```

## 20. Section `urls`

La section :

```json
"urls": {}
```

contient les URLs principales.

Définition :

```text
URL = adresse d’une page web.
```

Champs officiels :

```text
localBase
serverBase
localMediatheque
serverMediatheque
localCourseIndex
serverCourseIndex
```

## 21. URL `urls.localBase`

Nom officiel :

```text
localBase
```

Définition :

```text
Adresse de base du Moodle local.
```

Valeur prévue :

```text
http://localhost:8000
```

ou :

```text
http://127.0.0.1:8000
```

Règle :

```text
Choisir une seule valeur officielle dans la configuration et l’utiliser partout.
```

## 22. URL `urls.serverBase`

Nom officiel :

```text
serverBase
```

Définition :

```text
Adresse de base du site public UCKK.
```

Valeur officielle :

```text
https://uckk.org
```

## 23. URL `urls.localMediatheque`

Nom officiel :

```text
localMediatheque
```

Définition :

```text
Adresse de la Médiathèque locale.
```

Valeur prévue :

```text
http://localhost:8000/local/uckk/mediatheque.php
```

ou selon `localBase` :

```text
{localBase}/local/uckk/mediatheque.php
```

## 24. URL `urls.serverMediatheque`

Nom officiel :

```text
serverMediatheque
```

Définition :

```text
Adresse de la Médiathèque serveur.
```

Valeur officielle :

```text
https://uckk.org/local/uckk/mediatheque.php
```

## 25. URL `urls.localCourseIndex`

Nom officiel :

```text
localCourseIndex
```

Définition :

```text
Adresse locale de l’index des cours Moodle.
```

Valeur prévue :

```text
http://localhost:8000/course/index.php
```

## 26. URL `urls.serverCourseIndex`

Nom officiel :

```text
serverCourseIndex
```

Définition :

```text
Adresse serveur de l’index des cours Moodle.
```

Valeur officielle :

```text
https://uckk.org/course/index.php
```

## 27. Section `server`

La section :

```json
"server": {}
```

contient les informations de connexion serveur qui ne sont pas des secrets.

Champs officiels :

```text
sshHost
sshUser
sshTarget
```

## 28. Champ `server.sshHost`

Nom officiel :

```text
sshHost
```

Définition :

```text
Adresse ou IP du serveur.
```

Valeur connue :

```text
57.129.115.159
```

Ce champ n’est pas un secret en soi, mais il ne doit pas être mélangé avec un mot de passe.

## 29. Champ `server.sshUser`

Nom officiel :

```text
sshUser
```

Définition :

```text
Nom d’utilisateur utilisé pour la connexion SSH.
```

Valeur connue :

```text
ubuntu
```

## 30. Champ `server.sshTarget`

Nom officiel :

```text
sshTarget
```

Définition :

```text
Cible SSH complète sous forme utilisateur@serveur.
```

Valeur connue :

```text
ubuntu@57.129.115.159
```

Ce champ peut être construit automatiquement à partir de :

```text
server.sshUser
server.sshHost
```

Règle :

```text
Ne pas répéter inutilement sshTarget si l’application peut le construire de manière fiable.
```

## 31. Section `git`

La section :

```json
"git": {}
```

contient les paramètres Git.

Champs officiels :

```text
repoRoot
mainBranch
remoteName
```

### 31.1 `git.repoRoot`

Définition :

```text
Dossier racine du dépôt Git à vérifier.
```

Valeur prévue :

```text
C:\mycode\UCKK\uckk-moodle
```

### 31.2 `git.mainBranch`

Définition :

```text
Branche principale utilisée pour publier.
```

Valeur à configurer selon le dépôt :

```text
main
```

ou :

```text
master
```

L’application ne doit pas deviner silencieusement si les deux existent.

### 31.3 `git.remoteName`

Définition :

```text
Nom du dépôt distant Git.
```

Valeur habituelle :

```text
origin
```

## 32. Section `moodle`

La section :

```json
"moodle": {}
```

contient les paramètres Moodle utiles aux actions.

Champs officiels :

```text
localPhpPath
serverPhpPath
adminCliPath
purgeCachesScript
```

### 32.1 `moodle.localPhpPath`

Définition :

```text
Chemin ou nom de la commande PHP locale.
```

Valeur possible :

```text
php
```

ou un chemin complet si nécessaire.

### 32.2 `moodle.serverPhpPath`

Définition :

```text
Chemin ou nom de la commande PHP sur le serveur.
```

Valeur possible :

```text
php
```

### 32.3 `moodle.adminCliPath`

Définition :

```text
Chemin relatif vers les scripts CLI d’administration Moodle.
```

Valeur habituelle :

```text
admin/cli
```

Définition :

```text
CLI = interface en ligne de commande.
```

### 32.4 `moodle.purgeCachesScript`

Définition :

```text
Script Moodle utilisé pour purger les caches.
```

Valeur habituelle :

```text
admin/cli/purge_caches.php
```

## 33. Section `mediatheque`

La section :

```json
"mediatheque": {}
```

contient les paramètres de la Médiathèque.

Champs officiels :

```text
manifestPath
serviceName
localArchiveId
localCourseId
localCmId
localContextId
serverArchiveId
serverCourseId
serverCmId
serverContextId
```

## 34. Champ `mediatheque.manifestPath`

Nom officiel :

```text
manifestPath
```

Définition :

```text
Chemin vers le manifeste Médiathèque.
```

Définition :

```text
Manifeste Médiathèque = fichier source qui liste les références de la Médiathèque.
```

Valeur prévue :

```text
C:\mycode\UCKK\uckk-moodle\content\mediatheque\mediatheque.catalog.json
```

ou, si le manifeste vit dans le dépôt source :

```text
{paths.uckkMoodleSource}\content\mediatheque\mediatheque.catalog.json
```

Règle :

```text
La configuration doit permettre de trouver le manifeste sans deviner son emplacement.
```

## 35. Champ `mediatheque.serviceName`

Nom officiel :

```text
serviceName
```

Définition :

```text
Nom technique du service Moodle utilisé pour chercher les références Médiathèque.
```

Valeur actuelle :

```text
mod_uckkarchive_search_mediatheque
```

Dans l’interface, afficher :

```text
Service Médiathèque : mod_uckkarchive_search_mediatheque
```

et non seulement le nom technique.

## 36. Champs d’identifiants Médiathèque

Champs locaux :

```text
localArchiveId
localCourseId
localCmId
localContextId
```

Champs serveur :

```text
serverArchiveId
serverCourseId
serverCmId
serverContextId
```

Définitions :

```text
archiveId = identifiant de l’activité uckkarchive dans Moodle.

courseId = identifiant du cours Moodle.

cmId = identifiant du module de cours Moodle.

contextId = identifiant du contexte Moodle lié à l’activité.
```

Ces noms sont techniques.

Ils peuvent apparaître dans la configuration et les rapports techniques.

Dans l’interface normale, les afficher avec une explication.

Exemple :

```text
Activité Médiathèque serveur : archiveId 114, courseId 115, cmId 332, contextId 480.
```

## 37. Important sur la cible Médiathèque serveur

L’état actuel connu peut utiliser une cible temporaire :

```text
serverArchiveId = 114
serverCourseId = 115
serverCmId = 332
serverContextId = 480
```

Cette cible correspond à une activité serveur existante.

Règle :

```text
La configuration doit rendre cette cible explicite.
Elle ne doit pas être cachée dans le code.
```

À terme, une vraie activité serveur centrale pourra être créée.

Nom conceptuel :

```text
Médiathèque centrale UCKK
```

ou :

```text
Registraire — Médiathèque centrale
```

Quand cette cible changera, la modification devra se faire dans la configuration.

## 38. Section `reports`

La section :

```json
"reports": {}
```

contient les règles de rapports.

Champs officiels :

```text
enabled
dir
format
keepLast
```

### 38.1 `reports.enabled`

Définition :

```text
Indique si l’application écrit des rapports.
```

Valeur obligatoire recommandée :

```text
true
```

### 38.2 `reports.dir`

Définition :

```text
Dossier de rapports.
```

Valeur prévue :

```text
./reports
```

### 38.3 `reports.format`

Définition :

```text
Format principal des rapports lisibles.
```

Valeur recommandée :

```text
markdown
```

Définition :

```text
Markdown = format texte lisible qui peut contenir titres, listes et blocs de code.
```

### 38.4 `reports.keepLast`

Définition :

```text
Nombre de rapports récents à conserver ou afficher rapidement.
```

Cette valeur ne doit pas supprimer des rapports sans règle claire.

## 39. Section `logs`

La section :

```json
"logs": {}
```

contient les règles de logs techniques.

Champs officiels :

```text
enabled
dir
level
```

### 39.1 `logs.enabled`

Définition :

```text
Indique si l’application écrit des logs techniques.
```

Valeur recommandée :

```text
true
```

### 39.2 `logs.dir`

Définition :

```text
Dossier de logs techniques.
```

Valeur prévue :

```text
./logs
```

### 39.3 `logs.level`

Définition :

```text
Niveau de détail des logs.
```

Valeurs possibles :

```text
normal
debug
```

Définition :

```text
debug = niveau plus détaillé utilisé pour diagnostiquer un problème.
```

Dans l’interface, afficher :

```text
Niveau détaillé
```

plutôt que `debug`, sauf dans les détails techniques.

## 40. Section `safety`

La section :

```json
"safety": {}
```

contient les règles de sécurité activées.

Champs officiels :

```text
confirmServerActions
confirmDatabaseWrites
confirmGitWrites
confirmRecoveryActions
requireBackupForRecovery
```

Valeurs recommandées :

```text
true
```

pour tous ces champs.

## 41. Exemple complet de configuration

Exemple de départ :

```json
{
  "app": {
    "name": "UCKK Ops Console",
    "root": "C:\\\\mycode\\\\UCKK\\\\UCKK_ops_console",
    "language": "fr"
  },
  "paths": {
    "uckkMoodleSource": "C:\\\\mycode\\\\UCKK\\\\uckk-moodle",
    "localMoodleRoot": "C:\\\\mycode\\\\UCKK\\\\moodle\\\\moodle",
    "localMoodleRuntime": "C:\\\\mycode\\\\UCKK\\\\moodle\\\\moodle\\\\public",
    "serverMoodleSource": "/opt/uckk/uckk-moodle",
    "serverMoodleRoot": "/var/www/moodle",
    "serverMoodleRuntime": "/var/www/moodle/public",
    "reportsDir": "./reports",
    "logsDir": "./logs",
    "legacyDir": "./legacy",
    "recoveryDir": "./recovery"
  },
  "urls": {
    "localBase": "http://localhost:8000",
    "serverBase": "https://uckk.org",
    "localMediatheque": "http://localhost:8000/local/uckk/mediatheque.php",
    "serverMediatheque": "https://uckk.org/local/uckk/mediatheque.php",
    "localCourseIndex": "http://localhost:8000/course/index.php",
    "serverCourseIndex": "https://uckk.org/course/index.php"
  },
  "server": {
    "sshHost": "57.129.115.159",
    "sshUser": "ubuntu",
    "sshTarget": "ubuntu@57.129.115.159"
  },
  "git": {
    "repoRoot": "C:\\\\mycode\\\\UCKK\\\\uckk-moodle",
    "mainBranch": "main",
    "remoteName": "origin"
  },
  "moodle": {
    "localPhpPath": "php",
    "serverPhpPath": "php",
    "adminCliPath": "admin/cli",
    "purgeCachesScript": "admin/cli/purge_caches.php"
  },
  "mediatheque": {
    "manifestPath": "C:\\\\mycode\\\\UCKK\\\\uckk-moodle\\\\content\\\\mediatheque\\\\mediatheque.catalog.json",
    "serviceName": "mod_uckkarchive_search_mediatheque",
    "localArchiveId": 115,
    "localCourseId": 116,
    "localCmId": 339,
    "localContextId": 491,
    "serverArchiveId": 114,
    "serverCourseId": 115,
    "serverCmId": 332,
    "serverContextId": 480
  },
  "reports": {
    "enabled": true,
    "dir": "./reports",
    "format": "markdown",
    "keepLast": 50
  },
  "logs": {
    "enabled": true,
    "dir": "./logs",
    "level": "normal"
  },
  "safety": {
    "confirmServerActions": true,
    "confirmDatabaseWrites": true,
    "confirmGitWrites": true,
    "confirmRecoveryActions": true,
    "requireBackupForRecovery": true
  }
}
```

## 42. Règle sur les chemins relatifs

Un chemin relatif est un chemin qui dépend de la racine de l’application.

Définition :

```text
Chemin relatif = chemin qui commence depuis un dossier de référence plutôt que depuis la racine du disque.
```

Exemple :

```text
./reports
```

signifie :

```text
dossier reports dans la racine de l’application
```

Règle :

```text
Les chemins relatifs dans la configuration sont relatifs à app.root.
```

## 43. Règle sur les chemins Windows et serveur

Les chemins Windows utilisent généralement :

```text
C:\...
```

Les chemins serveur Linux utilisent généralement :

```text
/...
```

Règle :

```text
Le code ne doit pas mélanger les chemins Windows et Linux.
```

Exemple incorrect :

```text
C:\mycode\UCKK\uckk-moodle utilisé dans une commande SSH serveur.
```

Exemple correct :

```text
/opt/uckk/uckk-moodle utilisé dans une commande SSH serveur.
```

## 44. Règle sur la normalisation des chemins

Définition :

```text
Normaliser un chemin = transformer un chemin en forme claire et utilisable par le système.
```

L’application doit normaliser les chemins avant de les utiliser.

Elle doit vérifier qu’un chemin requis existe avant de lancer une action qui en dépend.

Exemple :

```text
Avant de synchroniser source vers Moodle local, vérifier que paths.uckkMoodleSource et paths.localMoodleRuntime existent.
```

## 45. Règle sur les chemins manquants

Si un chemin requis manque, l’application doit afficher une erreur lisible.

Format :

```text
L’action a échoué.
Cause probable : un chemin requis est introuvable.
Prochaine étape : vérifier la configuration.
Détail technique : paths.localMoodleRuntime = ...
```

Ne pas afficher seulement :

```text
Path not found
```

## 46. Règle sur les URLs manquantes

Si une URL requise manque, l’application doit afficher une erreur lisible.

Format :

```text
L’action a échoué.
Cause probable : une URL requise est absente de la configuration.
Prochaine étape : vérifier la section urls.
Détail technique : urls.serverMediatheque est vide.
```

## 47. Règle sur la validation de la configuration

Au lancement, l’application doit valider la configuration.

Définition :

```text
Valider = vérifier qu’une valeur existe, a le bon format et peut être utilisée.
```

La validation doit vérifier au minimum :

```text
app.root existe ;
paths.uckkMoodleSource existe ;
paths.localMoodleRuntime existe ;
reportsDir peut être créé ou existe ;
logsDir peut être créé ou existe ;
urls.serverBase est une URL ;
urls.localBase est une URL ;
server.sshUser est défini ;
server.sshHost est défini ;
mediatheque.serviceName est défini ;
safety contient les confirmations obligatoires.
```

## 48. Règle sur la création automatique des dossiers

L’application peut créer automatiquement :

```text
reportsDir ;
logsDir.
```

Elle ne doit pas créer automatiquement :

```text
uckkMoodleSource ;
localMoodleRuntime ;
serverMoodleSource ;
serverMoodleRoot ;
serverMoodleRuntime.
```

Raison :

```text
Ces dossiers représentent des systèmes existants. Les créer automatiquement pourrait cacher une mauvaise configuration.
```

## 49. Règle sur les valeurs absentes

Si une valeur de configuration est absente, le code ne doit pas inventer silencieusement une valeur dangereuse.

Exemple interdit :

```text
serverMoodleRuntime absent → utiliser /var/www/html par défaut.
```

Exemple correct :

```text
serverMoodleRuntime absent → afficher une erreur de configuration.
```

Les valeurs par défaut sont acceptables seulement si elles sont documentées et non dangereuses.

Exemples acceptables :

```text
reports.dir = ./reports
logs.dir = ./logs
reports.format = markdown
logs.level = normal
```

## 50. Règle sur l’affichage de la configuration

L’application peut afficher la configuration à l’utilisateur.

Mais elle doit masquer ou éviter les champs sensibles si un jour ils existent.

Même si les secrets sont interdits, le code doit éviter d’encourager leur affichage.

Règle :

```text
Ne jamais afficher de mot de passe, token ou clé privée dans l’interface, un rapport ou un log.
```

## 51. Règle sur les rapports de configuration

L’action :

```text
Vérifier la configuration
```

doit produire un rapport.

Le rapport doit indiquer :

```text
valeurs présentes ;
valeurs manquantes ;
chemins trouvés ;
chemins introuvables ;
URLs valides ;
URLs invalides ;
prochaine étape.
```

Il ne doit pas afficher de secret.

## 52. Règle sur les anciennes configurations

Les anciens fichiers de configuration peuvent être consultés pour migration.

Mais ils ne doivent pas devenir la source principale de la nouvelle app.

Règle :

```text
La nouvelle app lit seulement ./config/uckk-ops-console.config.json comme configuration principale.
```

Si une migration est nécessaire, elle doit être explicite.

Définition :

```text
Migration = transformation contrôlée d’une ancienne configuration vers la nouvelle structure.
```

## 53. Règle anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
écrire des chemins absolus directement dans les modules ;
inventer un deuxième fichier de configuration principal ;
mettre des secrets dans la configuration ;
utiliser un chemin serveur comme chemin local ;
utiliser un chemin local dans une commande SSH ;
deviner silencieusement des valeurs serveur ;
créer automatiquement des dossiers système critiques ;
ignorer une valeur manquante ;
afficher une erreur technique brute pour un chemin manquant.
```

Si une nouvelle valeur de configuration semble nécessaire, l’IA doit proposer une modification de ce document avant de l’utiliser.

## 54. Résumé obligatoire

Fichier de configuration principal :

```text
./config/uckk-ops-console.config.json
```

Sections officielles :

```text
app
paths
urls
server
git
moodle
mediatheque
reports
logs
safety
```

Règle finale :

```text
Les chemins, URLs et paramètres ne doivent pas être cachés dans le code.
Ils doivent être déclarés, nommés, validés et expliqués dans la configuration.


## Clarification — racine Moodle vs webroot

`paths.localMoodleRoot` désigne la racine du code Moodle utilisée pour les commandes CLI.

`paths.localMoodleRuntime` désigne le document root HTTP servi localement.

Ces chemins peuvent être différents, notamment lorsque Moodle expose un sous-dossier
`public/` comme webroot. Les actions CLI ne doivent donc pas concaténer
`admin/cli/...` à `localMoodleRuntime` sans détection.

L'action `Diagnostiquer Moodle local` teste les racines candidates et affiche le chemin
effectivement retenu.
