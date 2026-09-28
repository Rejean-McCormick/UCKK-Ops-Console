# 08 — Contrat Médiathèque

## 1. Rôle de ce document

Ce document définit le contrat complet de la Médiathèque dans la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il sert à empêcher l’IA de recréer le désordre des anciens imports.

Il définit :

```text
ce qu’est la Médiathèque ;
quelle est la source de vérité ;
quel est le workflow normal ;
quelles actions sont autorisées ;
quelles actions sont interdites ;
comment écrire dans Moodle ;
comment vérifier localement et sur serveur ;
comment produire des rapports ;
comment classer les anciens scripts ;
comment éviter de retomber à 5 médias par erreur.
```

Ce document est un contrat de construction.

Il n’est pas une liste de tâches.

## 2. Décision principale

Le workflow normal de la Médiathèque est :

```text
manifeste → simulation → appliquer → vérifier
```

Cette règle est obligatoire.

Elle signifie :

```text
1. Les références sont éditées dans un fichier source clair.
2. L’application simule ce qui serait changé.
3. L’application applique seulement après validation.
4. L’application vérifie le résultat dans Moodle et dans le navigateur.
```

Règle :

```text
Aucun ajout normal à la Médiathèque ne doit exiger un wipe, un rebuild complet, un dump SQL ou une copie directe de tables.
```

## 3. Définition de la Médiathèque

Nom visible officiel :

```text
Médiathèque
```

Définition :

```text
Médiathèque = liste organisée de références publiques : vidéos, articles, sons, livres, pages web, dépôts de code et autres ressources.
```

La Médiathèque UCKK contient surtout des références externes.

Définition :

```text
Référence externe = lien vers un contenu qui reste sur un autre site.
```

Exemples :

```text
YouTube ;
SoundCloud ;
Spotify ;
Medium ;
GitHub ;
PhilPapers ;
Amazon ;
sites web publics.
```

Règle :

```text
Une référence externe ne doit pas être traitée comme un fichier média local à copier.
```

## 4. Ce que la Médiathèque n’est pas

La Médiathèque normale n’est pas :

```text
un dossier de fichiers média à importer ;
un dump SQL ;
une copie de tables ;
un export depuis la page publique ;
une réparation manuelle ;
une série de scripts datés ;
un import media_original ;
un vieux pipeline /play non contrôlé.
```

Définition :

```text
Pipeline = suite d’étapes automatisées qui transforment ou déplacent des données.
```

Si une action ressemble à une réparation ou un contournement, elle ne fait pas partie du workflow normal.

Elle appartient à :

```text
Récupération
```

ou :

```text
Legacy
```

## 5. Source de vérité

La source de vérité normale de la Médiathèque est :

```text
Manifeste Médiathèque
```

Définition :

```text
Source de vérité = endroit principal et fiable d’où part une donnée.
```

Définition :

```text
Manifeste Médiathèque = fichier source qui liste les références de la Médiathèque.
```

Chemin prévu :

```text
C:\mycode\UCKK\uckk-moodle\content\mediatheque\mediatheque.catalog.json
```

ou selon la configuration :

```text
mediatheque.manifestPath
```

Règle :

```text
La base Moodle reçoit les données de la Médiathèque, mais elle n’est pas l’endroit normal où l’on édite la Médiathèque.
```

Définition :

```text
Base Moodle = base de données utilisée par Moodle pour stocker son état actif.
```

Définition :

```text
Cible = endroit où une donnée est envoyée ou appliquée.
```

Donc :

```text
Manifeste = source de vérité.
Base Moodle = cible de publication.
```

## 6. Pourquoi le manifeste est obligatoire

Le manifeste est obligatoire parce qu’il évite les situations suivantes :

```text
une source partielle à 5 items est prise pour la source complète ;
un export public incomplet écrase un état correct ;
un ancien script importe le mauvais type de média ;
un rebuild complet est utilisé pour un simple ajout ;
local et serveur divergent sans explication ;
l’utilisateur ne sait plus quel outil est normal.
```

Définition :

```text
Diverger = devenir différent alors que deux environnements devraient représenter la même chose.
```

Règle :

```text
Un ajout normal doit être une modification du manifeste, pas une intervention directe dans la base Moodle.
```

## 7. Format conceptuel d’une entrée

Une entrée du manifeste doit représenter une référence Médiathèque.

Exemple conceptuel :

```json
{
  "slug": "titre-stable-du-document",
  "title": "Titre du document",
  "type": "external_article",
  "url": "https://example.org/document",
  "publisher": "example",
  "language": "fr",
  "summary": "Résumé court.",
  "tags": ["satire", "responsabilite"],
  "collections": ["mediatheque-centrale"]
}
```

Ce format peut évoluer, mais il doit toujours permettre :

```text
d’identifier l’entrée de manière stable ;
d’afficher un titre ;
de connaître le type de ressource ;
de connaître l’URL externe ;
de classer par tags ;
de rattacher à des collections ;
de publier dans Moodle de manière idempotente.
```

Définition :

```text
Idempotent = une action peut être relancée sans créer de doublons ou de dégâts.
```

## 8. Champs conceptuels du manifeste

### 8.1 `slug`

Définition :

```text
slug = identifiant texte stable et lisible.
```

Exemple :

```text
satire-responsabilite-theatre-public
```

Règle :

```text
Le slug ne doit pas changer sans raison.
```

Il sert à reconnaître la même référence dans le temps.

### 8.2 `title`

Définition :

```text
title = titre visible de la référence.
```

Dans l’interface et les rapports, utiliser le mot français :

```text
Titre
```

### 8.3 `type`

Définition :

```text
type = catégorie de ressource.
```

Exemples :

```text
external_video
external_article
external_audio
external_book
external_website
external_code
external_reference
```

Le type aide à choisir l’affichage et la correspondance Moodle.

### 8.4 `url`

Définition :

```text
url = adresse web de la référence externe.
```

Règle :

```text
Pour une référence externe, l’URL est obligatoire.
```

### 8.5 `publisher`

Définition :

```text
publisher = plateforme, éditeur ou site d’origine.
```

Exemples :

```text
YouTube
SoundCloud
Medium
GitHub
PhilPapers
```

### 8.6 `language`

Définition :

```text
language = langue principale de la ressource.
```

Exemples :

```text
fr
en
```

### 8.7 `summary`

Définition :

```text
summary = court résumé destiné à l’affichage ou à la recherche.
```

### 8.8 `tags`

Définition :

```text
tags = mots-clés associés à une référence.
```

Dans l’interface, afficher :

```text
Tags (mots-clés)
```

### 8.9 `collections`

Définition :

```text
collections = groupes organisés dans lesquels la référence doit apparaître.
```

Exemple :

```text
mediatheque-centrale
```

## 9. Validation du manifeste

Avant toute simulation ou application, le manifeste doit être validé.

Définition :

```text
Valider = vérifier qu’une donnée existe, a le bon format et peut être utilisée.
```

La validation doit vérifier au minimum :

```text
le fichier existe ;
le fichier est lisible ;
le JSON est valide ;
chaque entrée a un identifiant stable ;
chaque entrée a un titre ;
chaque référence externe a une URL ;
les URLs ne sont pas vides ;
les tags ont un format cohérent ;
les collections ont un format cohérent ;
il n’y a pas de doublons évidents ;
les champs obligatoires sont présents.
```

Définition :

```text
JSON = fichier texte structuré qui décrit des données.
```

## 10. Doublons

Un doublon est une référence présente plusieurs fois alors qu’elle représente la même ressource.

Définition :

```text
Doublon = deux entrées qui semblent représenter la même référence.
```

La validation doit signaler les doublons possibles selon :

```text
slug identique ;
URL identique ;
titre très proche avec URL identique ;
identifiant externe identique si disponible.
```

Règle :

```text
Les doublons doivent être signalés avant application.
```

Selon la gravité, ils peuvent bloquer ou produire un avertissement.

## 11. Workflow normal local

Le workflow normal local est :

```text
1. Ouvrir le manifeste Médiathèque.
2. Modifier ou ajouter une entrée.
3. Vérifier manifeste Médiathèque.
4. Simulation Médiathèque locale.
5. Lire le rapport de simulation.
6. Appliquer Médiathèque localement.
7. Vérifier Médiathèque locale.
8. Vérifier dans le navigateur local si nécessaire.
```

Règle :

```text
On ne doit pas appliquer localement si le manifeste est invalide.
```

## 12. Workflow normal serveur

Le workflow normal serveur est :

```text
1. S’assurer que le manifeste est validé et versionné.
2. Publier le code ou les données nécessaires sur serveur selon le workflow Local/Git/Serveur.
3. Simulation Médiathèque serveur.
4. Lire le rapport de simulation serveur.
5. Appliquer Médiathèque serveur.
6. Vérifier Médiathèque serveur.
7. Ouvrir la Médiathèque serveur dans le navigateur.
8. Lire le rapport final.
```

Définition :

```text
Versionné = enregistré dans Git.
```

Règle :

```text
On ne doit pas appliquer la Médiathèque serveur depuis une source locale non versionnée ou ambiguë.
```

## 13. Boutons officiels de l’onglet Médiathèque

Les boutons officiels sont :

```text
Ouvrir manifeste Médiathèque
Vérifier manifeste Médiathèque
Simulation Médiathèque locale
Appliquer Médiathèque localement
Vérifier Médiathèque locale
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
Vérifier Médiathèque serveur
Ouvrir Médiathèque locale
Ouvrir Médiathèque serveur
Ouvrir rapport Médiathèque
```

Aucun autre bouton Médiathèque normal ne doit être ajouté sans modification de ce document.

## 14. Actions interdites dans l’onglet Médiathèque

L’onglet Médiathèque normal ne doit pas contenir :

```text
wipe Médiathèque ;
rebuild complet ;
dump SQL brut ;
copie directe de tables ;
export depuis la page publique comme source de vérité ;
import media_original ;
ancien import /play non intégré ;
script daté de dépannage ;
restauration depuis sauvegarde ;
réparation automatique ;
suppression massive.
```

Ces actions appartiennent à :

```text
Récupération
```

ou :

```text
Legacy
```

Définition :

```text
Suppression massive = suppression de plusieurs données en une seule action.
```

## 15. Simulation Médiathèque

### 15.1 Définition

```text
Simulation Médiathèque = action qui lit le manifeste et indique ce qui serait écrit dans Moodle, sans modifier la base Moodle.
```

Équivalent technique :

```text
dry-run
```

Mais le mot visible principal doit être :

```text
Simulation
```

### 15.2 Simulation locale

Bouton :

```text
Simulation Médiathèque locale
```

Définition :

```text
Vérifie ce qui serait écrit dans la base Moodle locale, sans modifier les données.
```

### 15.3 Simulation serveur

Bouton :

```text
Simulation Médiathèque serveur
```

Définition :

```text
Vérifie ce qui serait écrit dans la base Moodle serveur, sans modifier les données.
```

### 15.4 Règle de fidélité

La simulation et l’application doivent utiliser la même source de vérité.

Règle :

```text
La simulation ne doit pas lire une source différente de l’action Appliquer.
```

Exemple interdit :

```text
Simulation depuis le manifeste, puis Apply depuis un export public.
```

Exemple correct :

```text
Simulation depuis le manifeste, puis Apply depuis le même manifeste.
```

## 16. Appliquer Médiathèque

### 16.1 Définition

```text
Appliquer Médiathèque = écrire réellement les références du manifeste dans Moodle.
```

### 16.2 Appliquer localement

Bouton :

```text
Appliquer Médiathèque localement
```

Confirmation obligatoire :

```text
Cette action écrit dans la base Moodle locale. Continuer ?
```

### 16.3 Appliquer serveur

Bouton :

```text
Appliquer Médiathèque serveur
```

Confirmation obligatoire :

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

### 16.4 Règle

Une action “Appliquer” doit produire un rapport.

Elle doit indiquer :

```text
éléments créés ;
éléments mis à jour ;
éléments inchangés ;
éléments ignorés ;
avertissements ;
erreurs ;
prochaine vérification.
```

## 17. Écriture dans Moodle

L’écriture normale dans Moodle doit créer ou mettre à jour les données nécessaires.

Tables techniques concernées :

```text
uckkarchive_external_work
uckkarchive_media
uckkarchive_media_source
uckkarchive_media_tag
uckkarchive_media_collection
uckkarchive_media_collection_item
```

Dans les rapports, afficher les noms lisibles avec les noms techniques.

Exemples :

```text
Références externes principales (uckkarchive_external_work)
Cartes Médiathèque (uckkarchive_media)
Sources des cartes (uckkarchive_media_source)
Tags / mots-clés (uckkarchive_media_tag)
Collections (uckkarchive_media_collection)
Liens collection-carte (uckkarchive_media_collection_item)
```

## 18. Rôle des tables Moodle

### 18.1 `uckkarchive_external_work`

Nom lisible :

```text
Référence externe principale
```

Rôle :

```text
Stocke la référence externe de base.
```

### 18.2 `uckkarchive_media`

Nom lisible :

```text
Carte Médiathèque
```

Rôle :

```text
Stocke l’entrée utilisée pour afficher une carte dans la Médiathèque.
```

### 18.3 `uckkarchive_media_source`

Nom lisible :

```text
Source de la carte
```

Rôle :

```text
Relie la carte à son URL ou à son origine externe.
```

### 18.4 `uckkarchive_media_tag`

Nom lisible :

```text
Tags (mots-clés)
```

Rôle :

```text
Stocke les mots-clés associés aux cartes.
```

### 18.5 `uckkarchive_media_collection`

Nom lisible :

```text
Collections
```

Rôle :

```text
Stocke les groupes organisés de références.
```

### 18.6 `uckkarchive_media_collection_item`

Nom lisible :

```text
Liens collection-carte
```

Rôle :

```text
Relie une collection à une carte Médiathèque.
```

## 19. Règle d’idempotence

L’application doit être idempotente.

Définition :

```text
Idempotent = une action peut être relancée sans créer de doublons ou de dégâts.
```

Pour être idempotente, l’application doit reconnaître les éléments existants par des identifiants stables.

Exemples d’identifiants stables :

```text
slug ;
URL ;
identifiant externe ;
UUID si déjà connu ;
combinaison archive + URL.
```

Définition :

```text
UUID = identifiant unique utilisé par un système pour reconnaître un objet.
```

Règle :

```text
Relancer “Appliquer Médiathèque” ne doit pas créer une deuxième copie de la même référence.
```

## 20. Règle de non-destruction par défaut

Par défaut, l’application ne doit pas supprimer des références.

Elle doit privilégier :

```text
créer ce qui manque ;
mettre à jour ce qui existe ;
laisser intact ce qui n’est pas concerné.
```

Les suppressions doivent être explicites et documentées.

Définition :

```text
Explicite = visible, annoncé et confirmé.
```

Règle :

```text
L’absence d’une entrée dans le manifeste ne doit pas automatiquement supprimer la référence Moodle, sauf mode spécial documenté.
```

Si un mode de suppression existe un jour, il doit être classé à haut risque et ne doit pas être le comportement par défaut.

## 21. Collections Médiathèque

Les collections doivent faire partie du workflow normal.

Définition :

```text
Collection = groupe organisé de références Médiathèque.
```

Le manifeste doit pouvoir indiquer les collections.

L’application doit pouvoir :

```text
créer les collections manquantes ;
mettre à jour les collections existantes ;
lier les cartes aux collections ;
maintenir l’ordre si un ordre est défini.
```

Définition :

```text
Ordre = position d’un élément dans une liste.
```

Règle :

```text
Les collections ne doivent pas être oubliées du workflow normal.
```

## 22. Tags Médiathèque

Définition :

```text
Tag = mot-clé associé à une référence.
```

Les tags doivent être synchronisés de manière contrôlée.

L’application doit pouvoir :

```text
créer les tags nécessaires ;
éviter les doublons ;
normaliser les tags ;
associer les tags aux cartes.
```

Définition :

```text
Normaliser = transformer une valeur en forme stable et cohérente.
```

Exemple :

```text
Responsabilité
responsabilite
responsabilité
```

doivent être traités selon une règle claire, pour éviter des tags incohérents.

## 23. Types de ressources

Le manifeste doit distinguer les types de ressources.

Types conceptuels possibles :

```text
external_video
external_audio
external_article
external_book
external_website
external_code
external_document
external_reference
```

L’application doit convertir ces types vers les champs Moodle nécessaires.

Définition :

```text
Convertir = transformer une valeur source en valeur attendue par la cible.
```

Règle :

```text
La conversion des types doit être centralisée, pas dispersée dans plusieurs scripts.
```

## 24. Vérifier Médiathèque

### 24.1 Vérification locale

Bouton :

```text
Vérifier Médiathèque locale
```

Cette action doit vérifier au minimum :

```text
la page locale répond ;
le service Médiathèque local répond ;
le nombre de références est cohérent ;
les premières cartes ont une URL externe si attendu ;
aucune erreur évidente n’est retournée.
```

### 24.2 Vérification serveur

Bouton :

```text
Vérifier Médiathèque serveur
```

Cette action doit vérifier au minimum :

```text
la page serveur répond ;
le service Médiathèque serveur répond ;
le nombre de références est cohérent ;
les premières cartes ont une URL externe si attendu ;
aucune erreur évidente n’est retournée.
```

### 24.3 Vérification navigateur

Après une application, la vérification navigateur est obligatoire.

Définition :

```text
Navigateur = application comme Chrome, Edge ou Firefox utilisée pour voir le site comme un utilisateur.
```

Règle :

```text
Une réponse HTTP 200 ne suffit pas toujours.
```

Définition :

```text
HTTP 200 = réponse technique indiquant qu’une page a répondu.
```

Pourquoi :

```text
La page peut répondre, mais les cartes Médiathèque peuvent être chargées ensuite par JavaScript ou AJAX.
```

Définition :

```text
JavaScript = langage utilisé dans le navigateur pour rendre une page interactive.
```

Définition :

```text
AJAX = méthode utilisée par une page web pour charger des données après l’ouverture de la page.
```

## 25. Service Médiathèque

Nom lisible :

```text
Service Médiathèque
```

Nom technique actuel :

```text
mod_uckkarchive_search_mediatheque
```

Définition :

```text
Service Médiathèque = fonction Moodle appelée par la page pour chercher les références à afficher.
```

Le nom technique peut apparaître dans les rapports, mais il doit être expliqué.

Exemple correct :

```text
Service Médiathèque : mod_uckkarchive_search_mediatheque
```

## 26. Cibles Moodle Médiathèque

L’application doit connaître les cibles locales et serveur par configuration.

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

Règle :

```text
Ces valeurs ne doivent pas être codées en dur dans le code.
Elles doivent venir de la configuration.
```

Deux modes de cible sont reconnus :

```text
Mode site-wide :
archiveId = 0
courseId = 0
cmId = 0
contextId = 0

Mode lié à une activité Moodle :
archiveId > 0
courseId > 0
cmId > 0
contextId > 0
```

Le mode **site-wide** représente une Médiathèque publique qui n'est pas liée artificiellement à l'activité `uckkarchive` d'un cours particulier. Il est valide pour l'action de **vérification** de la Médiathèque.

Le helper actuel de **simulation/application** reste orienté vers une cible liée à une activité Moodle explicite. Tant que ce pipeline n'est pas rendu pleinement *library-aware*, une cible site-wide `0/0/0/0` ne doit pas être utilisée pour écrire dans la base.

Une configuration mixte est invalide. Par exemple :

```text
archiveId = 0
courseId = 115
cmId = 332
contextId = 480
```

Il ne faut jamais copier les identifiants d'une archive de cours arbitraire uniquement pour faire passer le vérificateur.

État local validé le 28 septembre 2026 :

```text
localArchiveId = 0
localCourseId = 0
localCmId = 0
localContextId = 0
```

Cette configuration correspond au mode site-wide local.

## 27. Cible serveur temporaire connue

L’état serveur actuel peut utiliser une cible existante :

```text
serverArchiveId = 114
serverCourseId = 115
serverCmId = 332
serverContextId = 480
```

Cette cible doit être explicite dans la configuration.

Elle ne doit pas être cachée dans le code.

Règle :

```text
Si une vraie activité “Médiathèque centrale UCKK” est créée plus tard, la configuration doit être modifiée, pas le code central.
```

## 28. Rapports Médiathèque

Toute action Médiathèque importante doit produire un rapport.

Actions concernées :

```text
Vérifier manifeste Médiathèque ;
Simulation Médiathèque locale ;
Appliquer Médiathèque localement ;
Vérifier Médiathèque locale ;
Simulation Médiathèque serveur ;
Appliquer Médiathèque serveur ;
Vérifier Médiathèque serveur ;
toute erreur ;
tout avertissement.
```

## 29. Contenu obligatoire d’un rapport Médiathèque

Un rapport Médiathèque doit contenir :

```text
action ;
cible : locale ou serveur ;
mode : vérification, simulation ou application ;
source utilisée ;
chemin du manifeste ;
nombre d’entrées dans le manifeste ;
nombre d’éléments à créer ;
nombre d’éléments à mettre à jour ;
nombre d’éléments inchangés ;
nombre d’éléments ignorés ;
nombre d’avertissements ;
nombre d’erreurs ;
tables concernées ;
service vérifié ;
prochaine étape.
```

Définition :

```text
Mode = façon dont l’action a été lancée, par exemple vérification, simulation ou application.
```

## 30. Rapport de simulation

Un rapport de simulation doit dire clairement :

```text
Aucune donnée Moodle n’a été modifiée.
```

Il doit indiquer ce qui serait fait.

Exemple :

```text
Simulation Médiathèque serveur
Aucune donnée Moodle n’a été modifiée.
Résumé : 1 référence serait créée, 2 références seraient mises à jour, 125 seraient inchangées.
```

## 31. Rapport d’application

Un rapport d’application doit dire clairement :

```text
Des données Moodle ont été modifiées.
```

Il doit indiquer ce qui a été fait.

Exemple :

```text
Appliquer Médiathèque serveur
Des données Moodle ont été modifiées.
Résumé : 1 référence créée, 2 références mises à jour, 125 inchangées, 0 erreur.
Prochaine étape : vérifier la Médiathèque serveur dans le navigateur.
```

## 32. Gestion des erreurs Médiathèque

Une erreur Médiathèque doit suivre le format :

```text
L’action a échoué.
Cause probable : ...
Prochaine étape : ...
Détail technique : ...
```

Exemple :

```text
L’action a échoué.
Cause probable : le manifeste Médiathèque contient une URL vide.
Prochaine étape : corriger le manifeste, puis relancer “Vérifier manifeste Médiathèque”.
Détail technique : entrée slug = ...
```

## 33. Avertissements Médiathèque

Un avertissement ne bloque pas toujours l’action.

Exemples d’avertissements :

```text
tag inconnu ;
collection absente qui serait créée ;
résumé manquant ;
type de ressource non reconnu, converti en external_reference ;
page répond mais cartes à vérifier dans le navigateur.
```

Règle :

```text
Un avertissement doit être visible dans le rapport.
```

## 34. Conditions de refus

L’application doit refuser de continuer si :

```text
le manifeste est introuvable ;
le manifeste n’est pas un JSON valide ;
la cible local/serveur est ambiguë ;
le service Médiathèque est absent de la configuration ;
une action serveur n’a pas de confirmation ;
une action d’application n’a pas de cible claire ;
une simulation obligatoire n’a pas été faite ;
une action tente d’utiliser un export public comme source normale ;
une action tente d’utiliser media_original comme source normale.
```

Message recommandé :

```text
Action refusée.
Cause : condition Médiathèque manquante ou dangereuse.
Prochaine étape : ...
```

## 35. Interdiction de l’export public comme source normale

La page publique ou le service public peuvent servir à vérifier.

Ils ne doivent pas servir de source de vérité normale.

Règle :

```text
Le service public vérifie ce qui est publié.
Il ne définit pas ce qui doit être publié.
```

Exemple interdit :

```text
Exporter depuis la page publique locale, puis reconstruire le serveur avec cet export.
```

Raison :

```text
Si la page publique locale ne voit que 5 items, cet export devient une source partielle dangereuse.
```

## 36. Interdiction de `media_original` comme workflow normal

Le workflow Médiathèque actuel concerne surtout des références externes.

Règle :

```text
Ne pas utiliser un import media_original pour publier les références externes de la Médiathèque.
```

Définition :

```text
media_original = logique d’import de fichiers médias locaux, pas de références externes.
```

Un fichier média local est différent d’une référence externe.

Définition :

```text
Fichier média local = fichier réellement stocké sur l’ordinateur ou dans Moodle.
```

## 37. Interdiction du dump SQL brut

Un dump SQL brut ne doit pas être un workflow normal Médiathèque.

Définition :

```text
Dump SQL = copie brute d’une base de données ou d’une partie de base de données.
```

Règle :

```text
La Médiathèque normale ne se synchronise pas par dump SQL.
```

Un dump SQL peut exister comme sauvegarde ou récupération, mais pas comme méthode d’ajout quotidien.

## 38. Interdiction de la copie directe de tables

La copie directe de tables ne doit pas être un workflow normal.

Définition :

```text
Copie directe de tables = transfert manuel de tables de base de données d’un environnement à un autre.
```

Raison :

```text
Les identifiants Moodle, contextes, cours et modules peuvent être différents entre local et serveur.
```

Définition :

```text
Identifiant Moodle = nombre interne utilisé par Moodle pour reconnaître un objet.
```

Règle :

```text
La synchronisation doit passer par une logique contrôlée, pas par une copie brute.
```

## 39. Classification des anciens outils Médiathèque

Les anciens outils doivent être classés.

Classes possibles :

```text
normal ;
legacy ;
recovery ;
test.
```

Définitions :

```text
Normal = utilisé dans le workflow quotidien.

Legacy = ancien outil conservé pour référence.

Recovery = outil de réparation.

Test = outil utilisé pour vérifier une hypothèse technique.
```

Règle :

```text
Un outil non classé ne doit pas être appelé par l’interface Médiathèque.
```

## 40. Outil normal attendu

Le workflow normal doit avoir un seul point d’entrée technique.

Nom conceptuel :

```text
Sync-UckkMediatheque
```

Rôle :

```text
Lire le manifeste, simuler, appliquer et produire des rapports.
```

Il peut être composé de plusieurs fichiers internes, mais l’interface doit présenter un chemin simple.

Règle :

```text
L’utilisateur ne doit pas choisir entre plusieurs importeurs Médiathèque.
```

## 41. Legacy Médiathèque

Les anciens imports liés à `/play`, `final-working`, `sourceitemid0` ou `v9` ne doivent pas être utilisés comme boutons normaux.

Ils peuvent être conservés dans :

```text
legacy
```

s’ils servent de référence.

Règle :

```text
Un outil legacy peut inspirer le nouveau code, mais ne doit pas être lancé comme workflow normal.
```

## 42. Recovery Médiathèque

Les actions suivantes sont recovery :

```text
rebuild depuis external_work ;
wipe/reimport ;
restauration depuis sauvegarde ;
reconstruction des collections après incident ;
comparaison profonde local/serveur ;
réparation de tables.
```

Ces actions doivent être dans :

```text
Récupération
```

Elles doivent demander confirmation forte.

Elles doivent exiger ou créer une sauvegarde si elles modifient des données.

## 43. Test Médiathèque

Les tests techniques Médiathèque peuvent exister.

Mais ils ne doivent pas être présentés comme workflow normal.

Exemples :

```text
test d’écriture DB ;
test de schéma ;
test AJAX brut ;
test d’un mapping spécifique.
```

Définition :

```text
Mapping = correspondance entre une donnée source et une donnée cible.
```

## 44. Sécurité locale / serveur

Les actions locales et serveur doivent être séparées.

Boutons corrects :

```text
Simulation Médiathèque locale
Appliquer Médiathèque localement
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
```

Boutons interdits :

```text
Appliquer Médiathèque
Sync Médiathèque
Import Médiathèque
Fix Médiathèque
```

Raison :

```text
Ces libellés ne disent pas la cible ni le niveau de danger.
```

## 45. Confirmations obligatoires

### 45.1 Application locale

Message :

```text
Cette action écrit dans la base Moodle locale. Continuer ?
```

### 45.2 Application serveur

Message :

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

### 45.3 Récupération Médiathèque

Message :

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données Médiathèque.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

### 45.4 Suppression ou reconstruction

Message :

```text
Cette action peut supprimer, remplacer ou reconstruire des données Médiathèque existantes.
Elle ne doit être lancée que si une sauvegarde existe.
Continuer ?
```

## 46. Sauvegardes

Une sauvegarde est obligatoire avant toute action Médiathèque destructive.

Définition :

```text
Destructive = qui peut supprimer, remplacer ou reconstruire des données existantes.
```

Actions qui exigent une sauvegarde :

```text
wipe ;
rebuild complet ;
restauration ;
copie directe de tables ;
suppression massive ;
reconstruction de plusieurs tables ;
récupération destructive.
```

Le workflow normal d’ajout ou de mise à jour ne doit pas être destructif par défaut.

## 47. Relation avec Git

Le manifeste Médiathèque doit être versionné dans Git.

Définition :

```text
Versionné dans Git = enregistré dans l’historique du projet.
```

Règle :

```text
Une modification Médiathèque destinée au serveur doit être enregistrée dans Git avant publication serveur.
```

Workflow :

```text
modifier manifeste ;
valider localement ;
commit Git ;
push Git ;
publier serveur ;
appliquer serveur.
```

## 48. Relation avec le workflow serveur

L’application ne doit pas appliquer la Médiathèque serveur si le serveur n’a pas accès à la bonne version du manifeste.

Règle :

```text
Appliquer Médiathèque serveur doit utiliser le manifeste attendu côté serveur ou un transfert explicitement contrôlé.
```

Ce point doit être visible dans le rapport.

Exemple :

```text
Source utilisée : manifeste serveur /opt/uckk/uckk-moodle/content/mediatheque/mediatheque.catalog.json
```

ou :

```text
Source utilisée : manifeste local transféré explicitement pour cette opération.
```

La première option est préférable pour un workflow stable.

## 49. Vérification du nombre de références

Les rapports doivent afficher le nombre de références.

Exemple :

```text
Entrées dans le manifeste : 128
Cartes Médiathèque serveur : 128
Service Médiathèque : 128 résultats
```

Règle :

```text
Si le nombre tombe brusquement de 128 à 5, l’application doit afficher un avertissement fort ou refuser l’application selon le contexte.
```

Définition :

```text
Avertissement fort = message très visible qui signale un risque important sans forcément être une erreur technique.
```

## 50. Protection contre les sources partielles

Une source partielle est une source qui ne contient qu’une partie des références attendues.

Définition :

```text
Source partielle = source incomplète qui peut écraser ou réduire un état correct.
```

Exemple :

```text
un export public local qui ne contient que 5 références.
```

Règle :

```text
L’application ne doit pas utiliser une source partielle comme source normale.
```

Si une source contient beaucoup moins d’entrées que l’état actuel, l’application doit signaler un risque.

Exemple de message :

```text
Avertissement fort — la source contient 5 références alors que la cible en contient 128.
Action refusée sauf mode récupération explicitement confirmé.
```

## 51. Règle sur les suppressions futures

Si un jour l’application permet de supprimer une référence via le manifeste, cela doit être un mode explicite.

Nom possible :

```text
Archiver les références absentes du manifeste
```

ou :

```text
Désactiver les références absentes du manifeste
```

Ne pas supprimer physiquement par défaut.

Définition :

```text
Archiver = rendre une entrée inactive ou cachée sans la supprimer définitivement.
```

Règle :

```text
L’absence dans le manifeste ne signifie pas suppression automatique.
```

## 52. Messages de succès

Exemple pour simulation :

```text
Réussi — simulation terminée.
Aucune donnée Moodle n’a été modifiée.
Résumé : 1 référence serait créée, 2 seraient mises à jour, 125 inchangées.
```

Exemple pour application :

```text
Réussi — Médiathèque serveur appliquée.
Résumé : 1 référence créée, 2 mises à jour, 125 inchangées, 0 erreur.
Prochaine étape : vérifier la Médiathèque serveur dans le navigateur.
```

Exemple pour vérification :

```text
Réussi — le service Médiathèque serveur retourne 128 références.
À vérifier dans le navigateur : https://uckk.org/local/uckk/mediatheque.php
```

## 53. Messages d’erreur

Format obligatoire :

```text
L’action a échoué.
Cause probable : ...
Prochaine étape : ...
Détail technique : ...
```

Exemple :

```text
L’action a échoué.
Cause probable : le service Médiathèque serveur ne répond pas.
Prochaine étape : vérifier uckk.org et lire le rapport serveur.
Détail technique : service = mod_uckkarchive_search_mediatheque.
```

## 54. Règle anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
créer un deuxième workflow Médiathèque normal ;
lancer un ancien script import comme action normale ;
utiliser un export public comme source de vérité ;
réintroduire media_original pour les références externes ;
écrire dans la base Moodle serveur sans confirmation ;
appliquer sans simulation quand la simulation est obligatoire ;
supprimer des références par défaut ;
ignorer les collections ;
ignorer les tags ;
mélanger local et serveur ;
coder archiveId/courseId/cmId/contextId en dur ;
afficher seulement des noms de tables sans explication lisible ;
traiter une chute 128 → 5 comme normale.
```

Si l’IA estime qu’une nouvelle action Médiathèque est nécessaire, elle doit proposer une modification de ce document avant de coder.

## 55. Résumé obligatoire

Règle centrale :

```text
manifeste → simulation → appliquer → vérifier
```

Source de vérité :

```text
Manifeste Médiathèque
```

Cibles :

```text
base Moodle locale ;
base Moodle serveur.
```

Actions normales :

```text
Ouvrir manifeste Médiathèque
Vérifier manifeste Médiathèque
Simulation Médiathèque locale
Appliquer Médiathèque localement
Vérifier Médiathèque locale
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
Vérifier Médiathèque serveur
Ouvrir Médiathèque locale
Ouvrir Médiathèque serveur
Ouvrir rapport Médiathèque
```

Interdits dans le workflow normal :

```text
wipe ;
rebuild complet ;
dump SQL brut ;
copie directe de tables ;
export public comme source ;
media_original ;
anciens scripts datés ;
recovery ;
legacy.
```

Règle finale :

```text
Ajouter un document à la Médiathèque doit prendre quelques minutes.
Si l’utilisateur doit faire une récupération pour un ajout normal, le design est mauvais.
