# 07 — Workflow Local, Git et Serveur

## 1. Rôle de ce document

Ce document définit les workflows normaux entre :

```text
Local
Git
Serveur
```

Il s’applique à la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il sert à empêcher l’IA de coder un flux de publication confus, incomplet ou dangereux.

Définition :

```text
Workflow = suite officielle d’étapes pour accomplir une opération.
```

Définition :

```text
Local = ordinateur de développement.
```

Définition :

```text
Git = système qui garde l’historique des changements du projet.
```

Définition :

```text
Serveur = ordinateur distant qui héberge le site public uckk.org.
```

## 2. Principe central

Le workflow normal doit suivre cette direction :

```text
source locale → Moodle local → Git → source serveur → Moodle serveur → vérification navigateur
```

Cette direction est obligatoire.

Elle signifie :

```text
1. On travaille d’abord localement.
2. On teste localement.
3. On enregistre dans Git.
4. On met à jour le serveur depuis Git.
5. On synchronise le serveur vers le dossier exécuté par Moodle.
6. On vérifie le vrai site.
```

Règle :

```text
Le serveur ne doit pas devenir l’endroit où l’on improvise des modifications.
```

## 3. Définitions essentielles

### 3.1 Source locale

Définition :

```text
Source locale = dossier du code UCKK modifié sur l’ordinateur de développement.
```

Chemin prévu :

```text
C:\mycode\UCKK\uckk-moodle
```

### 3.2 Moodle local

Définition :

```text
Moodle local = Moodle utilisé pour tester sur l’ordinateur avant de publier.
```

URL prévue :

```text
http://localhost:8000
```

### 3.3 Runtime local

Nom visible recommandé :

```text
Dossier exécuté par Moodle local
```

Nom technique :

```text
runtime local
```

Définition :

```text
Runtime local = dossier que Moodle local lit réellement quand il fonctionne.
```

Chemin prévu :

```text
C:\mycode\UCKK\moodle\moodle\public
```

### 3.4 Dépôt Git

Définition :

```text
Dépôt Git = dossier dont les changements sont suivis par Git.
```

Dans ce projet, il correspond normalement à :

```text
C:\mycode\UCKK\uckk-moodle
```

### 3.5 Source serveur

Définition :

```text
Source serveur = dossier du code UCKK sur le serveur.
```

Chemin prévu :

```text
/opt/uckk/uckk-moodle
```

### 3.6 Moodle serveur

Définition :

```text
Moodle serveur = Moodle utilisé par le site public uckk.org.
```

### 3.7 Runtime serveur

Nom visible recommandé :

```text
Dossier exécuté par Moodle serveur
```

Nom technique :

```text
runtime serveur
```

Définition :

```text
Runtime serveur = dossier que Moodle serveur lit réellement quand uckk.org fonctionne.
```

Chemin prévu :

```text
/var/www/moodle/public
```

### 3.8 Moodle root serveur

Définition :

```text
Moodle root serveur = racine principale de Moodle sur le serveur.
```

Chemin prévu :

```text
/var/www/moodle
```

## 4. Workflow local normal

### 4.1 But

Le workflow local prépare et teste les changements sur l’ordinateur avant Git et avant serveur.

Règle :

```text
On ne publie pas sur serveur ce qui n’a pas été au moins vérifié localement, sauf urgence explicitement documentée.
```

### 4.2 Étapes officielles

Étapes :

```text
1. Vérifier les chemins locaux.
2. Synchroniser source vers Moodle local.
3. Mettre à jour Moodle local après une synchronisation de plugins.
4. Purger les caches locaux.
5. Démarrer Moodle local si nécessaire.
6. Ouvrir UCKK, UCC ou Math.
7. Tester les pages locales et le switcher multi-façades.
8. Lire le résultat ou le rapport.
```

### 4.3 Boutons liés

Boutons autorisés dans l’application :

```text
Vérifier les chemins locaux
Synchroniser source vers Moodle local
Purger les caches locaux
Démarrer Moodle local
Ouvrir Moodle local
Tester les pages locales
```

### 4.4 Ce que “Vérifier les chemins locaux” doit contrôler

Cette action doit vérifier :

```text
racine de la nouvelle app ;
fichier de configuration ;
source locale ;
Moodle local ;
dossier exécuté par Moodle local ;
dossier reports ;
dossier logs.
```

Elle ne doit rien modifier, sauf créer les dossiers `reports` ou `logs` si cette création est autorisée par la configuration.

### 4.5 Ce que “Synchroniser source vers Moodle local” doit faire

Cette action copie les fichiers nécessaires depuis :

```text
source locale
```

vers :

```text
dossier exécuté par Moodle local
```

Elle doit respecter les exclusions nécessaires.

Exemples de choses à ne pas copier si elles existent :

```text
.git
fichiers temporaires
logs
rapports
secrets
dumps SQL
config.php serveur
```

Définition :

```text
Exclusion = fichier ou dossier volontairement ignoré pendant une copie.
```

### 4.6 Ce que “Purger les caches locaux” doit faire

Cette action doit vider les caches Moodle locaux.

Définition :

```text
Cache = mémoire temporaire utilisée par Moodle.
```

But :

```text
forcer Moodle local à relire les changements.
```

### 4.7 Tests locaux recommandés

Tests locaux importants :

```text
page d’accueil locale ;
index des cours local ;
pages publiques UCKK locales ;
Médiathèque locale si elle est concernée ;
page modifiée par le changement courant.
```

URLs typiques :

```text
http://localhost:8000
http://localhost:8000/course/index.php
http://localhost:8000/local/uckk/mediatheque.php
```

### 4.8 Résultat attendu

Exemple :

```text
Réussi — Moodle local répond et les pages locales importantes sont accessibles.
```

Si une page doit être confirmée visuellement :

```text
À vérifier dans le navigateur — la page répond, mais l’affichage doit être confirmé.
```

## 5. Workflow Git normal

### 5.1 But

Le workflow Git sert à enregistrer proprement les changements avant publication serveur.

Règle :

```text
Le serveur doit être mis à jour depuis un état Git clair.
```

### 5.2 Étapes officielles

Étapes :

```text
1. Vérifier Git.
2. Afficher les différences Git.
3. Vérifier qu’aucun secret n’est inclus.
4. Créer un commit Git.
5. Envoyer les changements vers Git.
```

### 5.3 Boutons liés

Boutons autorisés :

```text
Vérifier Git
Afficher les différences Git
Vérifier les fichiers sensibles
Créer un commit Git
Envoyer les changements vers Git
```

### 5.4 Ce que “Vérifier Git” doit faire

Cette action doit afficher :

```text
fichiers modifiés ;
fichiers ajoutés ;
fichiers supprimés ;
branche actuelle ;
état par rapport au dépôt distant si disponible.
```

Définition :

```text
Branche = ligne de travail dans Git.
```

### 5.5 Ce que “Afficher les différences Git” doit faire

Cette action doit montrer les changements de contenu.

Définition :

```text
Différences Git = détail des changements depuis la dernière version enregistrée.
```

L’application peut afficher un résumé dans l’interface et produire un rapport.

### 5.6 Ce que “Vérifier les fichiers sensibles” doit contrôler

Cette action doit chercher des signes de secrets ou fichiers interdits.

Fichiers ou contenus à signaler :

```text
config.php serveur
mots de passe
tokens
clés privées
dumps SQL
fichiers .env
secrets Moodle
secrets de base de données
archives de sauvegarde
```

Définition :

```text
Token = chaîne secrète utilisée pour autoriser un accès.
```

Cette vérification ne garantit pas qu’il n’y a aucun secret.

Elle aide seulement à éviter les erreurs évidentes.

Le rapport doit dire :

```text
Cette vérification ne remplace pas une lecture humaine des différences Git.
```

### 5.7 Ce que “Créer un commit Git” doit faire

Cette action crée une sauvegarde officielle des changements dans Git.

Définition :

```text
Commit Git = sauvegarde officielle d’un ensemble de changements dans l’historique du projet.
```

Confirmation obligatoire :

```text
Cette action enregistre des changements dans l’historique Git.
Vérifie qu’aucun secret n’est inclus.
Continuer ?
```

Règle :

```text
L’application ne doit pas créer un commit si Git signale un état incohérent ou si la vérification de fichiers sensibles bloque.
```

### 5.8 Ce que “Envoyer les changements vers Git” doit faire

Cette action envoie les commits vers le dépôt distant.

Définition :

```text
Envoyer vers Git = transmettre les commits vers le dépôt distant.
```

Confirmation obligatoire :

```text
Cette action envoie des changements vers Git.
Vérifie qu’aucun secret n’est inclus.
Continuer ?
```

### 5.9 Résultat attendu

Exemples :

```text
Réussi — Git ne signale aucun changement.
```

```text
Réussi — commit Git créé.
```

```text
Réussi — changements envoyés vers Git.
```

```text
Échoué — des fichiers sensibles semblent inclus.
Prochaine étape : vérifier les différences Git.
```

## 6. Workflow serveur normal

### 6.1 But

Le workflow serveur publie une version validée sur :

```text
uckk.org
```

Il doit être plus protégé que le workflow local.

Règle :

```text
Toute action qui modifie uckk.org doit être visible, confirmée et rapportée.
```

### 6.2 Étapes officielles

Étapes :

```text
1. Tester connexion serveur.
2. Vérifier le dernier commit local envoyé vers Git.
3. Récupérer dernier code sur serveur.
4. Synchroniser source serveur vers Moodle serveur.
5. Mettre à jour Moodle serveur si nécessaire.
6. Purger les caches serveur.
7. Recharger PHP-FPM si nécessaire.
8. Vérifier uckk.org.
9. Vérifier dans le navigateur les pages concernées.
10. Lire le rapport de publication.
```

### 6.3 Boutons liés

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
```

### 6.4 Ce que “Tester connexion serveur” doit faire

Cette action vérifie que l’application peut se connecter au serveur.

Définition :

```text
Connexion SSH = méthode sécurisée pour se connecter au serveur et y lancer des commandes.
```

Elle ne doit pas modifier le serveur.

Résultat attendu :

```text
Réussi — la connexion serveur fonctionne.
```

ou :

```text
Échoué — la connexion serveur ne fonctionne pas.
Prochaine étape : vérifier la configuration serveur ou la connexion SSH.
```

### 6.5 Ce que “Vérifier état serveur” doit faire

Cette action doit lire l’état serveur sans modifier.

Elle peut vérifier :

```text
dossier source serveur ;
dossier Moodle serveur ;
branche Git serveur ;
dernier commit serveur ;
présence du runtime serveur ;
réponse du site public.
```

Elle ne doit pas :

```text
faire git pull ;
synchroniser ;
purger caches ;
modifier fichiers ;
modifier base Moodle.
```

### 6.6 Ce que “Récupérer dernier code sur serveur” doit faire

Cette action met à jour la source serveur depuis Git.

Elle modifie le serveur.

Confirmation obligatoire :

```text
Cette action modifie le code source sur le serveur. Continuer ?
```

Elle doit produire un rapport.

Elle ne doit pas modifier directement le runtime Moodle serveur sauf si cette étape est explicitement incluse dans une action en chaîne documentée.

### 6.7 Ce que “Synchroniser source serveur vers Moodle serveur” doit faire

Cette action copie le code serveur source vers le dossier exécuté par Moodle serveur.

Source :

```text
/opt/uckk/uckk-moodle
```

Cible :

```text
/var/www/moodle/public
```

Confirmation obligatoire :

```text
Cette action modifie le code exécuté par uckk.org. Continuer ?
```

Elle doit respecter les exclusions nécessaires :

```text
.git
logs
rapports
secrets
dumps SQL
config.php serveur si non prévu
outils temporaires
```

### 6.8 Ce que “Mettre à jour Moodle serveur” doit faire

Cette action lance la mise à jour Moodle côté serveur si nécessaire.

Définition :

```text
Mettre à jour Moodle = lancer l’étape où Moodle applique les changements nécessaires après une modification de code ou de structure.
```

Confirmation obligatoire :

```text
Cette action peut modifier la base Moodle serveur. Continuer ?
```

Si cette action écrit dans la base Moodle serveur, elle est niveau 6 selon le document de sécurité.

### 6.9 Ce que “Purger les caches serveur” doit faire

Cette action vide les caches Moodle serveur.

Confirmation obligatoire :

```text
Cette action modifie l’état temporaire de Moodle serveur. Continuer ?
```

Elle doit produire un rapport.

### 6.10 Ce que “Recharger PHP-FPM” doit faire

Cette action recharge le service PHP du serveur.

Définition :

```text
PHP-FPM = service du serveur qui exécute le code PHP de Moodle.
```

Confirmation obligatoire :

```text
Cette action recharge le service PHP du serveur. Continuer ?
```

Elle ne doit pas redémarrer toute la machine.

### 6.11 Ce que “Vérifier uckk.org” doit faire

Cette action teste les pages publiques importantes sans modifier le serveur.

Pages recommandées :

```text
https://uckk.org
https://uckk.org/course/index.php
https://uckk.org/local/uckk/mediatheque.php
```

Elle doit distinguer :

```text
page qui répond ;
page qui affiche correctement ;
données chargées après ouverture.
```

Définition :

```text
Données chargées après ouverture = données récupérées par JavaScript ou AJAX une fois la page déjà ouverte.
```

Règle :

```text
Une réponse HTTP 200 ne suffit pas toujours à confirmer que la page fonctionne visuellement.
```

### 6.12 Résultat attendu

Exemples :

```text
Réussi — uckk.org répond.
```

```text
Réussi avec avertissements — la page Médiathèque répond, mais les cartes doivent être vérifiées dans le navigateur.
```

```text
Échoué — la synchronisation serveur a échoué.
Prochaine étape : lire le rapport de publication.
```

## 7. Workflow de publication en chaîne

### 7.1 Définition

```text
Publication en chaîne = action qui exécute plusieurs étapes serveur dans un ordre prévu.
```

Exemple :

```text
Publier sur serveur
```

peut contenir :

```text
tester connexion serveur ;
récupérer dernier code sur serveur ;
synchroniser source serveur vers Moodle serveur ;
mettre à jour Moodle si nécessaire ;
purger caches serveur ;
vérifier uckk.org.
```

### 7.2 Règle

Une publication en chaîne doit annoncer ses étapes avant de commencer.

Elle doit demander confirmation.

Message recommandé :

```text
Cette action va mettre à jour uckk.org à partir du code Git validé.
Elle peut modifier le code serveur, les caches Moodle et possiblement la base Moodle.
Continuer ?
```

### 7.3 Rapport obligatoire

Le rapport doit indiquer pour chaque étape :

```text
non lancée ;
en cours ;
réussie ;
réussie avec avertissements ;
échouée ;
ignorée.
```

Définition :

```text
Ignorée = étape volontairement non exécutée parce qu’elle n’était pas nécessaire ou parce qu’une étape précédente a échoué.
```

### 7.4 Arrêt sur erreur

Si une étape critique échoue, la chaîne doit s’arrêter.

Exemples d’étapes critiques :

```text
connexion serveur ;
récupération du code ;
synchronisation vers Moodle serveur ;
mise à jour Moodle si obligatoire.
```

Règle :

```text
L’application ne doit pas continuer comme si tout allait bien après une étape critique échouée.
```

## 8. Workflow de vérification après publication

### 8.1 But

Après une publication, il faut vérifier que le site fonctionne.

### 8.2 Étapes officielles

Étapes :

```text
1. Vérifier uckk.org techniquement.
2. Ouvrir uckk.org dans le navigateur.
3. Ouvrir les pages concernées.
4. Si la Médiathèque est concernée, vérifier les cartes chargées.
5. Lire le rapport.
```

### 8.3 Vérifications techniques

Vérifications possibles :

```text
HTTP 200 ;
présence du shell public ;
service AJAX répond ;
nombre de résultats attendu ;
absence d’erreur visible.
```

Définitions :

```text
HTTP 200 = réponse technique indiquant qu’une page a répondu.

Shell public = structure HTML de base d’une page publique.

Service AJAX = fonction appelée par une page pour charger des données après son ouverture.
```

### 8.4 Vérification navigateur

La vérification navigateur est obligatoire quand la page dépend de JavaScript ou AJAX.

Exemple :

```text
Médiathèque
```

Règle :

```text
Si les cartes sont chargées par JavaScript ou AJAX, curl ou HTTP 200 ne suffit pas.
```

Définition :

```text
curl = outil technique qui lit une URL sans afficher la page comme un navigateur.
```

## 9. Interdictions dans le workflow Local/Git/Serveur

Le workflow normal ne doit pas contenir :

```text
wipe ;
rebuild complet ;
dump SQL brut ;
copie directe de tables ;
modification manuelle sur serveur ;
commit automatique sans diff ;
push automatique sans confirmation ;
publication serveur sans vérification Git ;
publication serveur sans rapport ;
suppression de données sans sauvegarde ;
outil legacy ;
outil recovery.
```

Définition :

```text
Modification manuelle sur serveur = changement fait directement sur le serveur sans passer par le workflow documenté.
```

## 10. Règle sur les états ambigus

Si l’état est ambigu, l’application doit refuser ou demander une action de vérification.

Définition :

```text
Ambigu = pas assez clair pour agir en sécurité.
```

Exemples :

```text
branche Git inconnue ;
dernier commit serveur inconnu ;
chemin serveur absent ;
configuration incomplète ;
Moodle local introuvable ;
diff Git non vérifié avant publication.
```

Message recommandé :

```text
Action refusée.
Cause : l’état actuel n’est pas assez clair pour continuer.
Prochaine étape : lancer la vérification indiquée.
```

## 11. Règle sur les rapports

Les workflows suivants doivent produire un rapport :

```text
workflow local ;
workflow Git si écriture ;
workflow serveur ;
publication en chaîne ;
vérification après publication ;
toute erreur ;
tout avertissement.
```

Un rapport doit indiquer :

```text
action ;
cible ;
mode ;
étapes ;
résultat ;
avertissements ;
erreurs ;
prochaine étape.
```

Définition :

```text
Mode = façon dont l’action a été lancée, par exemple vérification, simulation ou application.
```

## 12. Règle sur les logs techniques

Chaque workflow important doit produire ou compléter un log technique.

Définition :

```text
Log technique = journal détaillé utile pour diagnostiquer une action.
```

Le log peut contenir :

```text
commandes exécutées ;
sorties techniques ;
codes de retour ;
timestamps ;
chemins utilisés.
```

Le log ne doit pas contenir :

```text
mots de passe ;
tokens ;
clés privées ;
secrets de base de données.
```

## 13. Règle sur les messages d’erreur

Les erreurs doivent être lisibles.

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
Cause probable : le serveur ne répond pas à la connexion SSH.
Prochaine étape : vérifier la connexion serveur dans l’onglet Serveur.
Détail technique : code de retour 255.
```

## 14. Règle sur les confirmations

Confirmations obligatoires :

### 14.1 Git

```text
Cette action enregistre ou envoie des changements dans l’historique Git.
Vérifie qu’aucun secret n’est inclus.
Continuer ?
```

### 14.2 Serveur

```text
Cette action modifie uckk.org ou son code serveur. Continuer ?
```

### 14.3 Base Moodle serveur

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

### 14.4 Publication en chaîne

```text
Cette action va mettre à jour uckk.org à partir du code Git validé.
Elle peut modifier le code serveur, les caches Moodle et possiblement la base Moodle.
Continuer ?
```

## 15. Règle sur la relation Accueil / Onglets spécialisés

L’Accueil peut proposer :

```text
Synchroniser source vers Moodle local ;
Vérifier Git ;
Publier sur serveur ;
Vérifier uckk.org.
```

Mais les détails doivent vivre dans les onglets spécialisés :

```text
Local ;
Git ;
Serveur ;
Tests ;
Historique.
```

Si une action devient trop complexe, l’Accueil doit rediriger vers l’onglet spécialisé plutôt que tout faire directement.

## 16. Règle anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
publier sur serveur sans passer par Git ;
coder un bouton serveur qui fait des modifications non annoncées ;
continuer une publication après une étape critique échouée ;
remplacer une vérification navigateur par un simple HTTP 200 ;
faire un commit sans encourager la vérification des secrets ;
faire un push sans confirmation ;
mélanger chemins locaux et chemins serveur ;
utiliser un chemin codé en dur ;
introduire un script legacy dans le workflow normal ;
faire une action recovery dans le workflow serveur normal.
```

Si un nouveau raccourci est proposé, il doit respecter la direction officielle :

```text
source locale → Moodle local → Git → source serveur → Moodle serveur → vérification navigateur
```

## 17. Résumé obligatoire

Direction officielle :

```text
source locale → Moodle local → Git → source serveur → Moodle serveur → vérification navigateur
```

Workflows normaux :

```text
Workflow local
Workflow Git
Workflow serveur
Workflow de publication en chaîne
Workflow de vérification après publication
```

Règles finales :

```text
Tester localement avant de publier.
Vérifier Git avant de publier.
Confirmer toute action serveur.
Produire un rapport pour toute action importante.
Vérifier dans le navigateur après publication.
Ne pas utiliser legacy ou recovery dans le workflow normal.
