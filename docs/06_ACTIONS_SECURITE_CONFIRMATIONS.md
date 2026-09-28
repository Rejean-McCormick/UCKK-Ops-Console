# 06 — Actions, sécurité et confirmations

## 1. Rôle de ce document

Ce document définit les règles de sécurité de la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il explique :

```text
comment classer les actions ;
quelles actions sont dangereuses ;
quelles confirmations sont obligatoires ;
quelles actions doivent produire un rapport ;
quelles actions doivent exiger une sauvegarde ;
quand l’application doit refuser de continuer ;
comment expliquer le danger à l’utilisateur.
```

Ce document sert à empêcher l’IA de coder des boutons dangereux sans protection.

Définition :

```text
Action = opération lancée par l’utilisateur ou par l’application.
```

Définition :

```text
Confirmation = message qui demande à l’utilisateur de valider avant de continuer.
```

Définition :

```text
Sécurité = ensemble des règles qui empêchent les erreurs, pertes de données ou modifications non voulues.
```

## 2. Principe central

Toute action doit être classée selon son niveau de danger.

Règle :

```text
Une action ne doit pas être codée avant que son niveau de danger soit clair.
```

Une action doit répondre à ces questions :

```text
Est-ce que l’action lit seulement ?
Est-ce que l’action modifie le local ?
Est-ce que l’action modifie Git ?
Est-ce que l’action modifie le serveur ?
Est-ce que l’action écrit dans la base Moodle ?
Est-ce que l’action supprime ou reconstruit des données ?
Est-ce que l’action est une récupération ?
Est-ce qu’une sauvegarde est nécessaire ?
Est-ce qu’un rapport est nécessaire ?
```

Si l’IA ne peut pas répondre clairement, l’action ne doit pas être codée comme action normale.

## 3. Niveaux de danger officiels

Les niveaux de danger officiels sont :

```text
Niveau 0 — Navigation
Niveau 1 — Lecture / vérification
Niveau 2 — Modification locale simple
Niveau 3 — Git
Niveau 4 — Base Moodle locale
Niveau 5 — Serveur public
Niveau 6 — Base Moodle serveur
Niveau 7 — Récupération
```

Aucun autre niveau ne doit être ajouté sans modification documentée.

## 4. Niveau 0 — Navigation

### 4.1 Définition

```text
Navigation = action qui ouvre un écran, un dossier, une page ou un rapport sans rien modifier.
```

### 4.2 Exemples

```text
Ouvrir Moodle local
Ouvrir uckk.org
Ouvrir la Médiathèque
Ouvrir le dernier rapport
Ouvrir dossier logs
Ouvrir documentation
```

### 4.3 Confirmation

Aucune confirmation requise.

### 4.4 Rapport

Rapport non obligatoire.

### 4.5 Règle

Une action de navigation ne doit jamais modifier de données.

Si une action modifie quelque chose, elle n’est pas une navigation.

## 5. Niveau 1 — Lecture / vérification

### 5.1 Définition

```text
Lecture / vérification = action qui contrôle un état sans modifier les données.
```

### 5.2 Exemples

```text
Vérifier l’état local
Vérifier Git
Vérifier uckk.org
Tester pages locales
Tester Médiathèque serveur
Vérifier manifeste Médiathèque
Vérifier fichiers JSON Moodle
```

### 5.3 Confirmation

Aucune confirmation requise.

### 5.4 Rapport

Rapport recommandé si l’action peut aider au diagnostic.

Rapport obligatoire si l’action échoue ou produit un avertissement.

### 5.5 Règle

Une vérification ne doit pas écrire dans :

```text
un fichier ;
Git ;
la base Moodle ;
le serveur ;
la Médiathèque ;
les dossiers de runtime.
```

Elle peut écrire un rapport ou un log, car cela ne modifie pas le système contrôlé.

## 6. Niveau 2 — Modification locale simple

### 6.1 Définition

```text
Modification locale simple = action qui modifie seulement l’ordinateur de développement et ne touche pas la base Moodle.
```

### 6.2 Exemples

```text
Synchroniser source vers Moodle local
Créer un dossier reports
Créer un dossier logs
Nettoyer un fichier temporaire local généré par l’application
```

### 6.3 Confirmation

Confirmation forte non obligatoire.

Mais l’interface doit dire clairement :

```text
Cette action modifie seulement le local.
```

### 6.4 Rapport

Rapport obligatoire pour les actions de synchronisation.

Rapport recommandé pour les autres modifications locales.

### 6.5 Règle

Une modification locale simple ne doit pas toucher :

```text
le serveur ;
la base Moodle serveur ;
Git ;
les données de production ;
les outils recovery.
```

Définition :

```text
Production = environnement public ou réel utilisé par le site uckk.org.
```

## 7. Niveau 3 — Git

### 7.1 Définition

```text
Action Git = action qui modifie ou transmet l’historique du projet.
```

### 7.2 Exemples

```text
Créer un commit Git
Envoyer les changements vers Git
Récupérer depuis Git si cela modifie le dossier source
Changer de branche Git
Annuler des changements Git
```

### 7.3 Confirmation obligatoire

Les actions Git qui modifient l’état doivent demander confirmation.

Message obligatoire ou équivalent très proche :

```text
Cette action enregistre ou envoie des changements dans l’historique Git.
Vérifie qu’aucun secret n’est inclus.
Continuer ?
```

Pour une action qui récupère depuis Git :

```text
Cette action peut modifier les fichiers locaux en récupérant des changements depuis Git.
Continuer ?
```

### 7.4 Rapport

Rapport obligatoire pour :

```text
commit ;
push ;
pull qui modifie des fichiers ;
annulation de changements.
```

### 7.5 Règle

Avant une action Git d’écriture, l’application doit encourager la vérification des fichiers sensibles.

Définition :

```text
Fichier sensible = fichier qui peut contenir un secret ou une configuration privée.
```

Secrets interdits :

```text
mots de passe ;
clés SSH privées ;
tokens ;
config.php serveur ;
dumps SQL ;
secrets Moodle ;
secrets de base de données.
```

## 8. Niveau 4 — Base Moodle locale

### 8.1 Définition

```text
Base Moodle locale = base de données utilisée par le Moodle local.
```

Une action de niveau 4 écrit dans cette base.

### 8.2 Exemples

```text
Appliquer Médiathèque localement
Appliquer catégories Moodle localement
Appliquer cours Moodle localement
Appliquer programmes localement
Appliquer parcours localement
```

### 8.3 Confirmation obligatoire

Message obligatoire ou équivalent très proche :

```text
Cette action écrit dans la base Moodle locale. Continuer ?
```

### 8.4 Simulation préalable

Une simulation doit exister quand l’action est complexe.

Exemples où la simulation est obligatoire :

```text
Médiathèque ;
Données Moodle ;
plusieurs créations ou mises à jour ;
modification de collections ;
modification de plusieurs tables.
```

Définition :

```text
Simulation = action qui montre ce qui serait fait, sans modifier les données.
```

### 8.5 Rapport

Rapport obligatoire.

Le rapport doit indiquer :

```text
nombre d’éléments créés ;
nombre d’éléments mis à jour ;
nombre d’éléments ignorés ;
nombre d’avertissements ;
nombre d’erreurs ;
prochaine vérification.
```

### 8.6 Règle

Une action sur la base Moodle locale ne doit jamais toucher la base Moodle serveur.

Le texte visible doit contenir le mot :

```text
locale
```

ou :

```text
localement
```

## 9. Niveau 5 — Serveur public

### 9.1 Définition

```text
Serveur public = machine qui héberge le vrai site accessible par les visiteurs.
```

Dans ce projet :

```text
uckk.org
```

Une action de niveau 5 modifie le serveur, mais pas nécessairement la base Moodle serveur.

### 9.2 Exemples

```text
Récupérer dernier code sur serveur
Synchroniser source serveur vers Moodle serveur
Purger les caches serveur
Recharger PHP-FPM
Mettre à jour les fichiers exécutés par uckk.org
```

### 9.3 Confirmation obligatoire

Message obligatoire ou équivalent très proche :

```text
Cette action modifie uckk.org ou son code serveur. Continuer ?
```

Si l’action peut aussi toucher la base Moodle, utiliser plutôt le message de niveau 6.

### 9.4 Rapport

Rapport obligatoire.

### 9.5 Vérification après action

Après une action serveur, l’application doit proposer :

```text
Vérifier uckk.org
```

ou :

```text
Ouvrir uckk.org dans le navigateur
```

### 9.6 Règle

Une action serveur ne doit jamais être cachée derrière un bouton vague.

Exemple interdit :

```text
Sync
```

Exemple correct :

```text
Synchroniser source serveur vers Moodle serveur
```

## 10. Niveau 6 — Base Moodle serveur

### 10.1 Définition

```text
Base Moodle serveur = base de données utilisée par Moodle sur uckk.org.
```

Une action de niveau 6 écrit dans cette base.

C’est un niveau très sensible.

### 10.2 Exemples

```text
Appliquer Médiathèque serveur
Appliquer catégories Moodle serveur
Appliquer cours Moodle serveur
Appliquer programmes serveur
Appliquer parcours serveur
Mettre à jour Moodle serveur si cela applique des changements de base
```

### 10.3 Confirmation obligatoire

Message obligatoire ou équivalent très proche :

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

Si l’action modifie aussi le site public, le message peut être :

```text
Cette action modifie uckk.org et écrit dans la base Moodle serveur. Continuer ?
```

### 10.4 Simulation préalable obligatoire

Toute action normale de niveau 6 doit avoir une simulation préalable, sauf exception documentée.

Exemples :

```text
Simulation Médiathèque serveur avant Appliquer Médiathèque serveur.
Simulation catégories serveur avant Appliquer catégories serveur.
```

### 10.5 Rapport obligatoire

Le rapport doit indiquer clairement :

```text
cible : serveur ;
base touchée : base Moodle serveur ;
mode : simulation ou application ;
changements effectués ;
avertissements ;
erreurs ;
prochaine vérification.
```

### 10.6 Vérification navigateur

Après une action de niveau 6, l’application doit proposer une vérification dans le navigateur si l’action affecte une page visible.

Exemple :

```text
À vérifier dans le navigateur : https://uckk.org/local/uckk/mediatheque.php
```

### 10.7 Règle

Une action de niveau 6 ne doit jamais être dans l’Accueil si elle exige des choix complexes.

Elle doit être dans l’onglet spécialisé correspondant.

## 11. Niveau 7 — Récupération

### 11.1 Définition

```text
Récupération = action spéciale utilisée quand l’état normal est cassé.
```

Une action recovery peut réparer, mais aussi aggraver un problème si elle est mal utilisée.

### 11.2 Exemples

```text
Wipe ;
rebuild complet ;
restauration depuis sauvegarde ;
copie directe de tables ;
reconstruction de liens media/media_source ;
reconstruction de collections ;
réparation de compteurs ;
import depuis une sauvegarde.
```

Définitions :

```text
Wipe = suppression volontaire d’un ensemble de données avant reconstruction.

Rebuild = reconstruction complète d’un état à partir d’une autre source.

Copie directe de tables = transfert manuel de tables de base de données.

Sauvegarde = copie conservée avant une action risquée pour pouvoir revenir en arrière.
```

### 11.3 Emplacement obligatoire

Les actions de récupération doivent être dans l’onglet :

```text
Récupération
```

Elles ne doivent pas apparaître dans :

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

### 11.4 Confirmation forte obligatoire

Message obligatoire ou équivalent très proche :

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

### 11.5 Sauvegarde obligatoire

Si l’action de récupération modifie des données, elle doit exiger une sauvegarde.

Règle :

```text
Pas de sauvegarde vérifiée = pas de récupération destructive.
```

Définition :

```text
Destructive = qui peut supprimer, remplacer ou reconstruire des données existantes.
```

### 11.6 Rapport obligatoire

Toute action de récupération doit produire un rapport.

Le rapport doit indiquer :

```text
pourquoi l’action a été lancée ;
quelle sauvegarde a été utilisée ou créée ;
quelles données ont été lues ;
quelles données ont été modifiées ;
quelles données ont été supprimées, si applicable ;
comment vérifier le résultat ;
comment revenir en arrière si possible.
```

### 11.7 Règle

Une action recovery ne doit jamais devenir un workflow normal.

Si l’utilisateur doit utiliser recovery chaque fois qu’il ajoute une référence Médiathèque, le design est mauvais.

## 12. Actions de lecture, écriture et destruction

Toute action doit être classée aussi selon son effet :

```text
lecture ;
écriture ;
destruction.
```

### 12.1 Lecture

Définition :

```text
Lecture = action qui consulte un état sans le modifier.
```

Exemples :

```text
vérifier ;
tester ;
ouvrir ;
comparer sans écrire.
```

### 12.2 Écriture

Définition :

```text
Écriture = action qui crée ou modifie un fichier, une base, Git ou un serveur.
```

Exemples :

```text
appliquer ;
synchroniser ;
créer un commit ;
purger des caches ;
mettre à jour Moodle.
```

### 12.3 Destruction

Définition :

```text
Destruction = action qui supprime, remplace ou reconstruit des données existantes.
```

Exemples :

```text
wipe ;
rebuild ;
restaurer sur un état existant ;
supprimer des références ;
remplacer des collections ;
copier des tables par-dessus d’autres tables.
```

Règle :

```text
Toute destruction est recovery par défaut.
```

## 13. Matrice officielle de sécurité

| Niveau | Nom | Modifie des données ? | Confirmation | Simulation | Rapport | Onglet normal |
|---|---|---:|---|---|---|---|
| 0 | Navigation | Non | Non | Non | Non | Oui |
| 1 | Lecture / vérification | Non | Non | Non | Si erreur ou avertissement | Oui |
| 2 | Modification locale simple | Oui, local | Message visible | Parfois | Oui si sync | Oui |
| 3 | Git | Oui | Oui | Non | Oui | Oui, onglet Git |
| 4 | Base Moodle locale | Oui | Oui | Oui si complexe | Oui | Oui, onglet spécialisé |
| 5 | Serveur public | Oui | Oui | Selon action | Oui | Oui, onglet Serveur |
| 6 | Base Moodle serveur | Oui | Oui | Oui | Oui | Oui, onglet spécialisé |
| 7 | Récupération | Oui / destructif | Forte | Si possible | Oui | Seulement Récupération |

## 14. Confirmations officielles

### 14.1 Serveur public

```text
Cette action modifie uckk.org ou son code serveur. Continuer ?
```

### 14.2 Base Moodle locale

```text
Cette action écrit dans la base Moodle locale. Continuer ?
```

### 14.3 Base Moodle serveur

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

### 14.4 Serveur + base Moodle serveur

```text
Cette action modifie uckk.org et écrit dans la base Moodle serveur. Continuer ?
```

### 14.5 Git

```text
Cette action enregistre ou envoie des changements dans l’historique Git.
Vérifie qu’aucun secret n’est inclus.
Continuer ?
```

### 14.6 Récupération

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

### 14.7 Suppression ou reconstruction

```text
Cette action peut supprimer, remplacer ou reconstruire des données existantes.
Elle ne doit être lancée que si une sauvegarde existe.
Continuer ?
```

## 15. Interdictions générales

L’application ne doit jamais :

```text
modifier le serveur sans confirmation ;
écrire dans la base Moodle serveur sans confirmation ;
lancer une récupération sans confirmation forte ;
faire un wipe sans sauvegarde ;
faire un rebuild silencieux ;
faire un dump SQL brut comme workflow normal ;
copier directement des tables comme workflow normal ;
cacher une action dangereuse derrière un bouton vague ;
présenter un outil legacy comme outil normal ;
afficher un faux succès si une étape critique échoue.
```

Définition :

```text
Faux succès = message qui annonce une réussite alors qu’une étape nécessaire a échoué ou n’a pas été vérifiée.
```

## 16. Actions interdites dans l’Accueil

L’Accueil ne doit jamais contenir :

```text
wipe ;
rebuild ;
dump SQL ;
copie directe de tables ;
restauration de sauvegarde ;
import brut ;
outil legacy ;
outil recovery ;
suppression de données ;
écriture directe dans la base Moodle serveur.
```

Règle :

```text
Une action dangereuse ne devient pas sûre parce qu’elle est placée dans l’Accueil.
Elle devient seulement plus dangereuse.
```

## 17. Règle sur les boutons vagues

Les boutons suivants sont interdits seuls :

```text
Run
Go
Sync
Apply
Fix
Repair
Reset
Import
Export
Deploy
Clean
```

Ils ne disent pas :

```text
ce qui est fait ;
sur quelle cible ;
avec quel niveau de danger.
```

Exemples corrects :

```text
Synchroniser source vers Moodle local
Appliquer Médiathèque serveur
Créer sauvegarde avant récupération
Vérifier uckk.org
```

## 18. Règle sur les simulations

Une simulation doit être fidèle à l’action qu’elle précède.

Exemple :

```text
Simulation Médiathèque serveur
```

doit vérifier ce que fera :

```text
Appliquer Médiathèque serveur
```

Elle ne doit pas lire une source différente.

Règle :

```text
La simulation et l’application doivent utiliser la même source de vérité.
```

Définition :

```text
Source de vérité = endroit principal et fiable d’où part une donnée.
```

Pour la Médiathèque normale :

```text
la source de vérité est le manifeste Médiathèque.
```

## 19. Règle sur les rapports de sécurité

Les rapports des actions sensibles doivent indiquer le niveau de danger.

Exemple :

```text
Niveau de danger : 6 — Base Moodle serveur
Confirmation utilisateur : oui
Simulation préalable : oui
Rapport : oui
```

Pour recovery :

```text
Niveau de danger : 7 — Récupération
Sauvegarde vérifiée : oui
Confirmation forte : oui
```

## 20. Règle sur l’annulation

Si l’utilisateur refuse une confirmation, le résultat doit être :

```text
Annulé
```

Message recommandé :

```text
Annulé — aucune modification n’a été faite.
```

L’application ne doit pas traiter un refus comme une erreur.

Définition :

```text
Annulé = l’utilisateur a choisi de ne pas continuer, ou l’action a été arrêtée volontairement.
```

## 21. Règle sur les échecs partiels

Une action peut réussir partiellement.

Définition :

```text
Échec partiel = une partie de l’action a réussi, mais une autre partie a échoué.
```

L’application ne doit pas afficher seulement :

```text
Réussi
```

si une étape importante a échoué.

Statut recommandé :

```text
Réussi avec avertissements
```

ou :

```text
Échoué
```

selon la gravité.

Exemple :

```text
Réussi avec avertissements — la page répond, mais les cartes Médiathèque doivent être vérifiées dans le navigateur.
```

## 22. Règle sur les actions en chaîne

Une action en chaîne lance plusieurs sous-actions.

Définition :

```text
Action en chaîne = bouton qui exécute plusieurs étapes dans un ordre prévu.
```

Exemple :

```text
Publier sur serveur
```

peut contenir :

```text
récupérer dernier code ;
synchroniser source serveur vers Moodle serveur ;
purger les caches serveur ;
vérifier uckk.org.
```

Règle :

```text
Une action en chaîne doit annoncer ses grandes étapes avant de commencer.
```

Elle doit produire un rapport indiquant quelles étapes ont réussi ou échoué.

## 23. Règle sur les sauvegardes

Une sauvegarde est obligatoire avant toute action destructive.

Définition :

```text
Sauvegarde = copie conservée avant une action risquée pour pouvoir revenir en arrière.
```

Actions qui exigent une sauvegarde :

```text
wipe ;
rebuild ;
restauration ;
copie directe de tables ;
suppression massive ;
reconstruction de plusieurs tables ;
récupération destructive.
```

Règle :

```text
L’application doit connaître ou créer la sauvegarde avant de continuer.
```

Un simple message “faites une sauvegarde” ne suffit pas pour une action destructive.

## 24. Règle sur la Médiathèque

Le workflow normal de la Médiathèque est :

```text
manifeste → simulation → appliquer → vérifier
```

Sont interdits comme workflow normal :

```text
export depuis la page publique ;
dump SQL brut ;
copie directe de tables ;
import media_original ;
wipe ;
rebuild complet ;
ancien script /play non intégré ;
outil daté de dépannage.
```

Ces actions sont legacy ou recovery.

Elles ne doivent pas apparaître dans l’onglet Médiathèque normal.

## 25. Règle sur les données Moodle

Les données Moodle doivent respecter :

```text
fichier source → simulation → appliquer → vérifier
```

Modifier un fichier JSON ne modifie pas automatiquement Moodle.

Définition :

```text
Fichier JSON = fichier texte structuré qui décrit des données.
```

Définition :

```text
Appliquer = écrire réellement les changements dans Moodle.
```

Toute action “Appliquer” sur serveur est niveau 6 si elle écrit dans la base Moodle serveur.

## 26. Règle sur les tests

Un test est normalement une lecture.

Définition :

```text
Test = vérification automatique ou semi-automatique.
```

Règle :

```text
Un test ne doit pas modifier de données.
```

Si une vérification nécessite une préparation qui modifie quelque chose, elle ne doit pas être appelée simplement “Test”.

Elle doit être classée selon son niveau réel.

## 27. Règle sur les anciens outils

Un ancien outil ne doit pas être lancé depuis un workflow normal.

Définition :

```text
Ancien outil / legacy = outil conservé pour référence, mais non recommandé pour le workflow normal.
```

Si une logique ancienne est encore utile, elle doit être intégrée proprement dans un module normal.

Sinon, elle reste dans :

```text
legacy
```

ou :

```text
recovery
```

## 28. Règle sur les refus automatiques

L’application doit refuser de continuer si :

```text
une action destructive n’a pas de sauvegarde ;
la cible local/serveur est ambiguë ;
la configuration nécessaire est absente ;
la simulation requise n’a pas été faite ;
une action recovery est lancée depuis un onglet normal ;
une action serveur n’a pas de confirmation ;
une action base Moodle serveur n’a pas de confirmation.
```

Message recommandé :

```text
Action refusée.
Cause : condition de sécurité manquante.
Prochaine étape : ...
```

## 29. Règle sur les erreurs de sécurité

Une erreur de sécurité doit être claire.

Exemple :

```text
Action refusée.
Cause : aucune sauvegarde vérifiée pour cette récupération.
Prochaine étape : créer une sauvegarde avant de continuer.
Détail technique : niveau de danger 7.
```

## 30. Règle sur l’IA pendant le codage

L’IA ne doit pas :

```text
réduire les confirmations pour aller plus vite ;
remplacer une confirmation forte par un simple log ;
placer recovery dans un workflow normal ;
supposer qu’un serveur peut être modifié sans danger ;
supposer qu’une base Moodle peut être reconstruite sans sauvegarde ;
inventer un nouveau niveau de danger ;
présenter une action destructive comme une action normale ;
nommer un bouton de façon vague pour cacher la complexité.
```

Si une action ne rentre pas dans ce document, l’IA doit proposer une mise à jour documentaire avant de coder.

## 31. Résumé obligatoire

Les niveaux de danger sont :

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

Règles finales :

```text
Toute action doit avoir un niveau de danger.
Toute action sensible doit demander confirmation.
Toute action destructive doit exiger une sauvegarde.
Toute action importante doit produire un rapport.
Toute récupération doit rester dans Récupération.
Aucun workflow normal ne doit dépendre d’un outil recovery.
