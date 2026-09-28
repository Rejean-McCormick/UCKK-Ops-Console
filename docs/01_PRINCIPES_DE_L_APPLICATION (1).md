# 01 — Principes de l’application

## 1. Rôle de ce document

Ce document définit les principes obligatoires de la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il sert à guider le codage.

Il sert aussi à empêcher l’IA de dériver.

Dans ce document, “dériver” signifie :

```text
changer le but de l’application ;
ajouter des fonctions non demandées ;
réutiliser un ancien script dangereux comme s’il était normal ;
inventer une architecture parallèle ;
mettre trop de complexité dans l’écran principal ;
employer des mots techniques non expliqués ;
faire dépendre un workflow normal d’une opération de réparation.
```

Ce document n’est pas une présentation marketing.

Ce document n’est pas une liste de tâches.

Ce document est un contrat de construction.

## 2. Décision principale

UCKK Ops Console est une nouvelle application indépendante.

Elle ne doit pas être une continuation directe du vieux dossier :

```text
C:\mycode\UCKK\uckk-moodle\tools\uckk-ops
```

Les anciens outils peuvent servir de matière première.

Mais la nouvelle application doit être organisée, expliquée et sécurisée selon ses propres règles.

Règle :

```text
L’ancien code peut être consulté.
L’ancien code ne dicte pas l’architecture de la nouvelle application.
```

## 3. But de l’application

Le but de UCKK Ops Console est de permettre à l’utilisateur de piloter les opérations courantes du projet UCKK sans devoir retenir des commandes techniques ou choisir entre plusieurs scripts ambigus.

L’application doit aider à faire ces opérations :

```text
travailler localement ;
vérifier l’état du projet ;
synchroniser le code vers Moodle local ;
préparer et envoyer des changements Git ;
publier sur uckk.org ;
gérer la Médiathèque ;
appliquer certaines données Moodle ;
lancer des tests simples ;
lire des rapports clairs ;
utiliser des outils de récupération seulement quand c’est nécessaire.
```

Définition :

```text
Piloter = lancer une action, voir ce qu’elle fait, comprendre le résultat, puis savoir quoi faire ensuite.
```

L’application doit être un outil de pilotage, pas seulement un lanceur de scripts.

## 4. Ce que l’application n’est pas

UCKK Ops Console n’est pas :

```text
un terminal déguisé ;
une collection de vieux scripts ;
un panneau d’administration Moodle complet ;
un outil de développement général ;
un outil de sauvegarde complet ;
un outil de manipulation directe de base de données ;
un endroit où placer toutes les idées futures.
```

Définition :

```text
Terminal = fenêtre où l’on tape des commandes techniques directement.
```

L’application peut lancer des commandes, mais elle ne doit pas obliger l’utilisateur à comprendre chaque commande pour faire une opération normale.

## 5. Utilisateur cible

L’utilisateur cible connaît le projet UCKK, mais n’est pas nécessairement expert en développement.

Conséquence :

```text
L’application doit expliquer les actions.
L’application doit éviter le jargon.
L’application doit afficher des résultats lisibles.
L’application doit empêcher les actions dangereuses involontaires.
```

Définition :

```text
Jargon = mot technique utilisé comme si tout le monde le comprenait déjà.
```

Exemple de jargon à éviter seul :

```text
dry-run
runtime
cache
DB
deploy
smoke test
rollback
```

Ces mots peuvent être utilisés seulement s’ils sont expliqués dans l’interface ou dans la documentation.

## 6. Principe de simplicité du premier onglet

Le premier onglet doit rester simple, direct et rassurant.

Il doit servir aux opérations les plus fréquentes.

Il ne doit pas exposer les outils dangereux.

Il ne doit pas devenir un tableau de bord saturé.

Règle :

```text
Si une action demande une explication longue, elle ne va probablement pas dans le premier onglet.
```

Le premier onglet doit privilégier des actions comme :

```text
vérifier l’état local ;
démarrer Moodle local ;
synchroniser localement ;
vérifier Git ;
publier sur serveur ;
vérifier uckk.org ;
ouvrir la Médiathèque.
```

Le premier onglet ne doit pas contenir :

```text
wipe ;
rebuild ;
dump SQL ;
copie directe de tables ;
scripts legacy ;
scripts recovery ;
outils de test technique profond.
```

Définitions :

```text
Wipe = suppression volontaire d’un ensemble de données avant reconstruction.

Rebuild = reconstruction complète d’un état à partir d’une autre source.

Dump SQL = copie brute d’une base de données ou d’un morceau de base de données.

Legacy = ancien outil conservé pour référence.

Recovery = outil de réparation utilisé quand l’état normal est cassé.
```

## 7. Principe des onglets spécialisés

Les onglets après l’accueil peuvent être plus détaillés.

Mais ils doivent rester organisés par domaine réel.

Un domaine réel est une zone de travail que l’utilisateur peut nommer simplement.

Domaines prévus :

```text
Local ;
Git ;
Serveur ;
Médiathèque ;
Données Moodle ;
Tests ;
Historique ;
Récupération.
```

Chaque onglet doit répondre à une question claire.

Exemples :

```text
Local = que se passe-t-il sur mon ordinateur ?
Git = quels changements sont prêts à être enregistrés ?
Serveur = qu’est-ce qui va modifier uckk.org ?
Médiathèque = comment ajouter ou publier des références ?
Récupération = comment réparer un état cassé ?
```

Un onglet ne doit pas mélanger des actions sans lien clair.

## 8. Principe “un workflow normal = un chemin officiel”

Un workflow normal est une suite d’étapes que l’utilisateur peut utiliser régulièrement.

Définition :

```text
Workflow = suite officielle d’étapes pour accomplir une opération.
```

Chaque workflow normal doit avoir un seul chemin officiel.

Exemple pour la Médiathèque :

```text
manifeste → simulation → appliquer → vérifier
```

L’application ne doit pas proposer plusieurs chemins normaux pour la même opération.

Mauvais exemple :

```text
Ajouter une référence Médiathèque par manifeste.
Ajouter une référence Médiathèque par ancien import /play.
Ajouter une référence Médiathèque par export public.
Ajouter une référence Médiathèque par copie SQL.
```

Bon exemple :

```text
Ajouter une référence Médiathèque par manifeste.
Les autres méthodes sont classées legacy ou recovery.
```

## 9. Principe de source de vérité

Une source de vérité est l’endroit officiel où une information doit être modifiée.

Définition :

```text
Source de vérité = endroit principal et fiable d’où part une donnée.
```

Si plusieurs endroits peuvent modifier la même donnée, l’application devient fragile.

Règle :

```text
Chaque domaine doit avoir une source de vérité claire.
```

Pour la Médiathèque, la source de vérité normale doit être un manifeste.

Définition :

```text
Manifeste = fichier source qui liste les entrées de la Médiathèque de manière lisible et versionnée.
```

La base Moodle n’est pas la source principale d’édition de la Médiathèque.

Elle est la cible où les données sont publiées pour que Moodle les utilise.

Définition :

```text
Cible = endroit où une donnée est envoyée ou appliquée.
```

## 10. Principe “simulation avant modification”

Toute action qui peut modifier des données importantes doit avoir une simulation quand c’est possible.

Définition :

```text
Simulation = action qui montre ce qui serait fait, sans modifier les données.
```

Le mot technique équivalent est :

```text
dry-run
```

Mais dans l’interface, le mot principal doit être :

```text
Simulation
```

Règle :

```text
Pour une action complexe ou dangereuse, l’utilisateur doit pouvoir voir le résultat prévu avant d’appliquer.
```

Exemples d’actions qui doivent avoir une simulation :

```text
appliquer Médiathèque localement ;
appliquer Médiathèque sur serveur ;
appliquer données Moodle ;
modifier plusieurs entrées dans la base Moodle.
```

## 11. Principe “appliquer” signifie écrire vraiment

Le mot “appliquer” doit être réservé aux actions qui écrivent vraiment des changements.

Définition :

```text
Appliquer = modifier réellement un fichier, une base de données, un état Git ou le serveur.
```

Le mot technique équivalent est :

```text
apply
```

Mais dans l’interface, le mot principal doit être :

```text
Appliquer
```

Une action “Appliquer” doit dire clairement :

```text
ce qui sera modifié ;
si la cible est locale ou serveur ;
si la base Moodle est touchée ;
s’il existe un rapport ;
quelle vérification faire après.
```

## 12. Principe de séparation local / serveur

L’application doit toujours distinguer :

```text
local ;
serveur.
```

Définition :

```text
Local = l’ordinateur de développement.
Serveur = l’ordinateur distant qui héberge uckk.org.
```

Une action locale ne doit pas modifier le serveur.

Une action serveur ne doit jamais être confondue avec une action locale.

Chaque bouton qui touche le serveur doit l’indiquer clairement.

Exemples de libellés corrects :

```text
Simulation Médiathèque locale
Appliquer Médiathèque localement
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
```

Mauvais libellé :

```text
Appliquer Médiathèque
```

Ce libellé est mauvais parce qu’il ne dit pas si l’action vise local ou serveur.

## 13. Principe de protection du serveur

Le serveur public est sensible.

Définition :

```text
Serveur public = machine qui héberge le vrai site accessible par les visiteurs.
```

Dans ce projet, le serveur public est :

```text
uckk.org
```

Toute action qui modifie `uckk.org` doit demander confirmation.

Message de confirmation recommandé :

```text
Cette action modifie uckk.org ou sa base Moodle. Continuer ?
```

L’application ne doit pas permettre une modification serveur par accident.

## 14. Principe de protection de la base Moodle

La base Moodle contient l’état actif de Moodle.

Définition :

```text
Base Moodle = base de données utilisée par Moodle pour stocker les cours, activités, réglages, utilisateurs, références et autres données actives.
```

La base Moodle ne doit jamais être modifiée silencieusement.

Si une action modifie la base Moodle, l’interface doit le dire.

Exemples :

```text
Cette action écrit dans la base Moodle locale.
Cette action écrit dans la base Moodle serveur.
```

Les actions qui suppriment ou reconstruisent des données doivent être classées comme récupération.

## 15. Principe de non-destruction par défaut

Par défaut, l’application doit éviter de supprimer des données.

Une action normale doit privilégier :

```text
créer ce qui manque ;
mettre à jour ce qui existe ;
laisser intact ce qui n’est pas concerné.
```

Les suppressions doivent être explicites.

Définition :

```text
Explicite = visible, annoncé et confirmé.
```

Une action qui supprime plusieurs données ne doit pas être disponible dans le premier onglet.

Elle doit être dans Récupération ou dans un écran spécialisé avec confirmation forte.

## 16. Principe de rapport lisible

Une action importante doit produire un rapport lisible.

Définition :

```text
Rapport = résumé compréhensible d’une action.
```

Un rapport doit répondre à ces questions :

```text
Quelle action a été lancée ?
Quelle était la cible ?
Est-ce que c’était une simulation ou une vraie modification ?
Qu’est-ce qui a changé ?
Y a-t-il des avertissements ?
Y a-t-il des erreurs ?
Que faut-il vérifier ensuite ?
```

Un rapport ne doit pas être seulement une sortie technique brute.

Définition :

```text
Sortie technique brute = texte produit par un programme, souvent difficile à lire pour un non-expert.
```

## 17. Principe de log technique séparé

Un log est différent d’un rapport.

Définition :

```text
Log = journal technique détaillé d’une action.
```

Le log peut contenir :

```text
commandes exécutées ;
codes de retour ;
sorties complètes ;
détails d’erreur ;
timestamps.
```

Définition :

```text
Timestamp = date et heure enregistrées avec un événement.
```

L’utilisateur doit voir un résumé lisible dans le rapport.

Le log sert à diagnostiquer quand le rapport ne suffit pas.

## 18. Principe d’erreur compréhensible

Une erreur doit être expliquée simplement.

Mauvais message :

```text
Process exited with code 1.
```

Bon message :

```text
L’action a échoué.
La connexion au serveur n’a pas fonctionné.
Vérifie que la connexion SSH est disponible, puis relance “Tester connexion serveur”.
Détail technique : code 1.
```

Règle :

```text
Une erreur doit toujours dire ce qui a échoué et quoi faire ensuite.
```

## 19. Principe d’anti-duplication

L’application ne doit pas contenir plusieurs outils normaux qui font presque la même chose.

Définition :

```text
Duplication = plusieurs morceaux de code ou plusieurs outils qui accomplissent la même tâche avec de petites différences.
```

La duplication est dangereuse parce qu’elle crée de la confusion.

Exemple de confusion à éviter :

```text
un outil importe 128 références ;
un autre outil n’en voit que 5 ;
l’utilisateur ne sait pas lequel utiliser.
```

Règle :

```text
Quand deux outils font presque la même chose, il faut choisir un outil normal et classer l’autre comme legacy, recovery ou test.
```

## 20. Principe legacy

Un outil legacy est un ancien outil conservé pour référence.

Définition :

```text
Legacy = ancien outil qui peut aider à comprendre l’historique, mais qui ne doit pas être utilisé dans le workflow normal.
```

Un outil legacy :

```text
ne doit pas apparaître dans l’accueil ;
ne doit pas être présenté comme chemin recommandé ;
ne doit pas être appelé automatiquement par un module normal ;
doit être clairement identifié comme ancien.
```

## 21. Principe recovery

Un outil recovery sert à réparer une situation cassée.

Définition :

```text
Recovery / récupération = action spéciale utilisée seulement quand l’état normal est cassé.
```

Une action recovery :

```text
est dangereuse par défaut ;
doit être isolée ;
doit demander confirmation forte ;
doit créer ou exiger une sauvegarde si elle modifie des données ;
doit produire un rapport.
```

Une action recovery ne doit pas être utilisée comme solution quotidienne.

## 22. Principe de vocabulaire contrôlé

L’application doit utiliser un vocabulaire stable.

Un même concept doit toujours avoir le même nom.

Exemple :

```text
Simulation
```

ne doit pas être parfois nommé :

```text
dry-run
prévisualisation
test d’écriture
mode no-write
```

Le vocabulaire visible doit être français.

Les mots techniques anglais peuvent être mentionnés comme équivalents, mais ne doivent pas remplacer le mot français principal.

Exemple correct :

```text
Simulation (dry-run)
```

Exemple moins bon :

```text
Dry-run
```

## 23. Principe de boutons explicites

Un bouton doit dire clairement ce qu’il fait.

Un bouton ne doit pas être nommé seulement :

```text
Run
Go
Sync
Apply
Fix
Import
```

Ces mots sont trop vagues.

Bonnes formes :

```text
Vérifier les chemins locaux
Synchroniser source vers Moodle local
Simulation Médiathèque serveur
Appliquer Médiathèque serveur
Purger caches serveur
```

Règle :

```text
Le nom du bouton doit inclure la cible quand la cible est importante.
```

## 24. Principe de résultat visible

Après une action, l’utilisateur doit voir un résultat.

Un résultat minimal doit dire :

```text
réussi ;
réussi avec avertissements ;
échoué ;
à vérifier dans le navigateur.
```

L’application ne doit pas simplement fermer une fenêtre ou afficher une sortie technique sans conclusion.

Exemple :

```text
OK — 128 références Médiathèque trouvées sur serveur.
À vérifier dans le navigateur : https://uckk.org/local/uckk/mediatheque.php
```

## 25. Principe de vérification navigateur

Certaines choses doivent être vérifiées dans le navigateur, pas seulement par commande.

Définition :

```text
Navigateur = application comme Chrome, Edge ou Firefox utilisée pour voir le site comme un utilisateur.
```

Exemple important :

```text
La page Médiathèque peut répondre HTTP 200 mais charger ses cartes par JavaScript ensuite.
```

Définition :

```text
HTTP 200 = réponse technique indiquant qu’une page a répondu.
```

Cela ne garantit pas toujours que tout ce que l’utilisateur voit fonctionne.

L’application doit distinguer :

```text
test technique ;
vérification navigateur.
```

## 26. Principe de configuration centralisée

Les chemins, URLs et paramètres doivent être dans la configuration.

Définition :

```text
Configuration = fichier de paramètres lu par l’application.
```

Les chemins ne doivent pas être codés directement dans plusieurs fichiers.

Définition :

```text
Codé en dur = écrit directement dans le code au lieu d’être lu depuis la configuration.
```

Règle :

```text
Si une valeur peut changer selon la machine ou le serveur, elle va dans config.
```

Exemples :

```text
chemin de Moodle local ;
chemin du repo source ;
chemin serveur ;
URL locale ;
URL serveur ;
chemin du manifeste Médiathèque.
```

## 27. Principe de responsabilité unique

Chaque fichier de code doit avoir une responsabilité claire.

Définition :

```text
Responsabilité = rôle principal d’un fichier ou d’un module.
```

Exemple :

```text
un module Local gère le local ;
un module Serveur gère le serveur ;
un module Médiathèque gère la Médiathèque ;
un module Rapports écrit les rapports.
```

Un fichier ne doit pas devenir un fourre-tout.

Définition :

```text
Fourre-tout = fichier qui contient des fonctions sans lien clair.
```

## 28. Principe de neutralité des anciens scripts

Les anciens scripts ne doivent pas être supprimés immédiatement sans décision.

Mais ils ne doivent pas contrôler le design.

Ils doivent être classés.

Classes officielles :

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

Un script non classé ne doit pas être appelé par l’interface principale.

## 29. Principe de minimum utile

L’application doit faire ce qui est utile pour les opérations UCKK.

Elle ne doit pas devenir une plateforme générale qui fait tout.

Avant d’ajouter une fonction, vérifier :

```text
Est-ce une opération UCKK réelle ?
Est-ce fréquent ou nécessaire ?
Est-ce que cela appartient à cette application ?
Est-ce que le vocabulaire est défini ?
Est-ce que l’action est dangereuse ?
Dans quel onglet cela doit aller ?
```

Si la réponse n’est pas claire, la fonction ne doit pas être ajoutée.

## 30. Principe de traçabilité

Les actions importantes doivent laisser une trace.

Définition :

```text
Traçabilité = capacité de savoir ce qui a été fait, quand, sur quelle cible et avec quel résultat.
```

Une trace peut être :

```text
un rapport ;
un log ;
un commit Git ;
un message de résultat.
```

La traçabilité est obligatoire pour :

```text
actions serveur ;
actions Médiathèque ;
actions données Moodle ;
actions recovery ;
actions Git.
```

## 31. Principe de “pas de magie invisible”

L’application peut simplifier les opérations.

Mais elle ne doit pas cacher les actions importantes.

Définition :

```text
Magie invisible = action importante lancée sans que l’utilisateur comprenne ce qui est modifié.
```

Exemple à éviter :

```text
un bouton “Réparer” qui supprime et reconstruit des tables sans explication claire.
```

Exemple acceptable :

```text
un bouton “Reconstruire Médiathèque depuis external_work” dans Récupération, avec explication, sauvegarde et confirmation.
```

## 32. Principe de langue

Les textes visibles pour l’utilisateur doivent être en français.

Exemples :

```text
boutons ;
messages ;
rapports ;
confirmations ;
descriptions ;
erreurs lisibles.
```

Le code peut utiliser des noms anglais si cela facilite la cohérence technique.

Mais le vocabulaire visible doit rester français.

## 33. Principe de refus d’un workflow dangereux

Si une demande de codage contredit les principes de sécurité, l’IA doit refuser de l’intégrer comme workflow normal.

Elle peut proposer une alternative dans :

```text
recovery ;
legacy ;
test ;
documentation.
```

Exemple :

```text
Demande : mettre un bouton wipe dans l’accueil.
Réponse attendue : ne pas le mettre dans l’accueil ; proposer Récupération avec confirmation forte.
```

## 34. Résumé des règles non négociables

Les règles suivantes sont obligatoires :

```text
L’application est indépendante.
Le premier onglet reste simple.
Les actions dangereuses sont isolées.
Le serveur est protégé par confirmation.
La base Moodle est protégée par confirmation.
La simulation précède les modifications complexes.
Les rapports sont lisibles.
Les logs sont séparés des rapports.
Les anciens scripts sont classés.
Un workflow normal ne dépend pas d’un outil recovery.
La Médiathèque normale part d’un manifeste.
Le vocabulaire visible est défini.
Les chemins viennent de la configuration.
Chaque module a une responsabilité claire.
```

## 35. Critère final

Une personne non experte en développement doit pouvoir ouvrir UCKK Ops Console et comprendre :

```text
où elle est ;
ce qu’elle peut faire ;
ce qui est local ;
ce qui touche le serveur ;
ce qui est dangereux ;
ce qui a réussi ;
ce qui a échoué ;
quoi vérifier ensuite.
```

Si l’application ne permet pas cela, elle ne respecte pas ce document.
