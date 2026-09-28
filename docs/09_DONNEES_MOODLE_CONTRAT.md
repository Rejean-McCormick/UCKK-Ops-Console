# 09 — Contrat Données Moodle

## 1. Rôle de ce document

Ce document définit le contrat des Données Moodle dans la nouvelle application :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Il couvre les données Moodle qui ne sont pas la Médiathèque.

La Médiathèque est définie séparément dans :

```text
docs/08_MEDIATHEQUE_CONTRAT.md
```

Ce document sert à empêcher l’IA de coder des actions qui modifient Moodle sans source claire, sans simulation, sans confirmation ou sans rapport.

Il définit :

```text
ce qu’on appelle Données Moodle ;
quelles données sont concernées ;
quelle est la source de vérité ;
quel est le workflow normal ;
quelles actions sont autorisées ;
quelles actions sont interdites ;
comment séparer local et serveur ;
comment produire les rapports ;
comment éviter les modifications silencieuses de la base Moodle.
```

Ce document est un contrat de construction.

Il n’est pas une liste de tâches.

## 2. Définition de Données Moodle

Nom visible officiel :

```text
Données Moodle
```

Définition :

```text
Données Moodle = informations enregistrées dans Moodle, comme les catégories, cours, programmes, parcours, rôles, permissions, badges, compétences, modèles et rapports.
```

Les Données Moodle sont stockées dans la base Moodle après application.

Définition :

```text
Base Moodle = base de données utilisée par Moodle pour stocker son état actif.
```

Règle :

```text
Modifier un fichier source ne modifie pas automatiquement Moodle.
Il faut appliquer ce fichier dans Moodle.
```

## 3. Ce que ce document ne couvre pas

Ce document ne couvre pas :

```text
Médiathèque ;
fichiers médias locaux ;
références externes de la Médiathèque ;
réparation de base de données ;
dump SQL ;
copie directe de tables ;
administration complète de Moodle ;
gestion manuelle des utilisateurs.
```

La Médiathèque appartient à son propre contrat.

Les réparations appartiennent à :

```text
Récupération
```

Définition :

```text
Récupération = action spéciale utilisée quand l’état normal est cassé.
```

## 4. Principe central

Le workflow normal des Données Moodle est :

```text
fichier source → validation → simulation → appliquer → vérifier
```

Cette règle est obligatoire.

Elle signifie :

```text
1. Les données sont décrites dans des fichiers source.
2. L’application valide les fichiers.
3. L’application simule ce qui serait changé.
4. L’application applique seulement après confirmation.
5. L’application vérifie Moodle après application.
```

Règle :

```text
Aucune donnée Moodle importante ne doit être modifiée silencieusement.
```

## 5. Source de vérité

La source de vérité normale des Données Moodle est un ensemble de fichiers JSON.

Définition :

```text
Source de vérité = endroit principal et fiable d’où part une donnée.
```

Définition :

```text
Fichier JSON = fichier texte structuré qui décrit des données.
```

Les fichiers JSON décrivent l’état prévu.

La base Moodle reçoit cet état après application.

Donc :

```text
Fichiers JSON = source de vérité.
Base Moodle = cible d’application.
```

Définition :

```text
Cible = endroit où une donnée est envoyée ou appliquée.
```

## 6. Dossier source des Données Moodle

Le dossier source conceptuel des Données Moodle peut être :

```text
academic_registry_json
```

ou un autre chemin défini dans la configuration.

Règle :

```text
Le chemin exact des fichiers de données Moodle doit venir de la configuration.
Il ne doit pas être codé en dur dans les modules.
```

Définition :

```text
Codé en dur = écrit directement dans le code au lieu d’être lu depuis la configuration.
```

Si le chemin change, le code ne doit pas être modifié.

La configuration doit être modifiée.

## 7. Données concernées

Les domaines de Données Moodle concernés sont :

```text
catégories ;
cours ;
programmes ;
parcours ;
rôles ;
permissions ;
compétences ;
badges ;
modèles ;
rapports.
```

Chaque domaine doit avoir une signification claire.

## 8. Catégories Moodle

Nom visible officiel :

```text
Catégories Moodle
```

Définition :

```text
Catégorie Moodle = groupe qui organise des cours dans Moodle.
```

Exemple conceptuel :

```text
une catégorie peut regrouper les cours d’un programme ou d’un secteur.
```

Règle :

```text
Une catégorie doit avoir un identifiant stable.
```

Définition :

```text
Identifiant stable = valeur qui permet de reconnaître la même donnée dans le temps.
```

## 9. Cours Moodle

Nom visible officiel :

```text
Cours Moodle
```

Définition :

```text
Cours Moodle = espace Moodle contenant des activités, ressources ou contenus pédagogiques.
```

Un cours peut avoir :

```text
un nom complet ;
un nom court ;
un identifiant stable ;
une catégorie ;
un format ;
un résumé ;
un état visible ou caché.
```

Règle :

```text
Un cours ne doit pas être recréé en double si son identifiant stable existe déjà.
```

## 10. Programmes

Nom visible officiel :

```text
Programmes
```

Définition :

```text
Programme = structure UCKK qui regroupe des parcours, cours ou objectifs pédagogiques.
```

Un programme peut servir à organiser une offre pédagogique plus large qu’un seul cours.

Règle :

```text
Un programme doit être appliqué de manière contrôlée, avec simulation avant écriture dans Moodle.
```

## 11. Parcours

Nom visible officiel :

```text
Parcours
```

Définition :

```text
Parcours = chemin organisé à l’intérieur d’un programme.
```

Un parcours peut indiquer une progression, une spécialisation ou une séquence.

Règle :

```text
Un parcours doit être lié à un programme connu ou signaler une erreur de validation.
```

## 12. Rôles

Nom visible officiel :

```text
Rôles
```

Définition :

```text
Rôle = ensemble de permissions attribuées à un utilisateur dans Moodle.
```

Exemples conceptuels :

```text
enseignant ;
étudiant ;
gestionnaire ;
rôle UCKK spécifique.
```

Règle :

```text
Les rôles sont sensibles parce qu’ils influencent les droits des utilisateurs.
```

Toute action qui applique des rôles doit être clairement confirmée.

## 13. Permissions

Nom visible officiel :

```text
Permissions
```

Définition :

```text
Permission = droit d’effectuer une action dans Moodle.
```

Exemple :

```text
voir une page ;
modifier une activité ;
gérer des données ;
accéder à un rapport.
```

Les permissions peuvent avoir un effet important sur la sécurité.

Règle :

```text
Une modification de permissions doit produire un rapport détaillé.
```

## 14. Compétences

Nom visible officiel :

```text
Compétences
```

Définition :

```text
Compétence = savoir, capacité ou objectif pédagogique que Moodle peut suivre.
```

Une compétence doit avoir :

```text
un identifiant stable ;
un nom ;
un statut visible ou non ;
une structure cohérente.
```

## 15. Badges

Nom visible officiel :

```text
Badges
```

Définition :

```text
Badge = reconnaissance attribuable à un utilisateur selon des critères.
```

Définition :

```text
Critère = condition à remplir pour obtenir un badge.
```

Règle :

```text
Un badge doit avoir des critères compréhensibles avant application.
```

## 16. Modèles

Nom visible officiel :

```text
Modèles
```

Définition :

```text
Modèle = structure de départ utilisée pour créer ou configurer un élément Moodle.
```

Exemples :

```text
modèle de cours ;
modèle d’activité ;
modèle d’archive ;
modèle de défi ;
modèle d’assemblée.
```

Règle :

```text
Un modèle ne doit pas être appliqué comme une donnée réelle sans que l’action le dise clairement.
```

## 17. Rapports Moodle

Nom visible officiel :

```text
Rapports Moodle
```

Définition :

```text
Rapport Moodle = vue ou outil qui présente des informations calculées ou regroupées depuis Moodle.
```

Ne pas confondre avec :

```text
rapport de l’Ops Console.
```

Définition :

```text
Rapport de l’Ops Console = résumé lisible d’une action lancée par l’application.
```

Règle :

```text
Quand le mot Rapport est utilisé, préciser le contexte si une confusion est possible.
```

## 18. Workflow normal local

Le workflow local des Données Moodle est :

```text
1. Ouvrir ou modifier les fichiers JSON.
2. Vérifier fichiers JSON Moodle.
3. Lancer une simulation locale.
4. Lire le rapport de simulation.
5. Appliquer localement.
6. Vérifier Moodle local.
7. Vérifier dans le navigateur si la donnée affecte une page visible.
```

Règle :

```text
On ne doit pas appliquer localement si les fichiers JSON sont invalides.
```

## 19. Workflow normal serveur

Le workflow serveur des Données Moodle est :

```text
1. Vérifier les fichiers JSON.
2. Valider localement si possible.
3. Enregistrer les changements dans Git.
4. Publier le code ou les fichiers nécessaires sur serveur.
5. Lancer une simulation serveur.
6. Lire le rapport de simulation serveur.
7. Appliquer serveur avec confirmation.
8. Vérifier Moodle serveur.
9. Vérifier dans le navigateur si nécessaire.
10. Lire le rapport final.
```

Règle :

```text
On ne doit pas appliquer des données Moodle serveur depuis une source non versionnée ou ambiguë.
```

Définition :

```text
Versionné = enregistré dans Git.
```

Définition :

```text
Ambigu = pas assez clair pour agir en sécurité.
```

## 20. Boutons officiels de l’onglet Données Moodle

Les boutons officiels sont :

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

Ces boutons peuvent être regroupés par domaine.

Aucun bouton vague ne doit être ajouté.

Boutons interdits :

```text
Apply
Import
Sync DB
Fix Moodle
Run seed
Deploy data
```

## 21. Boutons avancés possibles

Certains domaines peuvent être ajoutés dans l’onglet Données Moodle si le code les supporte clairement.

Boutons possibles :

```text
Simulation rôles locaux
Appliquer rôles localement
Simulation rôles serveur
Appliquer rôles serveur
Simulation permissions locales
Appliquer permissions localement
Simulation permissions serveur
Appliquer permissions serveur
Simulation badges locaux
Appliquer badges localement
Simulation badges serveur
Appliquer badges serveur
Simulation compétences locales
Appliquer compétences localement
Simulation compétences serveur
Appliquer compétences serveur
```

Règle :

```text
Un bouton avancé ne doit être visible que si son workflow est implémenté et documenté.
```

## 22. Validation des fichiers JSON

Avant toute simulation ou application, les fichiers JSON doivent être validés.

La validation doit vérifier au minimum :

```text
les fichiers existent ;
les fichiers sont lisibles ;
le JSON est valide ;
les champs obligatoires sont présents ;
les identifiants stables sont présents ;
les doublons évidents sont signalés ;
les liens entre données sont cohérents ;
les valeurs interdites sont signalées ;
les données dangereuses sont signalées.
```

Définition :

```text
Doublon = deux entrées qui semblent représenter la même donnée.
```

Exemple :

```text
deux cours avec le même identifiant stable.
```

## 23. Liens entre données

Certaines données dépendent d’autres données.

Exemples :

```text
un cours dépend d’une catégorie ;
un parcours dépend d’un programme ;
un badge peut dépendre de critères ;
une permission dépend d’un rôle ;
un modèle peut dépendre d’un plugin.
```

Définition :

```text
Dépendance = donnée nécessaire pour qu’une autre donnée soit valide.
```

Règle :

```text
La validation doit signaler les dépendances manquantes avant application.
```

## 24. Simulation Données Moodle

Définition :

```text
Simulation Données Moodle = action qui indique ce qui serait écrit dans Moodle, sans modifier la base Moodle.
```

La simulation doit indiquer :

```text
éléments qui seraient créés ;
éléments qui seraient mis à jour ;
éléments inchangés ;
éléments ignorés ;
avertissements ;
erreurs.
```

Le rapport de simulation doit contenir :

```text
Aucune donnée Moodle n’a été modifiée.
```

## 25. Application Données Moodle

Définition :

```text
Appliquer Données Moodle = écrire réellement les changements dans la base Moodle.
```

Une application doit être précédée d’une simulation quand l’action est complexe.

Règle :

```text
Toute action “Appliquer” qui écrit dans la base Moodle serveur doit avoir une simulation préalable.
```

L’application doit indiquer :

```text
cible : locale ou serveur ;
domaine : catégories, cours, programmes, etc. ;
source utilisée ;
résumé des changements ;
prochaine vérification.
```

## 26. Confirmation locale

Pour une application locale, message obligatoire :

```text
Cette action écrit dans la base Moodle locale. Continuer ?
```

Définition :

```text
Base Moodle locale = base de données utilisée par le Moodle local.
```

## 27. Confirmation serveur

Pour une application serveur, message obligatoire :

```text
Cette action écrit dans la base Moodle serveur. Continuer ?
```

Définition :

```text
Base Moodle serveur = base de données utilisée par Moodle sur uckk.org.
```

Si l’action touche aussi le site public :

```text
Cette action modifie uckk.org et écrit dans la base Moodle serveur. Continuer ?
```

## 28. Séparation local / serveur

Chaque action doit indiquer la cible.

Libellés corrects :

```text
Simulation cours locaux
Appliquer cours localement
Simulation cours serveur
Appliquer cours serveur
```

Libellés interdits :

```text
Appliquer cours
Run courses
Sync Moodle
Update data
```

Raison :

```text
Ces libellés ne disent pas si l’action vise local ou serveur.
```

## 29. Source utilisée

Chaque rapport doit indiquer la source utilisée.

Exemples :

```text
Source : C:\mycode\UCKK\uckk-moodle\academic_registry_json\courses.json
```

ou :

```text
Source serveur : /opt/uckk/uckk-moodle/academic_registry_json/courses.json
```

Règle :

```text
Une action serveur doit utiliser une source claire et attendue.
```

Elle ne doit pas utiliser silencieusement un ancien fichier temporaire ou une copie locale inconnue.

## 30. Idempotence

Les actions Données Moodle doivent être idempotentes autant que possible.

Définition :

```text
Idempotent = une action peut être relancée sans créer de doublons ou de dégâts.
```

Pour cela, les données doivent être reconnues par des identifiants stables.

Exemples :

```text
key ;
shortname ;
idnumber ;
code ;
slug ;
nom technique stable.
```

Règle :

```text
Relancer “Appliquer cours serveur” ne doit pas créer une deuxième copie du même cours.
```

## 31. Non-destruction par défaut

Par défaut, l’application ne doit pas supprimer des données Moodle.

Elle doit privilégier :

```text
créer ce qui manque ;
mettre à jour ce qui existe ;
laisser intact ce qui n’est pas concerné.
```

L’absence d’un élément dans un fichier JSON ne signifie pas suppression automatique.

Règle :

```text
La suppression ou désactivation doit être un mode explicite, documenté et confirmé.
```

Définition :

```text
Explicite = visible, annoncé et confirmé.
```

## 32. Suppression et désactivation

Si un jour l’application permet de supprimer ou désactiver des données Moodle, cela doit être séparé du workflow normal.

Noms acceptables :

```text
Désactiver éléments absents du fichier source
Archiver éléments absents du fichier source
Supprimer éléments absents du fichier source
```

Règle :

```text
Supprimer physiquement doit être plus dangereux que désactiver ou archiver.
```

Définitions :

```text
Désactiver = rendre inactif sans supprimer.

Archiver = conserver mais retirer du flux normal.

Supprimer = enlever la donnée de la base.
```

La suppression massive est une action de récupération ou de maintenance dangereuse.

Elle ne doit pas être le comportement par défaut.

## 33. Permissions et sécurité

Les rôles et permissions sont sensibles.

Règle :

```text
Toute modification de rôle ou permission doit produire un rapport détaillé.
```

Le rapport doit indiquer :

```text
rôle concerné ;
permission concernée ;
ancienne valeur si disponible ;
nouvelle valeur ;
cible : locale ou serveur ;
avertissements.
```

Définition :

```text
Ancienne valeur = état avant modification.
```

Définition :

```text
Nouvelle valeur = état après modification.
```

## 34. Vérification après application

Après une application Données Moodle, l’application doit proposer une vérification.

Exemples :

```text
Après catégories : vérifier l’index des cours.
Après cours : vérifier l’index des cours et le cours créé ou modifié.
Après programmes : vérifier la page des programmes.
Après parcours : vérifier les parcours concernés.
Après rôles/permissions : vérifier l’accès attendu avec prudence.
```

Règle :

```text
Une application réussie n’est pas complète tant que la vérification recommandée n’est pas indiquée.
```

## 35. Vérification navigateur

Certaines données affectent l’affichage.

Définition :

```text
Navigateur = application comme Chrome, Edge ou Firefox utilisée pour voir le site comme un utilisateur.
```

La vérification navigateur est recommandée pour :

```text
catégories visibles ;
cours visibles ;
programmes visibles ;
parcours visibles ;
rapports Moodle visibles ;
tout élément affiché sur uckk.org.
```

Une réponse technique ne suffit pas toujours.

Définition :

```text
HTTP 200 = réponse technique indiquant qu’une page a répondu.
```

## 36. Rapports Données Moodle

Toute action importante Données Moodle doit produire un rapport.

Actions concernées :

```text
Vérifier fichiers JSON Moodle ;
toute simulation ;
toute application ;
toute vérification après application ;
toute erreur ;
tout avertissement.
```

## 37. Contenu obligatoire du rapport

Un rapport Données Moodle doit contenir :

```text
action ;
domaine : catégories, cours, programmes, etc. ;
cible : locale ou serveur ;
mode : validation, simulation, application ou vérification ;
source utilisée ;
nombre d’éléments lus ;
nombre d’éléments valides ;
nombre d’éléments invalides ;
nombre d’éléments à créer ;
nombre d’éléments à mettre à jour ;
nombre d’éléments inchangés ;
nombre d’éléments ignorés ;
avertissements ;
erreurs ;
prochaine étape.
```

Définition :

```text
Mode = façon dont l’action a été lancée, par exemple validation, simulation ou application.
```

## 38. Rapport de simulation

Un rapport de simulation doit dire clairement :

```text
Aucune donnée Moodle n’a été modifiée.
```

Exemple :

```text
Simulation cours serveur
Aucune donnée Moodle n’a été modifiée.
Résumé : 2 cours seraient créés, 1 cours serait mis à jour, 18 seraient inchangés.
```

## 39. Rapport d’application

Un rapport d’application doit dire clairement :

```text
Des données Moodle ont été modifiées.
```

Exemple :

```text
Appliquer catégories serveur
Des données Moodle ont été modifiées.
Résumé : 1 catégorie créée, 2 catégories mises à jour, 0 erreur.
Prochaine étape : vérifier l’index des cours sur uckk.org.
```

## 40. Avertissements

Un avertissement ne bloque pas toujours l’action.

Exemples d’avertissements :

```text
champ optionnel manquant ;
élément inchangé ;
dépendance trouvée mais avec nom différent ;
valeur normalisée ;
page à vérifier dans le navigateur.
```

Définition :

```text
Normalisée = transformée en forme stable et cohérente.
```

Un avertissement doit être visible dans le rapport.

## 41. Erreurs

Une erreur bloque l’action ou une partie de l’action.

Exemples d’erreurs :

```text
JSON invalide ;
fichier introuvable ;
champ obligatoire absent ;
identifiant stable absent ;
dépendance manquante ;
cible serveur ambiguë ;
connexion Moodle impossible ;
écriture base Moodle refusée.
```

Format obligatoire :

```text
L’action a échoué.
Cause probable : ...
Prochaine étape : ...
Détail technique : ...
```

## 42. Conditions de refus

L’application doit refuser de continuer si :

```text
le fichier source est introuvable ;
le JSON est invalide ;
la cible local/serveur est ambiguë ;
la configuration nécessaire est absente ;
une action serveur n’a pas de confirmation ;
une action base Moodle serveur n’a pas de confirmation ;
une simulation obligatoire n’a pas été faite ;
une source non versionnée est utilisée pour appliquer serveur ;
un outil recovery est appelé comme workflow normal ;
un dump SQL est utilisé comme source normale.
```

Message recommandé :

```text
Action refusée.
Cause : condition Données Moodle manquante ou dangereuse.
Prochaine étape : ...
```

## 43. Interdiction du SQL brut comme workflow normal

Le SQL brut ne doit pas être un workflow normal des Données Moodle.

Définition :

```text
SQL = langage technique utilisé pour lire ou modifier une base de données.
```

Définition :

```text
SQL brut = commande SQL lancée directement sans workflow contrôlé.
```

Règle :

```text
Les Données Moodle normales ne se synchronisent pas par SQL brut.
```

Le SQL peut apparaître dans des outils de diagnostic ou de récupération, mais pas dans le workflow normal.

## 44. Interdiction de la copie directe de tables

La copie directe de tables ne doit pas être un workflow normal.

Définition :

```text
Copie directe de tables = transfert manuel de tables de base de données d’un environnement à un autre.
```

Raison :

```text
Les identifiants Moodle peuvent être différents entre local et serveur.
```

Définition :

```text
Identifiant Moodle = nombre interne utilisé par Moodle pour reconnaître un objet.
```

Règle :

```text
La synchronisation doit passer par des identifiants stables et une logique contrôlée.
```

## 45. Interdiction des anciens scripts non classés

Un ancien script ne doit pas être appelé par l’onglet Données Moodle s’il n’est pas classé.

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

Règle :

```text
Un script non classé ne doit pas être accessible depuis l’interface normale.
```

## 46. Relation avec Git

Les fichiers sources des Données Moodle doivent être versionnés dans Git.

Règle :

```text
Une modification destinée au serveur doit être enregistrée dans Git avant application serveur.
```

Workflow attendu :

```text
modifier fichier JSON ;
valider ;
simuler localement ;
appliquer localement si nécessaire ;
commit Git ;
push Git ;
publier serveur ;
simuler serveur ;
appliquer serveur ;
vérifier.
```

## 47. Relation avec le workflow serveur

L’application ne doit pas appliquer des Données Moodle serveur si le serveur n’a pas accès à la bonne version des fichiers sources.

Le rapport doit indiquer la source utilisée.

Exemple :

```text
Source utilisée : /opt/uckk/uckk-moodle/academic_registry_json/courses.json
```

Règle :

```text
Appliquer serveur doit partir d’une source claire côté serveur ou d’un transfert explicitement contrôlé.
```

## 48. Relation avec la configuration

Les chemins des fichiers sources doivent venir de la configuration.

Les champs de configuration peuvent inclure :

```text
moodleData.sourceDir
moodleData.categoriesFile
moodleData.coursesFile
moodleData.programsFile
moodleData.pathwaysFile
moodleData.rolesFile
moodleData.permissionsFile
moodleData.badgesFile
moodleData.competenciesFile
```

Règle :

```text
Si un fichier de données est nécessaire, son emplacement doit être configurable ou dérivable d’un dossier source configuré.
```

## 49. Nommage des actions

Les actions doivent être nommées avec :

```text
mode ;
domaine ;
cible.
```

Exemples :

```text
Simulation cours serveur
Appliquer cours serveur
Simulation programmes locaux
Appliquer programmes localement
```

Ne pas utiliser :

```text
Run seed
Apply data
Fix courses
Import Moodle
```

## 50. Données hors périmètre

Certaines données Moodle peuvent être trop sensibles ou trop complexes pour le workflow normal.

Exemples possibles :

```text
utilisateurs ;
mots de passe ;
inscriptions individuelles ;
notes ;
traces d’activité ;
données personnelles ;
données de paiement ;
données privées.
```

Règle :

```text
Ces données ne doivent pas être ajoutées au workflow normal sans contrat documentaire spécifique.
```

Définition :

```text
Donnée personnelle = information liée à une personne identifiable.
```

## 51. Sécurité des données personnelles

L’application ne doit pas exporter, afficher ou versionner des données personnelles sans contrat explicite.

Exemples de données personnelles :

```text
nom complet d’utilisateur ;
adresse courriel ;
identifiant personnel ;
note ;
historique d’activité ;
réponse à une activité ;
donnée privée de compte.
```

Règle :

```text
Les workflows Données Moodle décrits ici visent la structure pédagogique, pas les données personnelles des utilisateurs.
```

## 52. Sauvegardes

Le workflow normal ne doit pas être destructif.

Mais si une action peut supprimer ou remplacer plusieurs données, une sauvegarde est obligatoire.

Actions qui exigent une sauvegarde :

```text
suppression massive ;
reconstruction de données ;
restauration ;
copie directe de tables ;
action recovery ;
modification de rôles ou permissions à grande échelle.
```

Définition :

```text
Grande échelle = qui touche plusieurs éléments ou peut modifier un comportement global.
```

## 53. Messages de succès

Exemple validation :

```text
Réussi — les fichiers JSON Moodle sont valides.
```

Exemple simulation :

```text
Réussi — simulation terminée.
Aucune donnée Moodle n’a été modifiée.
Résumé : 2 cours seraient créés, 1 serait mis à jour, 18 inchangés.
```

Exemple application :

```text
Réussi — cours serveur appliqués.
Des données Moodle ont été modifiées.
Prochaine étape : vérifier l’index des cours sur uckk.org.
```

## 54. Messages d’erreur

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
Cause probable : le fichier courses.json contient un cours sans identifiant stable.
Prochaine étape : corriger le fichier JSON, puis relancer “Vérifier fichiers JSON Moodle”.
Détail technique : champ manquant = idnumber.
```

## 55. Anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
appliquer des données Moodle sans validation ;
appliquer serveur sans confirmation ;
appliquer serveur sans simulation quand elle est obligatoire ;
modifier la base Moodle silencieusement ;
utiliser SQL brut comme workflow normal ;
copier des tables local → serveur ;
mélanger Données Moodle et Médiathèque ;
inclure des données personnelles sans contrat spécifique ;
créer des boutons vagues ;
ignorer les dépendances entre données ;
créer des doublons au lieu d’upsert ;
coder des chemins de fichiers en dur ;
présenter un outil legacy comme normal.
```

Définition :

```text
Upsert = créer si absent, mettre à jour si déjà présent.
```

Si une nouvelle donnée Moodle doit être gérée, l’IA doit proposer une modification de ce document avant de coder.

## 56. Résumé obligatoire

Workflow normal :

```text
fichier source → validation → simulation → appliquer → vérifier
```

Source de vérité :

```text
fichiers JSON
```

Cibles :

```text
base Moodle locale ;
base Moodle serveur.
```

Domaines concernés :

```text
catégories ;
cours ;
programmes ;
parcours ;
rôles ;
permissions ;
compétences ;
badges ;
modèles ;
rapports.
```

Interdits dans le workflow normal :

```text
SQL brut ;
dump SQL ;
copie directe de tables ;
outil recovery ;
outil legacy non intégré ;
modification silencieuse ;
suppression par défaut ;
données personnelles sans contrat.
```

Règle finale :

```text
Les Données Moodle doivent être compréhensibles, versionnées, simulées, appliquées avec confirmation, puis vérifiées.
