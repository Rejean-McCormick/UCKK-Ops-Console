# 04 — Interface des onglets spécialisés

## 1. Rôle de ce document

Ce document définit les onglets spécialisés de la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il complète le document :

```text
docs/03_INTERFACE_ACCUEIL.md
```

Le document `03_INTERFACE_ACCUEIL.md` protège le premier onglet.

Le présent document définit les autres onglets.

Il sert à empêcher l’IA de mélanger les domaines, de créer des boutons vagues ou de replacer des outils dangereux dans les écrans normaux.

## 2. Principe général

Les onglets spécialisés peuvent être plus détaillés que l’Accueil.

Mais ils doivent rester clairs.

Règle :

```text
Un onglet = un domaine de travail.
Un bouton = une action explicite.
Une action dangereuse = une confirmation visible.
Un outil recovery = onglet Récupération seulement.
Un ancien outil = pas dans les onglets normaux.
```

Définitions :

```text
Domaine de travail = grande zone fonctionnelle de l’application.

Action explicite = action dont le libellé dit ce qui est fait et sur quelle cible.

Recovery / récupération = action spéciale utilisée quand l’état normal est cassé.

Legacy = ancien outil conservé pour référence, mais qui ne doit pas être utilisé dans le workflow normal.
```

## 3. Onglets officiels

Les onglets officiels de l’application sont :

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

Le présent document définit tous les onglets sauf :

```text
Accueil
```

L’Accueil est défini séparément pour rester simple.

Aucun autre onglet ne doit être ajouté sans modification documentée de ce fichier.

## 4. Règle de navigation entre onglets

Un onglet peut proposer un raccourci vers un autre onglet.

Exemple :

```text
Après “Vérifier Git”, l’application peut proposer : ouvrir l’onglet Git.
```

Mais un onglet ne doit pas effectuer une action appartenant à un autre domaine sans le dire clairement.

Exemple interdit :

```text
Dans l’onglet Médiathèque, un bouton lance directement une publication serveur complète sans confirmation.
```

Exemple correct :

```text
Dans l’onglet Médiathèque, un bouton “Appliquer Médiathèque serveur” indique clairement qu’il écrit sur le serveur et demande confirmation.
```

## 5. Structure commune de chaque onglet

Chaque onglet spécialisé doit suivre une structure commune.

Structure recommandée :

```text
1. Titre de l’onglet
2. Description courte
3. État du domaine
4. Actions principales
5. Actions de vérification
6. Dernier résultat du domaine
7. Liens vers rapports ou détails
```

### 5.1 Titre

Le titre doit être le nom officiel de l’onglet.

Exemples :

```text
Local
Git
Serveur
Médiathèque
```

### 5.2 Description courte

Chaque onglet doit expliquer son rôle en une ou deux phrases.

Exemple :

```text
Local
Gère ce qui se passe sur l’ordinateur de développement.
```

### 5.3 État du domaine

L’état doit résumer la situation.

Exemples :

```text
Local : prêt
Git : changements présents
Serveur : accessible
Médiathèque : 128 références trouvées
```

### 5.4 Actions principales

Les actions principales sont les opérations normales du domaine.

Elles doivent être visibles.

Elles doivent avoir des libellés explicites.

### 5.5 Actions de vérification

Les actions de vérification ne doivent pas modifier les données.

Elles servent à confirmer l’état avant ou après une opération.

### 5.6 Dernier résultat

Chaque onglet doit afficher le dernier résultat concernant son domaine.

Format minimal :

```text
Statut :
Action :
Cible :
Résumé :
Prochaine étape :
Rapport :
```

### 5.7 Liens vers rapports ou détails

Chaque onglet peut permettre d’ouvrir :

```text
le dernier rapport du domaine ;
le dossier de rapports ;
le log technique si nécessaire ;
la documentation liée au domaine.
```

## 6. Onglet Local

### 6.1 Rôle

Nom officiel :

```text
Local
```

Rôle :

```text
Gérer ce qui se passe sur l’ordinateur de développement.
```

Définition :

```text
Local = l’ordinateur de développement.
```

Cet onglet sert à préparer et vérifier le Moodle local avant toute publication serveur.

### 6.2 Ce que l’onglet Local peut faire

L’onglet Local peut :

```text
vérifier les chemins locaux ;
vérifier la configuration locale ;
synchroniser la source vers Moodle local ;
purger les caches locaux ;
démarrer Moodle local ;
ouvrir Moodle local ;
tester les pages locales importantes ;
ouvrir les dossiers locaux importants.
```

Définitions :

```text
Source = dossier qui contient le code officiel que l’on modifie.

Moodle local = Moodle utilisé pour tester sur l’ordinateur avant publication.

Purger les caches = vider la mémoire temporaire de Moodle pour qu’il recharge les changements.
```

### 6.3 Boutons officiels de l’onglet Local

Boutons autorisés :

```text
Vérifier les chemins locaux
Vérifier la configuration locale
Synchroniser source vers Moodle local
Purger les caches locaux
Démarrer Moodle local
Ouvrir Moodle local
Tester les pages locales

Mettre à jour Moodle local
Ouvrir UCKK
Ouvrir UCC
Ouvrir Math
Tester switcher UCKK / UCC / Math
Ouvrir dossier source
Ouvrir dossier Moodle local
```

### 6.4 Actions interdites dans l’onglet Local

L’onglet Local ne doit pas contenir :

```text
action serveur ;
publication sur uckk.org ;
modification de la base Moodle serveur ;
rebuild Médiathèque ;
dump SQL ;
outil legacy ;
outil recovery.
```

### 6.5 Résultats attendus

Exemples :

```text
Réussi — les chemins locaux sont valides.
```

```text
Réussi — la source a été copiée vers Moodle local.
```

```text
Échoué — le dossier Moodle local est introuvable.
Prochaine étape : vérifier la configuration locale.
```

## 7. Onglet Git

### 7.1 Rôle

Nom officiel :

```text
Git
```

Rôle :

```text
Gérer l’historique du code.
```

Définition :

```text
Git = système qui garde l’historique des changements du projet.
```

Cet onglet doit aider l’utilisateur à voir les changements avant de les enregistrer ou de les envoyer.

### 7.2 Ce que l’onglet Git peut faire

L’onglet Git peut :

```text
afficher l’état Git ;
afficher les différences Git ;
vérifier les fichiers sensibles ;
créer un commit Git ;
envoyer les changements vers Git ;
récupérer les changements depuis Git ;
ouvrir le dossier source.
```

Définitions :

```text
Différences Git = détail des changements depuis la dernière version enregistrée.

Commit Git = sauvegarde officielle d’un ensemble de changements.

Envoyer vers Git = envoyer les commits vers le dépôt distant.

Récupérer depuis Git = récupérer les changements depuis le dépôt distant.

Fichier sensible = fichier qui peut contenir un secret ou une configuration privée.
```

### 7.3 Boutons officiels de l’onglet Git

Boutons autorisés :

```text
Vérifier Git
Afficher les différences Git
Vérifier les fichiers sensibles
Créer un commit Git
Envoyer les changements vers Git
Récupérer depuis Git
Ouvrir dossier source
```

### 7.4 Confirmation obligatoire

Les actions suivantes doivent demander confirmation :

```text
Créer un commit Git
Envoyer les changements vers Git
Récupérer depuis Git si cela peut modifier le dossier source
```

Message obligatoire ou équivalent très proche :

```text
Cette action enregistre ou envoie des changements dans l’historique Git.
Vérifie qu’aucun secret n’est inclus.
Continuer ?
```

Pour “Récupérer depuis Git”, utiliser :

```text
Cette action peut modifier les fichiers locaux en récupérant des changements depuis Git.
Continuer ?
```

### 7.5 Actions interdites dans l’onglet Git

L’onglet Git ne doit pas contenir :

```text
publication serveur complète sans passer par l’onglet Serveur ;
apply Médiathèque serveur ;
rebuild ;
wipe ;
dump SQL ;
outil recovery.
```

### 7.6 Résultats attendus

Exemples :

```text
Réussi — Git ne signale aucun changement.
```

```text
Réussi avec avertissements — Git signale des changements non enregistrés.
Prochaine étape : afficher les différences Git.
```

```text
Échoué — un fichier sensible semble présent.
Prochaine étape : vérifier les différences avant commit.
```

## 8. Onglet Serveur

### 8.1 Rôle

Nom officiel :

```text
Serveur
```

Rôle :

```text
Gérer les actions qui concernent uckk.org.
```

Définition :

```text
Serveur = ordinateur distant qui héberge le site public uckk.org.
```

Cet onglet est sensible.

Toute action qui modifie le serveur doit être claire et confirmée.

### 8.2 Ce que l’onglet Serveur peut faire

L’onglet Serveur peut :

```text
tester la connexion serveur ;
vérifier l’état du serveur ;
récupérer le dernier code depuis Git sur le serveur ;
synchroniser source serveur vers Moodle serveur ;
mettre à jour Moodle serveur ;
purger les caches serveur ;
recharger PHP-FPM ;
vérifier uckk.org ;
ouvrir les pages publiques importantes.
```

Définitions :

```text
Connexion serveur = accès sécurisé au serveur, généralement par SSH.

SSH = méthode sécurisée pour se connecter au serveur et y lancer des commandes.

Source serveur = dossier du code sur le serveur.

Moodle serveur = Moodle utilisé par le site public uckk.org.

PHP-FPM = service du serveur qui exécute le code PHP de Moodle.
```

### 8.3 Boutons officiels de l’onglet Serveur

Boutons autorisés :

```text
Tester connexion serveur
Vérifier état serveur
Récupérer dernier code sur serveur
Synchroniser source serveur vers Moodle serveur
Mettre à jour Moodle serveur
Purger les caches serveur
Recharger PHP-FPM
Vérifier uckk.org
Ouvrir uckk.org
Ouvrir Médiathèque serveur
```

### 8.4 Confirmation obligatoire

Les actions suivantes doivent demander confirmation :

```text
Récupérer dernier code sur serveur
Synchroniser source serveur vers Moodle serveur
Mettre à jour Moodle serveur
Purger les caches serveur
Recharger PHP-FPM
```

Message obligatoire ou équivalent très proche :

```text
Cette action modifie uckk.org ou sa base Moodle. Continuer ?
```

Si l’action ne modifie pas la base Moodle mais modifie le runtime serveur, utiliser :

```text
Cette action modifie le code exécuté par uckk.org. Continuer ?
```

Définition :

```text
Runtime serveur = dossier que Moodle serveur exécute réellement.
```

### 8.5 Actions interdites dans l’onglet Serveur

L’onglet Serveur ne doit pas contenir :

```text
wipe Médiathèque ;
rebuild Médiathèque ;
dump SQL brut ;
copie directe de tables ;
restauration de sauvegarde ;
ancien script legacy ;
action recovery non isolée.
```

Ces actions appartiennent à l’onglet :

```text
Récupération
```

### 8.6 Résultats attendus

Exemples :

```text
Réussi — la connexion serveur fonctionne.
```

```text
Réussi — les caches serveur ont été purgés.
Prochaine étape : vérifier uckk.org.
```

```text
Échoué — la connexion SSH au serveur ne fonctionne pas.
Prochaine étape : vérifier les paramètres serveur.
Détail technique : code de retour 255.
```

## 9. Onglet Médiathèque

### 9.1 Rôle

Nom officiel :

```text
Médiathèque
```

Rôle :

```text
Gérer le workflow normal des références Médiathèque.
```

Définition :

```text
Médiathèque = liste organisée de références publiques : vidéos, articles, sons, livres, pages web, dépôts de code et autres ressources.
```

Cet onglet doit être le seul endroit normal pour ajouter, simuler, appliquer et vérifier les références Médiathèque.

### 9.2 Principe obligatoire

Le workflow normal de la Médiathèque est :

```text
manifeste → simulation → appliquer → vérifier
```

Définition :

```text
Manifeste Médiathèque = fichier source qui liste les références de la Médiathèque.
```

La base Moodle est une cible.

Elle n’est pas la source principale d’édition de la Médiathèque.

Définition :

```text
Cible = endroit où une donnée est envoyée ou appliquée.
```

### 9.3 Ce que l’onglet Médiathèque peut faire

L’onglet Médiathèque peut :

```text
ouvrir le manifeste Médiathèque ;
vérifier le manifeste Médiathèque ;
lancer une simulation locale ;
appliquer la Médiathèque localement ;
vérifier la Médiathèque locale ;
lancer une simulation serveur ;
appliquer la Médiathèque serveur ;
vérifier la Médiathèque serveur ;
ouvrir les rapports Médiathèque.
```

### 9.4 Boutons officiels de l’onglet Médiathèque

Boutons autorisés :

```text
Ouvrir manifeste Médiathèque
Vérifier manifeste Médiathèque
Simulation Médiathèque locale
Appliquer Médiathèque localement
Vérifier Médiathèque locale
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
Vérifier Médiathèque serveur
Ouvrir rapport Médiathèque
```

### 9.5 Confirmation obligatoire

Les actions suivantes doivent demander confirmation :

```text
Appliquer Médiathèque localement
Appliquer Médiathèque serveur
```

Pour local :

```text
Cette action écrit dans la base Moodle locale. Continuer ?
```

Pour serveur :

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

### 9.6 Actions interdites dans l’onglet Médiathèque

L’onglet Médiathèque ne doit pas contenir :

```text
wipe Médiathèque ;
rebuild complet ;
export depuis la page publique comme source de vérité ;
dump SQL brut ;
copie directe de tables ;
import media_original ;
outil legacy ;
outil recovery.
```

Ces actions appartiennent à :

```text
Récupération
```

ou :

```text
Legacy
```

selon leur rôle.

### 9.7 Résultats attendus

Exemples :

```text
Réussi — le manifeste Médiathèque est valide.
```

```text
Réussi — simulation terminée : 1 référence serait créée, 2 seraient mises à jour, 0 erreur.
```

```text
Réussi — la Médiathèque serveur retourne 128 références.
À vérifier dans le navigateur : ouvrir la page Médiathèque serveur.
```

## 10. Onglet Données Moodle

### 10.1 Rôle

Nom officiel :

```text
Données Moodle
```

Rôle :

```text
Gérer les données Moodle structurées qui ne sont pas la Médiathèque.
```

Définition :

```text
Données Moodle = informations enregistrées dans Moodle, comme les catégories, cours, programmes, parcours, rôles et permissions.
```

### 10.2 Ce que l’onglet Données Moodle peut faire

L’onglet Données Moodle peut :

```text
vérifier les fichiers JSON ;
lancer des simulations ;
appliquer des données localement ;
appliquer des données sur serveur ;
vérifier les résultats dans Moodle ;
ouvrir les rapports de données Moodle.
```

Définitions :

```text
Fichier JSON = fichier texte structuré qui décrit des données.

Simulation = action qui montre ce qui serait fait, sans modifier les données.

Appliquer = écrire réellement les changements dans Moodle.
```

### 10.3 Boutons officiels de l’onglet Données Moodle

Boutons autorisés :

```text
Vérifier fichiers JSON Moodle
Simulation catégories locales
Appliquer catégories localement
Simulation catégories serveur
Appliquer catégories serveur
Simulation cours locaux
Appliquer cours localement
Simulation cours serveur
Appliquer cours serveur
Simulation programmes locaux
Appliquer programmes localement
Simulation programmes serveur
Appliquer programmes serveur
Simulation parcours locaux
Appliquer parcours localement
Simulation parcours serveur
Appliquer parcours serveur
Ouvrir rapport Données Moodle
```

### 10.4 Confirmation obligatoire

Toute action “Appliquer” doit demander confirmation.

Pour local :

```text
Cette action écrit dans la base Moodle locale. Continuer ?
```

Pour serveur :

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

### 10.5 Actions interdites dans l’onglet Données Moodle

L’onglet Données Moodle ne doit pas contenir :

```text
dump SQL brut ;
copie directe de tables ;
wipe ;
restauration de sauvegarde ;
action recovery.
```

## 11. Onglet Tests

### 11.1 Rôle

Nom officiel :

```text
Tests
```

Rôle :

```text
Vérifier rapidement que les éléments importants fonctionnent.
```

Définition :

```text
Test = vérification automatique ou semi-automatique.
```

Cet onglet ne doit pas modifier les données.

### 11.2 Ce que l’onglet Tests peut faire

L’onglet Tests peut :

```text
tester les pages locales ;
tester les pages serveur ;
tester la Médiathèque locale ;
tester la Médiathèque serveur ;
tester l’index des cours ;
tester les pages publiques UCKK ;
ouvrir les rapports de test.
```

### 11.3 Boutons officiels de l’onglet Tests

Boutons autorisés :

```text
Tester pages locales
Tester pages serveur
Tester Médiathèque locale
Tester Médiathèque serveur
Tester index des cours local
Tester index des cours serveur
Tester pages publiques UCKK
Ouvrir rapport de tests
```

### 11.4 Résultats attendus

Exemples :

```text
Réussi — les pages locales répondent.
```

```text
Réussi avec avertissements — la page Médiathèque répond, mais les cartes doivent être vérifiées dans le navigateur.
```

```text
Échoué — la page serveur ne répond pas.
Prochaine étape : ouvrir l’onglet Serveur.
```

### 11.5 Actions interdites dans l’onglet Tests

L’onglet Tests ne doit pas contenir d’actions qui modifient :

```text
fichiers ;
Git ;
base Moodle ;
serveur ;
Médiathèque.
```

Si un test doit préparer quelque chose avant de lire, cela doit être très clairement indiqué et documenté.

Par défaut :

```text
Un test lit ou vérifie.
Un test ne modifie pas.
```

## 12. Onglet Historique

### 12.1 Rôle

Nom officiel :

```text
Historique
```

Rôle :

```text
Voir ce qui a été fait récemment.
```

Définition :

```text
Historique = liste des actions passées, rapports et logs disponibles.
```

### 12.2 Ce que l’onglet Historique peut faire

L’onglet Historique peut :

```text
afficher les dernières actions ;
ouvrir le dernier rapport ;
ouvrir un rapport par domaine ;
ouvrir le dossier des rapports ;
ouvrir le dossier des logs ;
ouvrir un log technique ;
filtrer les rapports par domaine.
```

Définitions :

```text
Rapport = résumé lisible d’une action.

Log technique = journal détaillé utile pour diagnostiquer une action.

Filtrer = afficher seulement une partie d’une liste selon un critère.
```

### 12.3 Boutons officiels de l’onglet Historique

Boutons autorisés :

```text
Ouvrir dernier rapport
Ouvrir rapports Local
Ouvrir rapports Git
Ouvrir rapports Serveur
Ouvrir rapports Médiathèque
Ouvrir rapports Données Moodle
Ouvrir rapports Tests
Ouvrir dossier rapports
Ouvrir dossier logs
```

### 12.4 Actions interdites dans l’onglet Historique

L’onglet Historique ne doit pas modifier les données.

Il peut ouvrir des fichiers ou dossiers.

Il ne doit pas relancer automatiquement une ancienne action.

Si un rapport contient un lien “relancer”, ce lien doit être considéré comme action du domaine concerné, pas comme action d’historique.

## 13. Onglet Récupération

### 13.1 Rôle

Nom officiel :

```text
Récupération
```

Rôle :

```text
Réparer une situation cassée.
```

Définition :

```text
Récupération = action spéciale utilisée quand l’état normal est cassé.
```

Cet onglet est dangereux par défaut.

Il ne doit pas servir au travail quotidien.

### 13.2 Ce que l’onglet Récupération peut faire

L’onglet Récupération peut :

```text
créer une sauvegarde avant réparation ;
comparer local et serveur ;
inspecter des compteurs de base Moodle ;
restaurer une Médiathèque depuis une source fiable ;
reconstruire des liens manquants ;
ouvrir les anciens rapports de réparation ;
ouvrir les outils legacy sans les lancer automatiquement.
```

Définition :

```text
Sauvegarde = copie conservée avant une action risquée pour pouvoir revenir en arrière.
```

### 13.3 Boutons officiels de l’onglet Récupération

Boutons autorisés, seulement si la logique est documentée :

```text
Créer sauvegarde avant récupération
Comparer Médiathèque locale et serveur
Vérifier compteurs Médiathèque
Reconstruire Médiathèque depuis external_work
Reconstruire collections Médiathèque
Ouvrir dossier recovery
Ouvrir dossier legacy
Ouvrir rapport de récupération
```

### 13.4 Confirmation obligatoire

Toute action de récupération qui modifie des données doit demander confirmation forte.

Message obligatoire ou équivalent très proche :

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

Si aucune sauvegarde n’existe ou n’est déclarée, l’action doit refuser de continuer ou proposer d’en créer une.

### 13.5 Actions interdites dans l’onglet Récupération

Même dans Récupération, certaines choses ne doivent pas être faites sans contrat précis :

```text
suppression complète sans sauvegarde ;
dump SQL brut vers serveur sans validation ;
copie directe de tables sans mapping ;
rebuild silencieux ;
réparation sans rapport ;
réparation sans confirmation.
```

Définition :

```text
Mapping = correspondance entre anciens identifiants et nouveaux identifiants.
```

### 13.6 Résultats attendus

Exemples :

```text
Réussi — sauvegarde créée avant récupération.
```

```text
Réussi avec avertissements — les compteurs local et serveur diffèrent.
Prochaine étape : lire le rapport avant toute réparation.
```

```text
Échoué — aucune sauvegarde disponible.
Prochaine étape : créer une sauvegarde avant récupération.
```

## 14. Règle sur les outils legacy dans les onglets

Les outils legacy ne doivent pas apparaître dans les onglets normaux.

Onglets normaux :

```text
Accueil
Local
Git
Serveur
Médiathèque
Données Moodle
Tests
Historique
```

Les outils legacy peuvent être visibles seulement dans :

```text
Récupération
```

ou dans un dossier ouvert manuellement.

Définition :

```text
Outil legacy = ancien outil conservé pour référence, mais non recommandé pour le workflow normal.
```

Règle :

```text
Afficher un outil legacy ne signifie pas le recommander.
```

## 15. Règle sur les confirmations dans les onglets spécialisés

Les confirmations sont obligatoires selon le niveau de danger.

### 15.1 Lecture

Pas de confirmation.

Exemples :

```text
Vérifier Git
Ouvrir rapport
Tester pages locales
```

### 15.2 Modification locale

Confirmation simple ou message visible selon le risque.

Exemple :

```text
Cette action modifie seulement Moodle local.
```

### 15.3 Git

Confirmation obligatoire avant commit ou envoi.

Message :

```text
Cette action enregistre ou envoie des changements dans l’historique Git.
Vérifie qu’aucun secret n’est inclus.
Continuer ?
```

### 15.4 Serveur

Confirmation obligatoire.

Message :

```text
Cette action modifie uckk.org ou sa base Moodle. Continuer ?
```

### 15.5 Récupération

Confirmation forte obligatoire.

Message :

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

## 16. Règle sur les rapports dans les onglets spécialisés

Toute action importante doit produire un rapport.

Actions qui doivent produire un rapport :

```text
synchronisation locale ;
publication serveur ;
application Médiathèque ;
application Données Moodle ;
tests serveur ;
actions recovery ;
erreurs ;
avertissements.
```

Un rapport doit indiquer :

```text
action ;
cible ;
mode ;
résumé ;
changements ;
avertissements ;
erreurs ;
prochaine étape.
```

Définition :

```text
Mode = façon dont l’action a été lancée, par exemple simulation ou application.
```

## 17. Règle sur les libellés de boutons

Les libellés doivent suivre le vocabulaire obligatoire.

Interdits comme boutons seuls :

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

Exemples corrects :

```text
Synchroniser source vers Moodle local
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
Vérifier fichiers JSON Moodle
Créer sauvegarde avant récupération
```

## 18. Règle sur les descriptions

Chaque bouton spécialisé doit avoir une description courte.

Format :

```text
Bouton
Description.
```

Exemple :

```text
Simulation Médiathèque serveur
Vérifie ce qui serait écrit dans la base Moodle serveur, sans modifier les données.
```

Si une description demande plus de deux phrases, ajouter un lien vers la documentation du domaine.

## 19. Règle sur les erreurs

Les erreurs doivent suivre la forme obligatoire :

```text
L’action a échoué.
Cause probable : ...
Prochaine étape : ...
Détail technique : ...
```

Les détails techniques longs doivent aller dans le log technique.

L’onglet doit afficher un résumé lisible.

## 20. Règle anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
ajouter un onglet non documenté ;
ajouter un bouton non documenté ;
déplacer un outil recovery dans un onglet normal ;
utiliser un mot anglais vague comme libellé principal ;
faire une action serveur sans confirmation ;
faire une action base Moodle sans confirmation ;
faire une action recovery sans sauvegarde ou confirmation forte ;
mélanger local et serveur dans un même bouton vague ;
afficher une sortie technique brute comme résultat principal.
```

Si un nouveau bouton semble nécessaire, l’IA doit proposer une modification du présent document avant de le coder.

## 21. Résumé obligatoire

Onglets spécialisés officiels :

```text
Local
Git
Serveur
Médiathèque
Données Moodle
Tests
Historique
Récupération
```

Règle principale :

```text
Chaque onglet a un domaine clair.
Chaque action a un libellé explicite.
Chaque modification sensible demande confirmation.
Chaque action importante produit un rapport.
Les outils legacy et recovery ne contaminent pas les workflows normaux.
```

Règle finale :

```text
Si l’utilisateur ne peut pas comprendre où l’action s’applique, ce qu’elle modifie et quoi vérifier ensuite, l’action n’est pas prête à être codée.
