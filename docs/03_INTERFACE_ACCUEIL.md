# 03 — Interface Accueil

## 1. Rôle de ce document

Ce document définit le premier onglet de la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Le premier onglet porte le nom officiel :

```text
Accueil
```

Ce document sert à empêcher l’IA de transformer l’accueil en écran complexe, technique ou dangereux.

Il définit :

```text
le rôle de l’accueil ;
ce qui doit y apparaître ;
ce qui ne doit jamais y apparaître ;
les boutons autorisés ;
les textes explicatifs ;
les statuts visibles ;
les règles de sécurité ;
les erreurs à éviter pendant le codage.
```

## 2. Principe central de l’accueil

L’accueil doit être simple, direct et rassurant.

Définition :

```text
Simple = l’utilisateur comprend rapidement ce qu’il peut faire.
Direct = les actions fréquentes sont accessibles sans chercher.
Rassurant = l’écran indique ce qui est local, ce qui touche le serveur, et ce qui est dangereux.
```

L’accueil n’est pas un écran pour experts.

L’accueil n’est pas un panneau de tous les scripts disponibles.

L’accueil n’est pas l’endroit des réparations.

L’accueil doit aider l’utilisateur à faire les opérations normales sans se perdre.

## 3. Utilisateur visé

L’utilisateur de l’accueil connaît le projet UCKK, mais n’est pas nécessairement expert en développement.

Conséquence :

```text
les boutons doivent être explicites ;
les mots techniques doivent être évités ou expliqués ;
les actions dangereuses doivent être absentes ou protégées ;
le résultat d’une action doit être lisible ;
l’utilisateur doit toujours savoir quoi vérifier ensuite.
```

## 4. Ce que l’accueil doit permettre

L’accueil doit permettre de répondre rapidement à ces questions :

```text
Est-ce que mon environnement local est prêt ?
Puis-je ouvrir Moodle local ?
Est-ce que mon code local est synchronisé vers Moodle local ?
Est-ce que Git contient des changements ?
Puis-je publier sur uckk.org ?
Est-ce que uckk.org répond ?
Puis-je ouvrir la Médiathèque ?
Où est le dernier rapport ?
```

Définition :

```text
Environnement local = ensemble des dossiers, chemins, outils et services nécessaires sur l’ordinateur de développement.
```

## 5. Ce que l’accueil ne doit pas faire

L’accueil ne doit pas contenir :

```text
wipe ;
rebuild ;
dump SQL ;
copie directe de tables ;
import brut ;
anciens scripts legacy ;
outils recovery ;
tests techniques profonds ;
boutons aux noms vagues ;
actions qui modifient la base Moodle sans explication.
```

Définitions :

```text
Wipe = suppression volontaire d’un ensemble de données avant reconstruction.

Rebuild = reconstruction complète d’un état à partir d’une autre source.

Dump SQL = copie brute d’une base de données ou d’une partie de base de données.

Legacy = ancien outil conservé pour référence.

Recovery / récupération = action spéciale utilisée quand l’état normal est cassé.

Test technique profond = test utile au diagnostic, mais trop spécialisé pour une opération quotidienne.
```

Règle :

```text
Si une action peut détruire, reconstruire ou contourner le workflow normal, elle ne va pas dans Accueil.
```

## 6. Structure générale de l’accueil

L’accueil doit être divisé en zones simples.

Structure officielle :

```text
1. État général
2. Actions rapides
3. Vérifications importantes
4. Dernier résultat
5. Liens utiles
```

Aucune autre zone ne doit être ajoutée sans justification documentée.

## 7. Zone 1 — État général

### 7.1 Rôle

La zone “État général” donne une lecture rapide de la situation.

Elle ne doit pas contenir de long détail technique.

Elle doit afficher des statuts courts.

### 7.2 Statuts à afficher

Statuts recommandés :

```text
Local : prêt / à vérifier / erreur
Git : propre / changements présents / erreur
Serveur : non vérifié / accessible / erreur
Médiathèque : non vérifiée / OK / à vérifier / erreur
Dernier rapport : disponible / aucun / erreur
```

Définitions :

```text
Prêt = les éléments nécessaires semblent disponibles.

À vérifier = l’application n’a pas assez d’information pour conclure.

Erreur = un problème empêche l’action ou la vérification.

Propre = aucun changement Git non enregistré n’a été détecté.

Changements présents = Git détecte des modifications.
```

### 7.3 Format visuel

Chaque statut doit être court.

Exemple :

```text
Local : prêt
Git : changements présents
Serveur : non vérifié
Médiathèque : à vérifier
```

Le détail doit être accessible dans un rapport ou dans l’onglet spécialisé, pas affiché massivement dans l’accueil.

## 8. Zone 2 — Actions rapides

### 8.1 Rôle

La zone “Actions rapides” contient les boutons utiles pour les opérations fréquentes.

Elle ne doit pas contenir toutes les actions possibles.

### 8.2 Boutons officiels

Les boutons officiels de l’accueil sont :

```text
Vérifier l’état local
Démarrer Moodle local
Synchroniser source vers Moodle local
Vérifier Git
Publier sur serveur
Vérifier uckk.org
Ouvrir la Médiathèque
Ouvrir le dernier rapport
```

Ces boutons peuvent être regroupés visuellement, mais leurs libellés doivent rester explicites.

### 8.3 Bouton : Vérifier l’état local

Libellé officiel :

```text
Vérifier l’état local
```

Description visible :

```text
Contrôle les dossiers et outils nécessaires sur l’ordinateur, sans rien modifier.
```

Action autorisée :

```text
lecture seulement
```

Cette action peut vérifier :

```text
racine de l’application ;
configuration ;
source locale ;
Moodle local ;
PHP local si nécessaire ;
dossiers reports et logs.
```

Cette action ne doit pas :

```text
modifier des fichiers ;
modifier Git ;
modifier Moodle ;
modifier le serveur.
```

Résultat attendu :

```text
Réussi — l’environnement local semble prêt.
```

ou :

```text
Échoué — un chemin requis est introuvable.
Prochaine étape : ouvrir l’onglet Local pour voir le détail.
```

### 8.4 Bouton : Démarrer Moodle local

Libellé officiel :

```text
Démarrer Moodle local
```

Description visible :

```text
Lance ou ouvre le Moodle de développement sur l’ordinateur.
```

Définition :

```text
Moodle local = Moodle utilisé pour tester sur l’ordinateur avant de publier sur le serveur.
```

Cette action peut :

```text
lancer le serveur local si l’application sait le faire ;
ouvrir l’URL locale dans le navigateur ;
indiquer que Moodle local semble déjà disponible.
```

Cette action ne doit pas :

```text
modifier le serveur ;
modifier la base Moodle serveur ;
publier du code.
```

Résultat attendu :

```text
Réussi — Moodle local est accessible.
```

ou :

```text
À vérifier dans le navigateur — Moodle local a été ouvert.
```

### 8.5 Bouton : Synchroniser source vers Moodle local

Libellé officiel :

```text
Synchroniser source vers Moodle local
```

Description visible :

```text
Copie le code source local vers le dossier exécuté par Moodle local.
```

Définitions :

```text
Source = dossier qui contient le code officiel que l’on modifie.

Dossier exécuté par Moodle = dossier que Moodle lit réellement quand il fonctionne.
```

Cette action peut modifier :

```text
le dossier Moodle local exécuté par Moodle.
```

Cette action ne doit pas modifier :

```text
Git ;
serveur ;
base Moodle serveur.
```

Confirmation :

```text
Aucune confirmation forte obligatoire si l’action modifie seulement le local.
```

Mais l’interface doit indiquer clairement :

```text
Cette action modifie seulement Moodle local.
```

Résultat attendu :

```text
Réussi — la source a été copiée vers Moodle local.
```

### 8.6 Bouton : Vérifier Git

Libellé officiel :

```text
Vérifier Git
```

Description visible :

```text
Affiche si des fichiers ont changé dans l’historique du projet.
```

Définition :

```text
Git = système qui garde l’historique des changements du projet.
```

Cette action ne doit pas :

```text
créer de commit ;
faire de push ;
modifier les fichiers.
```

Résultat attendu :

```text
Réussi — Git ne signale aucun changement.
```

ou :

```text
Réussi avec avertissements — Git signale des changements.
Prochaine étape : ouvrir l’onglet Git.
```

### 8.7 Bouton : Publier sur serveur

Libellé officiel :

```text
Publier sur serveur
```

Description visible :

```text
Met à jour uckk.org à partir du code validé.
```

Définition :

```text
Serveur = ordinateur distant qui héberge le site public uckk.org.
```

Cette action est sensible.

Elle peut modifier :

```text
le code serveur ;
le runtime serveur ;
les caches serveur ;
l’état public visible sur uckk.org.
```

Cette action ne doit pas être une boîte noire.

Avant exécution, elle doit afficher une confirmation.

Message obligatoire ou équivalent très proche :

```text
Cette action modifie uckk.org ou sa base Moodle. Continuer ?
```

L’accueil ne doit pas détailler toutes les sous-étapes.

Mais l’action doit produire un rapport.

Résultat attendu :

```text
Réussi — la publication serveur est terminée.
Prochaine étape : vérifier uckk.org dans le navigateur.
```

ou :

```text
Échoué — la publication serveur n’a pas été complétée.
Prochaine étape : ouvrir le rapport.
```

Règle importante :

```text
Si la publication serveur nécessite des choix complexes, le bouton doit rediriger vers l’onglet Serveur au lieu de lancer directement l’action.
```

### 8.8 Bouton : Vérifier uckk.org

Libellé officiel :

```text
Vérifier uckk.org
```

Description visible :

```text
Teste rapidement les pages publiques importantes.
```

Cette action ne doit pas modifier le serveur.

Elle peut vérifier :

```text
https://uckk.org
https://uckk.org/course/index.php
https://uckk.org/local/uckk/mediatheque.php
```

Résultat attendu :

```text
Réussi — uckk.org répond.
À vérifier dans le navigateur si une page charge des données après ouverture.
```

Définition :

```text
Données chargées après ouverture = données récupérées par JavaScript ou AJAX une fois la page déjà ouverte.
```

### 8.9 Bouton : Ouvrir la Médiathèque

Libellé officiel :

```text
Ouvrir la Médiathèque
```

Description visible :

```text
Ouvre la page publique de la Médiathèque dans le navigateur.
```

Cette action ne doit pas modifier de données.

Elle peut proposer deux liens si utile :

```text
Médiathèque locale
Médiathèque serveur
```

Mais le bouton principal doit rester simple.

Option recommandée :

```text
Ouvrir la Médiathèque
```

ouvre par défaut la Médiathèque serveur si l’application est en mode opération public, ou demande le choix local/serveur seulement si nécessaire.

Règle :

```text
Si un choix local/serveur est affiché, il doit être clair et non technique.
```

Exemple :

```text
Ouvrir la Médiathèque locale
Ouvrir la Médiathèque serveur
```

### 8.10 Bouton : Ouvrir le dernier rapport

Libellé officiel :

```text
Ouvrir le dernier rapport
```

Description visible :

```text
Affiche le résumé lisible de la dernière action importante.
```

Cette action ne doit rien modifier.

Si aucun rapport n’existe :

```text
Aucun rapport disponible pour le moment.
```

## 9. Zone 3 — Vérifications importantes

### 9.1 Rôle

Cette zone affiche les vérifications que l’utilisateur doit penser à faire.

Elle doit rester courte.

### 9.2 Vérifications recommandées

Exemples de vérifications à afficher :

```text
Après publication : vérifier uckk.org dans le navigateur.
Après changement Médiathèque : vérifier les cartes chargées par la page.
Avant commit : vérifier qu’aucun secret n’est inclus.
Avant action serveur : vérifier que le dernier commit est correct.
```

Définition :

```text
Secret = mot de passe, clé privée, token ou information sensible qui ne doit pas être stockée dans le code.
```

### 9.3 Format

Format recommandé :

```text
À ne pas oublier :
- vérifier dans le navigateur après une publication ;
- lire le rapport après une action serveur ;
- ne jamais publier un secret dans Git.
```

Cette zone ne doit pas devenir une documentation longue.

## 10. Zone 4 — Dernier résultat

### 10.1 Rôle

Cette zone affiche le dernier résultat d’action.

Elle doit être claire.

Elle doit permettre de comprendre ce qui vient d’arriver.

### 10.2 Format obligatoire

Le dernier résultat doit contenir :

```text
statut ;
nom de l’action ;
cible ;
résumé ;
prochaine étape ;
lien vers rapport si disponible.
```

Exemple :

```text
Statut : Réussi
Action : Vérifier uckk.org
Cible : serveur
Résumé : les pages principales répondent.
Prochaine étape : ouvrir la Médiathèque dans le navigateur.
Rapport : ouvrir
```

### 10.3 Statuts autorisés

Statuts officiels :

```text
Prêt
En cours
Réussi
Réussi avec avertissements
Échoué
Annulé
À vérifier dans le navigateur
```

Aucun autre statut visible ne doit être inventé sans mise à jour du vocabulaire obligatoire.

## 11. Zone 5 — Liens utiles

### 11.1 Rôle

Cette zone permet d’ouvrir rapidement les endroits importants.

Elle ne doit pas contenir d’actions dangereuses.

### 11.2 Liens recommandés

Liens possibles :

```text
Ouvrir Moodle local
Ouvrir uckk.org
Ouvrir Médiathèque locale
Ouvrir Médiathèque serveur
Ouvrir dossier rapports
Ouvrir dossier logs
Ouvrir configuration
Ouvrir documentation
```

### 11.3 Règle

Un lien ouvre quelque chose.

Un lien ne doit pas modifier des données.

Si un élément modifie des données, ce n’est pas un lien utile : c’est une action, et elle doit être classée selon son niveau de danger.

## 12. Actions explicitement interdites dans l’accueil

Les actions suivantes sont interdites dans l’accueil :

```text
Suppression complète de données ;
Reconstruction complète de la Médiathèque ;
Import SQL brut ;
Export depuis service public comme source de vérité ;
Copie directe de tables ;
Import media_original ;
Réparation automatique ;
Restauration depuis sauvegarde ;
Modification directe de la base Moodle ;
Exécution d’un script legacy ;
Exécution d’un script recovery.
```

Ces actions doivent aller dans :

```text
Récupération
```

ou dans un onglet spécialisé avec confirmation forte, si elles sont vraiment nécessaires.

## 13. Règle sur la Médiathèque dans l’accueil

L’accueil peut contenir seulement des actions simples liées à la Médiathèque :

```text
Ouvrir la Médiathèque
Vérifier rapidement la Médiathèque
Afficher le dernier statut Médiathèque
```

L’accueil ne doit pas contenir :

```text
Appliquer Médiathèque serveur
Rebuild Médiathèque
Wipe Médiathèque
Importer Médiathèque
Exporter Médiathèque depuis public
Réparer Médiathèque
```

Les actions normales de modification de la Médiathèque appartiennent à l’onglet :

```text
Médiathèque
```

Les actions de réparation appartiennent à l’onglet :

```text
Récupération
```

## 14. Règle sur Git dans l’accueil

L’accueil peut contenir :

```text
Vérifier Git
```

L’accueil ne doit pas contenir directement :

```text
Créer un commit Git
Envoyer les changements vers Git
Annuler des changements Git
Changer de branche Git
```

Ces actions appartiennent à l’onglet :

```text
Git
```

Raison :

```text
Git peut inclure des secrets ou des changements non voulus.
L’utilisateur doit voir les détails avant d’enregistrer ou envoyer.
```

## 15. Règle sur le serveur dans l’accueil

L’accueil peut contenir :

```text
Publier sur serveur
Vérifier uckk.org
```

Mais “Publier sur serveur” doit être protégé.

Si l’action est simple et bien définie, le bouton peut lancer le workflow de publication avec confirmation.

Si l’action nécessite des choix, le bouton doit ouvrir l’onglet Serveur.

Règle :

```text
L’accueil ne doit jamais cacher une action serveur dangereuse derrière un bouton vague.
```

## 16. Règle sur les couleurs ou niveaux visuels

Si l’interface utilise des couleurs, elles doivent suivre cette logique :

```text
Vert = vérifier ou ouvrir
Bleu = préparer ou synchroniser localement
Orange = modifier localement
Rouge = modifier le serveur ou la base Moodle
Gris = récupération, legacy ou outil avancé
```

Règle :

```text
Une action rouge ne doit jamais être présentée comme une action anodine.
```

Même si aucune couleur n’est utilisée, le texte doit indiquer le niveau de danger.

## 17. Règle sur les descriptions sous les boutons

Chaque bouton de l’accueil doit avoir une description courte.

Format :

```text
Bouton
Description en une phrase.
```

Exemple :

```text
Vérifier Git
Affiche si des fichiers ont changé dans l’historique du projet.
```

La description ne doit pas dépasser deux phrases.

Si l’action demande plus de deux phrases, elle appartient probablement à un onglet spécialisé.

## 18. Règle sur les confirmations dans l’accueil

Les actions de lecture ne demandent pas confirmation.

Exemples :

```text
Vérifier l’état local
Vérifier Git
Vérifier uckk.org
Ouvrir le dernier rapport
```

Les actions locales simples peuvent ne pas demander confirmation, mais doivent dire qu’elles modifient seulement le local.

Exemple :

```text
Cette action modifie seulement Moodle local.
```

Les actions serveur doivent demander confirmation.

Message obligatoire :

```text
Cette action modifie uckk.org ou sa base Moodle. Continuer ?
```

Les actions recovery ne doivent pas être dans l’accueil.

## 19. Règle sur les erreurs dans l’accueil

Une erreur affichée dans l’accueil doit être compréhensible.

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
Cause probable : Moodle local ne répond pas.
Prochaine étape : lancer “Démarrer Moodle local”, puis réessayer.
Détail technique : http://localhost:8000 ne répond pas.
```

L’accueil ne doit pas afficher seulement :

```text
Exception
Exit code
Stack trace
SQL error
```

Définition :

```text
Stack trace = détail technique listant les appels internes d’un programme au moment d’une erreur.
```

Une stack trace peut aller dans le log technique, pas comme message principal d’accueil.

## 20. Règle sur les rapports depuis l’accueil

Après une action importante lancée depuis l’accueil, l’utilisateur doit pouvoir ouvrir le rapport.

Actions qui doivent produire un rapport :

```text
Synchroniser source vers Moodle local ;
Publier sur serveur ;
Vérifier uckk.org ;
toute action qui échoue ;
toute action qui donne un avertissement.
```

Le rapport doit être sauvegardé dans le dossier officiel des rapports.

L’accueil doit afficher un lien :

```text
Ouvrir le rapport
```

si un rapport existe.

## 21. Règle sur la taille de l’accueil

L’accueil ne doit pas devenir trop long.

Règle :

```text
Si l’utilisateur doit faire défiler longtemps pour voir les actions principales, l’accueil est trop chargé.
```

L’accueil doit contenir peu d’actions.

Les détails doivent aller dans les onglets spécialisés.

## 22. Règle sur le mode expert

L’accueil ne doit pas avoir de mode expert au départ.

Définition :

```text
Mode expert = affichage qui expose des commandes ou options techniques avancées.
```

Si un mode expert est un jour ajouté, il ne doit pas modifier la simplicité de l’accueil normal.

Les outils experts doivent aller dans les onglets spécialisés ou récupération.

## 23. Règle sur les commandes visibles

L’accueil ne doit pas afficher les commandes brutes comme contenu principal.

Il peut afficher une commande dans le détail technique ou le rapport.

Exemple à éviter dans l’accueil :

```text
ssh ubuntu@57.129.115.159 "cd /opt/uckk/uckk-moodle && git pull"
```

Exemple correct dans l’accueil :

```text
Publication serveur en cours.
Détail technique disponible dans le rapport.
```

## 24. Règle sur l’état initial

Au premier lancement, l’accueil doit afficher un état initial compréhensible.

Exemple :

```text
État général
Local : non vérifié
Git : non vérifié
Serveur : non vérifié
Médiathèque : non vérifiée
Dernier rapport : aucun
```

Il ne doit pas afficher une erreur simplement parce qu’aucune vérification n’a encore été faite.

Définition :

```text
Non vérifié = l’application n’a pas encore contrôlé cet élément.
```

## 25. Règle sur l’absence de configuration

Si la configuration est absente ou invalide, l’accueil doit l’expliquer simplement.

Message recommandé :

```text
La configuration de l’application est introuvable ou incomplète.
Prochaine étape : ouvrir l’onglet Configuration ou créer le fichier de configuration.
```

L’accueil ne doit pas planter silencieusement.

Définition :

```text
Planter = arrêter de fonctionner de manière inattendue.
```

## 26. Règle sur l’accès aux autres onglets

L’accueil peut proposer des raccourcis vers les onglets spécialisés.

Exemples :

```text
Voir détails Local
Voir détails Git
Voir détails Serveur
Voir détails Médiathèque
Voir Historique
```

Ces raccourcis ne sont pas des actions dangereuses.

Ils servent seulement à naviguer.

## 27. Contrat de contenu minimal

L’accueil doit au minimum contenir :

```text
titre de l’application ;
zone État général ;
zone Actions rapides ;
zone Dernier résultat ;
accès au dernier rapport ;
accès aux onglets spécialisés.
```

Le titre officiel est :

```text
UCKK Ops Console
```

## 28. Contrat de comportement minimal

Au minimum, l’accueil doit permettre :

```text
de charger la configuration ;
d’afficher un état initial ;
de lancer une vérification locale ;
d’afficher un résultat ;
d’ouvrir un rapport si disponible ;
de naviguer vers les onglets spécialisés.
```

Même si certaines actions ne sont pas encore implémentées, l’accueil ne doit pas inventer des comportements.

Si une action n’est pas disponible, afficher :

```text
Action non disponible pour le moment.
```

Mais ne pas créer de faux succès.

## 29. Règle anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
ajouter des boutons non documentés dans l’accueil ;
mettre des outils legacy dans l’accueil ;
mettre des outils recovery dans l’accueil ;
remplacer les libellés officiels par des mots anglais ;
cacher une action serveur derrière un bouton vague ;
afficher des sorties techniques comme résultat principal ;
supprimer les descriptions sous les boutons ;
mélanger les actions locales et serveur.
```

Si l’IA estime qu’un nouveau bouton est nécessaire, elle doit proposer une modification de ce document avant de le coder.

## 30. Résumé obligatoire

L’onglet Accueil doit rester :

```text
simple ;
direct ;
rassurant ;
orienté actions fréquentes ;
sans jargon non défini ;
sans outil dangereux ;
sans script legacy ;
sans outil recovery.
```

Boutons officiels :

```text
Vérifier l’état local
Démarrer Moodle local
Synchroniser source vers Moodle local
Vérifier Git
Publier sur serveur
Vérifier uckk.org
Ouvrir la Médiathèque
Ouvrir le dernier rapport
```

Zones officielles :

```text
État général
Actions rapides
Vérifications importantes
Dernier résultat
Liens utiles
```

Règle finale :

```text
Si une action peut casser, reconstruire, supprimer ou contourner le workflow normal, elle ne va pas dans Accueil.

## Mise à jour multi-façades — 2026-09-24

Le bouton d'accueil réellement implémenté **Préparer local et ouvrir Moodle** est désormais le workflow quotidien recommandé pour le développement du switcher.

Il exécute, après confirmation unique :

```text
vérifier configuration
→ vérifier chemins locaux
→ synchroniser source vers runtime Moodle local
→ mettre à jour Moodle local
→ purger caches
→ démarrer Moodle local
→ ouvrir UCKK
```

L'upgrade est local seulement et peut modifier la base Moodle locale. Les boutons spécialisés **Ouvrir UCKK**, **Ouvrir UCC**, **Ouvrir Math** et **Tester switcher UCKK / UCC / Math** restent dans l'onglet Local/Tests afin de ne pas surcharger Accueil.

Voir `docs/13_SWITCHER_MULTI_FACADES.md`.



## Mise à jour — diagnostic CLI local avant upgrade

La chaîne **Préparer local et ouvrir Moodle** exécute désormais un diagnostic CLI Moodle
avant la synchronisation/upgrade. La séquence distingue explicitement la racine code Moodle
du webroot HTTP et arrête la chaîne si `admin/cli/upgrade.php`, `admin/cli/purge_caches.php`
ou PHP CLI ne peuvent pas être résolus.

En cas d'échec, le résultat composite conserve le résultat complet de l'étape fautive.
L'interface affiche ses sous-étapes, la commande, le dossier courant, le code de sortie,
STDOUT et STDERR.
