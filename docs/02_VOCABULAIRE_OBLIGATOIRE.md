# 02 — Vocabulaire obligatoire

## 1. Rôle de ce document

Ce document définit le vocabulaire obligatoire de la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il sert à empêcher l’IA de coder une interface avec des mots vagues, techniques ou contradictoires.

Il s’applique à tous les textes visibles par l’utilisateur :

```text
onglets ;
boutons ;
descriptions ;
confirmations ;
messages de succès ;
messages d’avertissement ;
messages d’erreur ;
rapports ;
aide intégrée.
```

Définition :

```text
Texte visible = texte que l’utilisateur voit dans l’application ou dans un rapport.
```

Le code interne peut utiliser des noms techniques, mais l’interface visible doit respecter ce document.

## 2. Principe central

L’application doit utiliser un vocabulaire simple, stable et défini.

Règle :

```text
Un même concept doit toujours avoir le même nom.
```

Mauvais exemple :

```text
simulation ;
dry-run ;
prévisualisation ;
test sans écriture ;
mode no-write.
```

Bon exemple :

```text
Simulation
```

Le mot anglais peut être indiqué entre parenthèses au besoin :

```text
Simulation (dry-run)
```

Mais le mot principal visible doit rester :

```text
Simulation
```

## 3. Langue visible

La langue visible principale est le français.

Les mots anglais sont acceptés seulement dans trois cas :

```text
nom technique connu ;
nom de commande ;
équivalent entre parenthèses après le mot français.
```

Exemples corrects :

```text
Simulation (dry-run)
Appliquer (apply)
Commit Git
Push Git
Service AJAX
```

Exemples à éviter :

```text
Run dry-run
Apply server
Deploy now
Smoke test
Fix DB
```

Si un mot anglais est nécessaire, il doit être défini dans ce document.

## 4. Noms des cibles

Une cible est l’endroit où une action lit ou modifie quelque chose.

Définition :

```text
Cible = endroit visé par une action.
```

Les cibles officielles sont :

```text
local ;
serveur ;
Git ;
base Moodle locale ;
base Moodle serveur ;
Médiathèque locale ;
Médiathèque serveur.
```

### 4.1 Local

Nom visible officiel :

```text
Local
```

Définition :

```text
Local = l’ordinateur de développement.
```

Exemple :

```text
Moodle local = le Moodle qui fonctionne sur l’ordinateur de développement.
```

À ne pas confondre avec :

```text
serveur
```

### 4.2 Serveur

Nom visible officiel :

```text
Serveur
```

Définition :

```text
Serveur = l’ordinateur distant qui héberge le site public.
```

Dans ce projet, le serveur public est :

```text
uckk.org
```

Quand une action touche le serveur, le texte visible doit le dire clairement.

Exemple correct :

```text
Appliquer Médiathèque serveur
```

Exemple interdit :

```text
Appliquer Médiathèque
```

Ce deuxième exemple est interdit parce qu’il ne dit pas si l’action vise local ou serveur.

### 4.3 uckk.org

Nom visible officiel :

```text
uckk.org
```

Définition :

```text
uckk.org = site public UCKK hébergé sur le serveur.
```

Quand une action peut modifier le vrai site public, utiliser explicitement :

```text
uckk.org
```

Exemple :

```text
Cette action modifie uckk.org ou sa base Moodle. Continuer ?
```

## 5. Noms des opérations

### 5.1 Vérifier

Nom visible officiel :

```text
Vérifier
```

Définition :

```text
Vérifier = contrôler un état sans modifier les données.
```

Une action “Vérifier” ne doit pas écrire dans la base Moodle, modifier Git ou modifier le serveur.

Exemples :

```text
Vérifier les chemins locaux
Vérifier Git
Vérifier uckk.org
Vérifier Médiathèque serveur
```

### 5.2 Ouvrir

Nom visible officiel :

```text
Ouvrir
```

Définition :

```text
Ouvrir = lancer un dossier, un fichier, une page ou un rapport pour consultation.
```

Une action “Ouvrir” ne doit pas modifier les données.

Exemples :

```text
Ouvrir Moodle local
Ouvrir la Médiathèque serveur
Ouvrir le dernier rapport
```

### 5.3 Synchroniser

Nom visible officiel :

```text
Synchroniser
```

Définition :

```text
Synchroniser = copier ou aligner une source vers une cible.
```

Le mot “synchroniser” doit toujours indiquer la direction.

Exemple correct :

```text
Synchroniser source vers Moodle local
```

Exemple incorrect :

```text
Synchroniser
```

Ce mot seul est trop vague.

### 5.4 Simulation

Nom visible officiel :

```text
Simulation
```

Équivalent technique :

```text
dry-run
```

Définition :

```text
Simulation = action qui montre ce qui serait fait, sans modifier les données.
```

Une simulation ne doit pas écrire dans la base Moodle.

Une simulation ne doit pas modifier Git.

Une simulation ne doit pas modifier le serveur.

Exemples :

```text
Simulation Médiathèque locale
Simulation Médiathèque serveur
Simulation données Moodle
```

Le mot `dry-run` ne doit pas être le mot principal d’un bouton.

### 5.5 Appliquer

Nom visible officiel :

```text
Appliquer
```

Équivalent technique :

```text
apply
```

Définition :

```text
Appliquer = écrire réellement les changements.
```

Une action “Appliquer” doit dire la cible.

Exemples corrects :

```text
Appliquer Médiathèque localement
Appliquer Médiathèque serveur
Appliquer catégories Moodle localement
Appliquer catégories Moodle serveur
```

Exemple interdit :

```text
Apply
```

Le mot est en anglais et ne dit pas la cible.

### 5.6 Publier

Nom visible officiel :

```text
Publier
```

Définition :

```text
Publier = rendre une version disponible sur le serveur public.
```

Dans cette application, “publier” doit être utilisé seulement quand l’action concerne `uckk.org`.

Exemple :

```text
Publier sur serveur
```

### 5.7 Purger les caches

Nom visible officiel :

```text
Purger les caches
```

Définition :

```text
Purger les caches = vider la mémoire temporaire de Moodle pour qu’il recharge les changements.
```

Ne pas utiliser seulement :

```text
Purge
```

Le mot visible doit être complet :

```text
Purger les caches locaux
Purger les caches serveur
```

### 5.8 Recharger PHP-FPM

Nom visible officiel :

```text
Recharger PHP-FPM
```

Définition :

```text
PHP-FPM = service du serveur qui exécute le code PHP de Moodle.
```

Définition :

```text
Recharger PHP-FPM = demander au serveur de relire son état PHP sans redémarrer toute la machine.
```

Cette action est technique.

Elle ne doit pas être dans l’accueil sauf si elle est incluse dans un bouton plus simple de publication serveur.

### 5.9 Mettre à jour Moodle

Nom visible officiel :

```text
Mettre à jour Moodle
```

Équivalent technique possible :

```text
Moodle upgrade
```

Définition :

```text
Mettre à jour Moodle = lancer l’étape où Moodle applique les changements nécessaires après une modification de code ou de structure.
```

Ne pas utiliser comme bouton principal :

```text
Upgrade
```

Utiliser :

```text
Mettre à jour Moodle serveur
```

ou :

```text
Mettre à jour Moodle local
```

## 6. Mots de projet

### 6.1 UCKK Ops Console

Nom officiel :

```text
UCKK Ops Console
```

Définition :

```text
UCKK Ops Console = application locale qui guide les opérations courantes du projet UCKK.
```

Ne pas renommer spontanément l’application.

Noms interdits sans décision explicite :

```text
Ops Panel
UCKK Manager
UCKK Admin
UCKK Toolbox
```

### 6.2 Projet UCKK

Nom visible officiel :

```text
Projet UCKK
```

Définition :

```text
Projet UCKK = ensemble du code, du site, des données et des outils liés à l’Univers-Cité King Klown.
```

### 6.3 Moodle

Nom visible officiel :

```text
Moodle
```

Définition :

```text
Moodle = plateforme utilisée par UCKK pour organiser des cours, activités, plugins et données pédagogiques.
```

### 6.4 Plugin Moodle

Nom visible officiel :

```text
Plugin Moodle
```

Définition :

```text
Plugin Moodle = morceau de code ajouté à Moodle pour lui donner une fonction spécifique.
```

Exemples dans le projet :

```text
local_uckk
mod_uckkarchive
```

## 7. Chemins, dossiers et fichiers

### 7.1 Chemin

Nom visible officiel :

```text
Chemin
```

Définition :

```text
Chemin = adresse d’un fichier ou d’un dossier sur un ordinateur.
```

Exemple :

```text
C:\mycode\UCKK\UCKK_ops_console
```

### 7.2 Racine

Nom visible officiel :

```text
Racine
```

Définition :

```text
Racine = dossier principal d’un projet ou d’une application.
```

Racine officielle de cette application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

### 7.3 Source

Nom visible officiel :

```text
Source
```

Définition :

```text
Source = dossier qui contient le code officiel que l’on modifie.
```

Ne pas confondre avec :

```text
runtime
```

### 7.4 Runtime

Nom visible officiel :

```text
Runtime
```

Traduction explicative obligatoire :

```text
dossier exécuté par Moodle
```

Définition :

```text
Runtime = dossier que Moodle exécute réellement.
```

Dans les textes visibles, ne jamais utiliser `runtime` seul.

Utiliser :

```text
Runtime (dossier exécuté par Moodle)
```

ou :

```text
dossier exécuté par Moodle
```

### 7.5 Config

Nom visible officiel :

```text
Configuration
```

Mot technique équivalent :

```text
config
```

Définition :

```text
Configuration = fichier de paramètres lu par l’application.
```

Le mot visible principal doit être :

```text
Configuration
```

### 7.6 Codé en dur

Nom visible officiel :

```text
Codé en dur
```

Définition :

```text
Codé en dur = écrit directement dans le code au lieu d’être lu depuis la configuration.
```

Règle visible :

```text
Les chemins et URLs ne doivent pas être codés en dur.
```

### 7.7 Dossier

Nom visible officiel :

```text
Dossier
```

Définition :

```text
Dossier = emplacement qui contient des fichiers ou d’autres dossiers.
```

### 7.8 Fichier

Nom visible officiel :

```text
Fichier
```

Définition :

```text
Fichier = document ou morceau de code enregistré sur disque.
```

## 8. Git

### 8.1 Git

Nom visible officiel :

```text
Git
```

Définition :

```text
Git = système qui garde l’historique des changements du projet.
```

### 8.2 État Git

Nom visible officiel :

```text
État Git
```

Définition :

```text
État Git = résumé des fichiers changés, ajoutés ou non enregistrés.
```

### 8.3 Différences Git

Nom visible officiel :

```text
Différences Git
```

Mot technique équivalent :

```text
diff
```

Définition :

```text
Différences Git = détail des changements depuis la dernière version enregistrée.
```

Ne pas afficher seulement :

```text
Diff
```

sauf dans un contexte technique.

### 8.4 Commit

Nom visible officiel :

```text
Commit Git
```

Définition :

```text
Commit Git = sauvegarde officielle d’un ensemble de changements dans l’historique du projet.
```

Ne pas utiliser “commit” seul dans un bouton destiné à un non-expert.

Utiliser :

```text
Créer un commit Git
```

### 8.5 Push

Nom visible officiel :

```text
Envoyer vers Git
```

Mot technique équivalent :

```text
push
```

Définition :

```text
Push = envoyer les commits vers le dépôt distant.
```

Bouton recommandé :

```text
Envoyer les changements vers Git
```

### 8.6 Pull

Nom visible officiel :

```text
Récupérer depuis Git
```

Mot technique équivalent :

```text
pull
```

Définition :

```text
Pull = récupérer les derniers changements depuis le dépôt distant.
```

## 9. Serveur et connexion

### 9.1 SSH

Nom visible officiel :

```text
Connexion SSH
```

Définition :

```text
SSH = méthode sécurisée pour se connecter au serveur et y lancer des commandes.
```

Ne pas utiliser seulement :

```text
SSH
```

dans un bouton sans description.

### 9.2 Commande

Nom visible officiel :

```text
Commande
```

Définition :

```text
Commande = instruction lancée par l’ordinateur ou le serveur.
```

### 9.3 Code de retour

Nom visible officiel :

```text
Code de retour
```

Définition :

```text
Code de retour = nombre donné par une commande pour indiquer si elle a réussi ou échoué.
```

Explication recommandée :

```text
Code de retour 0 = réussite habituelle.
Un autre code indique généralement une erreur.
```

### 9.4 Sortie technique

Nom visible officiel :

```text
Sortie technique
```

Définition :

```text
Sortie technique = texte brut produit par une commande ou un programme.
```

Une sortie technique ne doit pas remplacer un message lisible.

## 10. Base Moodle et données

### 10.1 Base Moodle

Nom visible officiel :

```text
Base Moodle
```

Mot technique équivalent :

```text
DB
```

Définition :

```text
Base Moodle = base de données utilisée par Moodle pour stocker son état actif.
```

Ne pas utiliser `DB` seul dans l’interface.

Utiliser :

```text
Base Moodle
```

ou :

```text
Base Moodle (DB)
```

### 10.2 Base Moodle locale

Nom visible officiel :

```text
Base Moodle locale
```

Définition :

```text
Base Moodle locale = base de données utilisée par le Moodle local.
```

### 10.3 Base Moodle serveur

Nom visible officiel :

```text
Base Moodle serveur
```

Définition :

```text
Base Moodle serveur = base de données utilisée par le Moodle public sur uckk.org.
```

Toute action qui touche la base Moodle serveur est dangereuse.

### 10.4 Table

Nom visible officiel :

```text
Table
```

Définition :

```text
Table = zone de la base Moodle qui contient un type de données.
```

Exemple :

```text
uckkarchive_media
```

### 10.5 Enregistrement

Nom visible officiel :

```text
Enregistrement
```

Définition :

```text
Enregistrement = une ligne de données dans une table.
```

Exemple :

```text
Une référence Médiathèque peut correspondre à plusieurs enregistrements dans plusieurs tables.
```

### 10.6 SQL

Nom visible officiel :

```text
SQL
```

Définition :

```text
SQL = langage technique utilisé pour lire ou modifier une base de données.
```

Règle :

```text
Le SQL brut ne doit pas être un workflow normal.
```

### 10.7 Dump SQL

Nom visible officiel :

```text
Dump SQL
```

Définition :

```text
Dump SQL = copie brute d’une base de données ou d’une partie de base de données.
```

Règle :

```text
Un dump SQL ne doit pas être utilisé comme méthode normale pour synchroniser la Médiathèque.
```

## 11. Médiathèque

### 11.1 Médiathèque

Nom visible officiel :

```text
Médiathèque
```

Définition :

```text
Médiathèque = liste organisée de références publiques : vidéos, articles, sons, livres, pages web, dépôts de code et autres ressources.
```

### 11.2 Référence Médiathèque

Nom visible officiel :

```text
Référence Médiathèque
```

Définition :

```text
Référence Médiathèque = une entrée visible ou utilisable dans la Médiathèque.
```

### 11.3 Référence externe

Nom visible officiel :

```text
Référence externe
```

Définition :

```text
Référence externe = lien vers un contenu qui reste sur un autre site.
```

Exemples :

```text
YouTube
SoundCloud
Spotify
Medium
GitHub
PhilPapers
Amazon
```

Règle :

```text
Une référence externe ne doit pas être traitée comme un fichier média local à copier.
```

### 11.4 Fichier média local

Nom visible officiel :

```text
Fichier média local
```

Définition :

```text
Fichier média local = fichier réellement stocké sur l’ordinateur ou dans Moodle.
```

Exemples :

```text
image locale ;
PDF local ;
audio local ;
vidéo locale.
```

Règle :

```text
Ne pas confondre fichier média local et référence externe.
```

### 11.5 Manifeste Médiathèque

Nom visible officiel :

```text
Manifeste Médiathèque
```

Définition :

```text
Manifeste Médiathèque = fichier source qui liste les références de la Médiathèque.
```

Règle :

```text
Le workflow normal de la Médiathèque part du manifeste.
```

### 11.6 Collection

Nom visible officiel :

```text
Collection
```

Définition :

```text
Collection = groupe organisé de références Médiathèque.
```

### 11.7 Tag

Nom visible officiel :

```text
Tag
```

Traduction explicative :

```text
mot-clé
```

Définition :

```text
Tag = mot-clé associé à une référence pour aider au classement et à la recherche.
```

Dans un texte visible long, préférer :

```text
Tag (mot-clé)
```

### 11.8 Carte Médiathèque

Nom visible officiel :

```text
Carte Médiathèque
```

Définition :

```text
Carte Médiathèque = bloc visible dans l’interface qui représente une référence.
```

### 11.9 Service Médiathèque

Nom visible officiel :

```text
Service Médiathèque
```

Définition :

```text
Service Médiathèque = fonction Moodle appelée par la page pour chercher les références à afficher.
```

Nom technique actuel :

```text
mod_uckkarchive_search_mediatheque
```

Le nom technique peut apparaître dans les rapports, mais il doit être accompagné d’un libellé lisible.

Exemple :

```text
Service Médiathèque : mod_uckkarchive_search_mediatheque
```

### 11.10 AJAX

Nom visible officiel :

```text
AJAX
```

Définition :

```text
AJAX = méthode utilisée par une page web pour charger des données après l’ouverture de la page.
```

Exemple simple :

```text
La page Médiathèque peut s’ouvrir, puis charger les cartes ensuite par AJAX.
```

Règle :

```text
Une page qui répond ne garantit pas que les données AJAX sont correctes.
```

### 11.11 JavaScript

Nom visible officiel :

```text
JavaScript
```

Définition :

```text
JavaScript = langage utilisé dans le navigateur pour rendre une page interactive.
```

Dans le contexte Médiathèque :

```text
Les cartes peuvent être chargées par JavaScript après l’ouverture de la page.
```

## 12. Tables techniques Médiathèque

Ces noms peuvent apparaître dans les rapports techniques.

Ils ne doivent pas être les seuls mots affichés à l’utilisateur.

### 12.1 `uckkarchive_external_work`

Nom lisible :

```text
Référence externe principale
```

Définition :

```text
uckkarchive_external_work = table qui stocke la référence externe principale.
```

### 12.2 `uckkarchive_media`

Nom lisible :

```text
Carte Médiathèque
```

Définition :

```text
uckkarchive_media = table qui stocke l’entrée utilisée pour afficher une carte Médiathèque.
```

### 12.3 `uckkarchive_media_source`

Nom lisible :

```text
Source de la carte
```

Définition :

```text
uckkarchive_media_source = table qui relie une carte Médiathèque à son lien ou origine externe.
```

### 12.4 `uckkarchive_media_tag`

Nom lisible :

```text
Tags (mots-clés)
```

Définition :

```text
uckkarchive_media_tag = table qui stocke les mots-clés associés aux cartes.
```

### 12.5 `uckkarchive_media_collection`

Nom lisible :

```text
Collections
```

Définition :

```text
uckkarchive_media_collection = table qui stocke les collections de la Médiathèque.
```

### 12.6 `uckkarchive_media_collection_item`

Nom lisible :

```text
Liens collection-carte
```

Définition :

```text
uckkarchive_media_collection_item = table qui relie une collection à une carte Médiathèque.
```

## 13. Données Moodle

### 13.1 Données Moodle

Nom visible officiel :

```text
Données Moodle
```

Définition :

```text
Données Moodle = informations enregistrées dans Moodle, comme les catégories, cours, programmes, parcours, rôles et permissions.
```

### 13.2 JSON

Nom visible officiel :

```text
Fichier JSON
```

Définition :

```text
Fichier JSON = fichier texte structuré qui décrit des données.
```

Ne pas utiliser `JSON` seul dans un bouton si l’utilisateur doit comprendre l’action.

Exemple correct :

```text
Vérifier fichier JSON des catégories
```

### 13.3 Seed

Nom visible recommandé :

```text
Données à appliquer
```

Mot technique :

```text
seed
```

Définition :

```text
Seed = fichier ou action qui remplit ou met à jour la base Moodle avec des données prévues.
```

Dans l’interface, éviter `seed` seul.

### 13.4 Catégorie Moodle

Nom visible officiel :

```text
Catégorie Moodle
```

Définition :

```text
Catégorie Moodle = groupe qui organise des cours dans Moodle.
```

### 13.5 Cours Moodle

Nom visible officiel :

```text
Cours Moodle
```

Définition :

```text
Cours Moodle = espace Moodle contenant des activités, ressources ou contenus pédagogiques.
```

### 13.6 Programme

Nom visible officiel :

```text
Programme
```

Définition :

```text
Programme = structure UCKK qui regroupe des parcours, cours ou objectifs pédagogiques.
```

### 13.7 Parcours

Nom visible officiel :

```text
Parcours
```

Définition :

```text
Parcours = chemin organisé à l’intérieur d’un programme.
```

### 13.8 Rôle

Nom visible officiel :

```text
Rôle
```

Définition :

```text
Rôle = ensemble de permissions attribuées à un utilisateur dans Moodle.
```

### 13.9 Permission

Nom visible officiel :

```text
Permission
```

Définition :

```text
Permission = droit d’effectuer une action dans Moodle.
```

## 14. Rapports, logs et résultats

### 14.1 Rapport

Nom visible officiel :

```text
Rapport
```

Définition :

```text
Rapport = résumé lisible d’une action.
```

Un rapport doit être compréhensible sans lire le log technique.

### 14.2 Log

Nom visible officiel :

```text
Log technique
```

Définition :

```text
Log technique = journal détaillé utile pour diagnostiquer une action.
```

Ne pas afficher seulement :

```text
log
```

dans une zone destinée à un utilisateur non expert.

Utiliser :

```text
log technique
```

### 14.3 Résultat

Nom visible officiel :

```text
Résultat
```

Définition :

```text
Résultat = état final affiché après une action.
```

Résultats officiels :

```text
Réussi
Réussi avec avertissements
Échoué
À vérifier dans le navigateur
Annulé
```

### 14.4 Avertissement

Nom visible officiel :

```text
Avertissement
```

Définition :

```text
Avertissement = problème ou risque qui n’a pas nécessairement bloqué l’action.
```

### 14.5 Erreur

Nom visible officiel :

```text
Erreur
```

Définition :

```text
Erreur = problème qui a empêché l’action de réussir complètement.
```

### 14.6 Détail technique

Nom visible officiel :

```text
Détail technique
```

Définition :

```text
Détail technique = information plus précise utile pour diagnostiquer, mais pas nécessaire pour comprendre le résumé.
```

## 15. Récupération et anciens outils

### 15.1 Normal

Nom visible officiel :

```text
Normal
```

Définition :

```text
Normal = utilisé dans le workflow quotidien.
```

### 15.2 Legacy

Nom visible officiel :

```text
Legacy
```

Traduction explicative obligatoire :

```text
ancien outil
```

Définition :

```text
Legacy = ancien outil conservé pour référence, mais qui ne doit pas être utilisé dans le workflow normal.
```

Dans l’interface, préférer :

```text
Legacy (ancien outil)
```

### 15.3 Recovery

Nom visible officiel :

```text
Récupération
```

Mot technique équivalent :

```text
recovery
```

Définition :

```text
Récupération = action spéciale utilisée quand l’état normal est cassé.
```

Dans l’interface, utiliser :

```text
Récupération
```

plutôt que :

```text
Recovery
```

### 15.4 Test technique

Nom visible officiel :

```text
Test technique
```

Définition :

```text
Test technique = outil utilisé pour vérifier une hypothèse précise pendant le développement ou le diagnostic.
```

Un test technique ne doit pas être présenté comme workflow normal.

### 15.5 Sauvegarde

Nom visible officiel :

```text
Sauvegarde
```

Définition :

```text
Sauvegarde = copie conservée avant une action risquée pour pouvoir revenir en arrière.
```

### 15.6 Restaurer

Nom visible officiel :

```text
Restaurer
```

Définition :

```text
Restaurer = revenir à un état précédent à partir d’une sauvegarde.
```

### 15.7 Comparer

Nom visible officiel :

```text
Comparer
```

Définition :

```text
Comparer = vérifier les différences entre deux états.
```

Exemple :

```text
Comparer Médiathèque locale et Médiathèque serveur
```

## 16. Mots dangereux

Ces mots indiquent des actions risquées.

Ils ne doivent jamais apparaître dans le premier onglet comme actions normales.

### 16.1 Wipe

Nom visible interdit dans l’accueil :

```text
Wipe
```

Nom français obligatoire :

```text
Suppression complète
```

Définition :

```text
Wipe = suppression volontaire d’un ensemble de données avant reconstruction.
```

Si cette action existe, elle doit être dans Récupération avec confirmation forte.

### 16.2 Rebuild

Nom visible recommandé :

```text
Reconstruction complète
```

Définition :

```text
Rebuild = reconstruction complète d’un état à partir d’une autre source.
```

Ne pas utiliser comme action normale.

### 16.3 Import brut

Nom visible officiel :

```text
Import brut
```

Définition :

```text
Import brut = import de données sans workflow contrôlé, sans manifeste clair ou sans simulation lisible.
```

Interdit dans les workflows normaux.

### 16.4 Copie directe de tables

Nom visible officiel :

```text
Copie directe de tables
```

Définition :

```text
Copie directe de tables = transfert manuel de tables de base de données d’un environnement à un autre.
```

Interdit comme workflow normal.

### 16.5 Réparer

Nom visible à utiliser avec prudence :

```text
Réparer
```

Définition :

```text
Réparer = modifier un état cassé pour revenir à un fonctionnement normal.
```

Un bouton “Réparer” seul est interdit.

Il faut nommer précisément l’action.

Exemple correct :

```text
Reconstruire les collections Médiathèque depuis la sauvegarde
```

## 17. Mots interdits comme boutons seuls

Les mots suivants ne doivent pas être utilisés seuls comme libellés de boutons :

```text
Run
Go
Start
Fix
Sync
Apply
Deploy
Import
Export
Update
Clean
Repair
Reset
```

Ils sont trop vagues.

Ils peuvent être utilisés seulement dans un libellé explicite en français.

Exemples corrects :

```text
Synchroniser source vers Moodle local
Appliquer Médiathèque serveur
Exporter rapport Médiathèque
Mettre à jour Moodle serveur
```

## 18. Mots recommandés pour les boutons

Utiliser des verbes clairs :

```text
Vérifier
Ouvrir
Synchroniser
Simuler
Appliquer
Publier
Purger
Comparer
Restaurer
Créer une sauvegarde
```

Règle :

```text
Le bouton doit contenir l’action et la cible.
```

Exemples :

```text
Vérifier les chemins locaux
Ouvrir Moodle local
Synchroniser source vers Moodle local
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
Créer une sauvegarde serveur
```

## 19. Statuts officiels

Les statuts visibles officiels sont :

```text
Prêt
En cours
Réussi
Réussi avec avertissements
Échoué
Annulé
À vérifier dans le navigateur
```

### 19.1 Prêt

Définition :

```text
Prêt = l’action peut être lancée.
```

### 19.2 En cours

Définition :

```text
En cours = l’action est lancée et n’a pas encore fini.
```

### 19.3 Réussi

Définition :

```text
Réussi = l’action s’est terminée sans erreur connue.
```

### 19.4 Réussi avec avertissements

Définition :

```text
Réussi avec avertissements = l’action a fonctionné, mais il reste un point à vérifier.
```

### 19.5 Échoué

Définition :

```text
Échoué = l’action n’a pas réussi.
```

### 19.6 Annulé

Définition :

```text
Annulé = l’utilisateur a choisi de ne pas continuer, ou l’action a été arrêtée volontairement.
```

### 19.7 À vérifier dans le navigateur

Définition :

```text
À vérifier dans le navigateur = le test technique a réussi, mais l’affichage réel doit être confirmé dans Chrome, Edge ou Firefox.
```

## 20. Messages obligatoires pour actions sensibles

### 20.1 Action serveur

Message obligatoire ou équivalent très proche :

```text
Cette action modifie uckk.org ou sa base Moodle. Continuer ?
```

### 20.2 Action base Moodle

Message obligatoire ou équivalent très proche :

```text
Cette action écrit dans la base Moodle. Continuer ?
```

Si la cible est serveur :

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

### 20.3 Action récupération

Message obligatoire ou équivalent très proche :

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

### 20.4 Action Git

Message obligatoire ou équivalent très proche :

```text
Cette action enregistre ou envoie des changements dans l’historique Git.
Vérifie qu’aucun secret n’est inclus.
Continuer ?
```

## 21. Forme des messages d’erreur

Un message d’erreur doit avoir cette structure :

```text
L’action a échoué.
Cause probable : ...
Prochaine étape : ...
Détail technique : ...
```

Exemple :

```text
L’action a échoué.
Cause probable : la connexion SSH au serveur ne fonctionne pas.
Prochaine étape : lance “Tester connexion serveur”.
Détail technique : code de retour 255.
```

Ne pas afficher seulement :

```text
Exit code 255
```

## 22. Forme des messages de succès

Un message de succès doit indiquer ce qui a réussi.

Exemple :

```text
Réussi — 128 références Médiathèque trouvées sur serveur.
```

Si une vérification navigateur est nécessaire :

```text
Réussi — le service Médiathèque retourne 128 références.
À vérifier dans le navigateur : https://uckk.org/local/uckk/mediatheque.php
```

## 23. Forme des avertissements

Un avertissement doit expliquer le risque sans bloquer inutilement.

Exemple :

```text
Réussi avec avertissements — la page répond, mais les cartes sont chargées par AJAX.
Prochaine étape : vérifier la Médiathèque dans le navigateur.
```

## 24. Noms d’onglets officiels

Les noms d’onglets officiels sont :

```text
Accueil
Local
Git
Serveur
Médiathèque
Données Moodle
Tests
Historique
Récupération
```

Ne pas créer un autre nom d’onglet sans justification documentée.

## 25. Règle pour les rapports techniques

Les rapports peuvent contenir des noms techniques.

Mais chaque nom technique important doit être accompagné d’un nom lisible.

Exemple correct :

```text
Carte Médiathèque : uckkarchive_media
Référence externe principale : uckkarchive_external_work
Service Médiathèque : mod_uckkarchive_search_mediatheque
```

Exemple insuffisant :

```text
uckkarchive_media = 128
```

Meilleur exemple :

```text
Cartes Médiathèque (uckkarchive_media) : 128
```

## 26. Règle contre les synonymes improvisés

L’IA ne doit pas inventer de synonymes visibles.

Exemples de synonymes à éviter :

```text
Préflight
Pré-vérification
No-write
Push serveur
Production DB
Live site
Hotfix import
```

Utiliser les mots officiels :

```text
Vérifier
Simulation
Serveur
Base Moodle serveur
uckk.org
Récupération
```

## 27. Résumé obligatoire

Les mots les plus importants sont :

```text
Local = ordinateur de développement.
Serveur = ordinateur distant qui héberge uckk.org.
Vérifier = contrôler sans modifier.
Simulation = montrer ce qui serait fait sans modifier.
Appliquer = écrire réellement les changements.
Source = dossier du code officiel.
Runtime = dossier exécuté par Moodle.
Base Moodle = base de données active de Moodle.
Médiathèque = liste organisée de références.
Manifeste Médiathèque = fichier source des références.
Référence externe = lien vers un contenu sur un autre site.
Rapport = résumé lisible.
Log technique = journal détaillé.
Legacy = ancien outil.
Récupération = réparation d’un état cassé.
```

Règle finale :

```text
Si un mot technique n’est pas défini ici, il ne doit pas apparaître dans l’interface sans explication.
