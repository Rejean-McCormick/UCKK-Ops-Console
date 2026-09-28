# 10 — Rapports, logs et erreurs

## 1. Rôle de ce document

Ce document définit comment la nouvelle application doit produire, afficher et conserver :

```text
rapports ;
logs techniques ;
messages de succès ;
messages d’avertissement ;
messages d’erreur ;
résultats d’action.
```

Application concernée :

```text
C:\mycode\UCKK\UCKK_ops_console
```

Ce document sert à empêcher l’IA de coder une application qui affiche seulement des sorties techniques brutes.

Définition :

```text
Rapport = résumé lisible d’une action.
```

Définition :

```text
Log technique = journal détaillé utile pour diagnostiquer une action.
```

Définition :

```text
Erreur = problème qui empêche une action de réussir complètement.
```

Règle principale :

```text
L’utilisateur doit comprendre ce qui s’est passé sans devoir lire un log technique.
```

## 2. Principe central

Toute action importante doit produire un résultat lisible.

Une action importante est une action qui :

```text
modifie des fichiers ;
modifie Git ;
modifie le serveur ;
écrit dans la base Moodle ;
applique des données ;
lance une récupération ;
échoue ;
produit un avertissement ;
sert à diagnostiquer un problème.
```

Règle :

```text
Le rapport explique.
Le log diagnostique.
L’interface résume.
```

## 3. Différence entre rapport et log

### 3.1 Rapport

Un rapport est destiné à l’utilisateur.

Il doit être lisible.

Il doit répondre à ces questions :

```text
Quelle action a été lancée ?
Sur quelle cible ?
Dans quel mode ?
Qu’est-ce qui a été fait ?
Qu’est-ce qui a changé ?
Y a-t-il des avertissements ?
Y a-t-il des erreurs ?
Que faut-il faire ensuite ?
```

### 3.2 Log technique

Un log technique est destiné au diagnostic.

Il peut contenir :

```text
commandes exécutées ;
sorties techniques ;
codes de retour ;
chemins utilisés ;
timestamps ;
détails d’exception ;
réponses brutes ;
traces courtes.
```

Définition :

```text
Timestamp = date et heure enregistrées avec un événement.
```

Définition :

```text
Exception = erreur technique produite par le code.
```

Définition :

```text
Trace = détail technique qui montre où une erreur s’est produite dans le code.
```

### 3.3 Règle

Le log ne remplace jamais le rapport.

L’interface ne doit pas afficher le log comme résultat principal.

## 4. Dossiers officiels

Les rapports sont écrits dans :

```text
./reports
```

Les logs techniques sont écrits dans :

```text
./logs
```

Ces chemins doivent venir de la configuration :

```text
reports.dir
logs.dir
```

Ils ne doivent pas être codés en dur dans les modules.

Définition :

```text
Codé en dur = écrit directement dans le code au lieu d’être lu depuis la configuration.
```

## 5. Création des dossiers

L’application peut créer automatiquement :

```text
./reports
./logs
```

si ces dossiers n’existent pas.

Elle doit afficher une erreur lisible si elle ne peut pas les créer.

Message recommandé :

```text
L’action a échoué.
Cause probable : le dossier des rapports ne peut pas être créé.
Prochaine étape : vérifier les permissions du dossier de l’application.
Détail technique : reports.dir = ...
```

Définition :

```text
Permission = droit de lire, écrire ou modifier un fichier ou dossier.
```

## 6. Format des rapports

Le format principal des rapports doit être :

```text
Markdown
```

Définition :

```text
Markdown = format texte lisible qui peut contenir titres, listes et blocs de code.
```

Extension recommandée :

```text
.md
```

Exemple :

```text
reports/20260609_143012_mediatheque_simulation_serveur.md
```

## 7. Format des logs

Le format principal des logs peut être :

```text
texte brut
```

Extension recommandée :

```text
.log
```

Exemple :

```text
logs/20260609_143012_mediatheque_simulation_serveur.log
```

Si un format structuré est nécessaire, il peut être ajouté plus tard, mais le format texte doit rester lisible.

## 8. Nommage des fichiers de rapport

Un nom de rapport doit contenir :

```text
date ;
heure ;
domaine ;
action ;
cible si applicable.
```

Format recommandé :

```text
YYYYMMDD_HHMMSS_domaine_action_cible.md
```

Exemples :

```text
20260609_143012_local_verifier_chemins.md
20260609_143512_git_verifier.md
20260609_144020_serveur_publication.md
20260609_144533_mediatheque_simulation_serveur.md
20260609_145010_donnees_moodle_appliquer_cours_serveur.md
20260609_150100_recovery_mediatheque_reconstruction.md
```

Définition :

```text
YYYYMMDD = année, mois, jour.
HHMMSS = heure, minute, seconde.
```

Règle :

```text
Le nom du fichier doit aider à retrouver le rapport sans ouvrir tous les fichiers.
```

## 9. Nommage des logs

Le log lié à un rapport doit utiliser le même préfixe que le rapport.

Exemple :

```text
Rapport :
20260609_143012_mediatheque_simulation_serveur.md

Log :
20260609_143012_mediatheque_simulation_serveur.log
```

Règle :

```text
Un rapport important doit pouvoir pointer vers son log technique.
```

## 10. Structure obligatoire d’un rapport

Un rapport doit contenir ces sections dans cet ordre :

```text
# Titre
## Résumé
## Action demandée
## Cible
## Niveau de danger
## Mode
## Source utilisée
## Étapes exécutées
## Changements
## Avertissements
## Erreurs
## Résultat final
## Prochaine étape
## Détail technique
```

Si une section ne s’applique pas, elle doit quand même être présente avec :

```text
Aucun.
```

ou :

```text
Non applicable.
```

Règle :

```text
La structure des rapports doit rester stable.
```

## 11. Section `# Titre`

Le titre doit être lisible.

Exemples :

```text
# Rapport — Simulation Médiathèque serveur
# Rapport — Vérifier Git
# Rapport — Publication serveur
# Rapport — Appliquer cours serveur
```

Le titre ne doit pas être seulement un nom de script.

Mauvais exemple :

```text
# sync_uckk_mediatheque.php
```

Bon exemple :

```text
# Rapport — Appliquer Médiathèque serveur
```

## 12. Section `## Résumé`

Le résumé doit donner la conclusion en quelques lignes.

Exemple :

```text
Statut : Réussi
Résumé : la simulation Médiathèque serveur est terminée.
Aucune donnée Moodle n’a été modifiée.
Prochaine étape : lire les changements prévus, puis appliquer si tout est correct.
```

Le résumé ne doit pas commencer par une sortie technique brute.

## 13. Section `## Action demandée`

Cette section indique ce que l’utilisateur a lancé.

Exemples :

```text
Action demandée : Simulation Médiathèque serveur
```

```text
Action demandée : Synchroniser source vers Moodle local
```

```text
Action demandée : Créer un commit Git
```

## 14. Section `## Cible`

La cible indique l’endroit visé par l’action.

Cibles possibles :

```text
local ;
serveur ;
Git ;
base Moodle locale ;
base Moodle serveur ;
Médiathèque locale ;
Médiathèque serveur ;
aucune cible modifiée.
```

Exemple :

```text
Cible : base Moodle serveur
```

Définition :

```text
Cible = endroit visé par une action.
```

## 15. Section `## Niveau de danger`

Le niveau de danger doit suivre le document :

```text
docs/06_ACTIONS_SECURITE_CONFIRMATIONS.md
```

Niveaux officiels :

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

Exemple :

```text
Niveau de danger : 6 — Base Moodle serveur
Confirmation utilisateur : oui
Simulation préalable : oui
```

## 16. Section `## Mode`

Le mode indique la nature de l’action.

Modes officiels :

```text
navigation ;
vérification ;
simulation ;
application ;
publication ;
récupération ;
test ;
annulation.
```

Définitions :

```text
Vérification = action qui contrôle un état sans modifier les données.

Simulation = action qui montre ce qui serait fait, sans modifier les données.

Application = action qui écrit réellement les changements.

Publication = action qui met à jour le serveur public.

Récupération = action spéciale utilisée quand l’état normal est cassé.
```

## 17. Section `## Source utilisée`

Cette section indique d’où viennent les données ou le code.

Exemples :

```text
Source utilisée : C:\mycode\UCKK\uckk-moodle
```

```text
Source utilisée : C:\mycode\UCKK\uckk-moodle\content\mediatheque\mediatheque.catalog.json
```

```text
Source utilisée : /opt/uckk/uckk-moodle
```

Si aucune source ne s’applique :

```text
Source utilisée : non applicable.
```

Règle :

```text
Une action qui applique des données doit toujours indiquer sa source.
```

## 18. Section `## Étapes exécutées`

Cette section liste les étapes.

Format recommandé :

```text
- Réussi — vérifier configuration.
- Réussi — lire manifeste.
- Réussi — valider données.
- Réussi — calculer changements.
- Ignoré — aucune écriture, mode simulation.
```

Statuts possibles :

```text
Non lancée
En cours
Réussi
Réussi avec avertissements
Échoué
Ignoré
Annulé
```

Définition :

```text
Ignoré = étape volontairement non exécutée parce qu’elle n’était pas nécessaire ou parce qu’une étape précédente a échoué.
```

## 19. Section `## Changements`

Cette section décrit les changements.

Pour une simulation, elle doit dire :

```text
Aucune donnée n’a été modifiée.
```

Puis indiquer les changements prévus.

Exemple :

```text
Aucune donnée Moodle n’a été modifiée.

Prévu :
- Références à créer : 1
- Références à mettre à jour : 2
- Références inchangées : 125
```

Pour une application, elle doit dire :

```text
Des données ont été modifiées.
```

Puis indiquer les changements réels.

Exemple :

```text
Des données Moodle ont été modifiées.

Effectué :
- Références créées : 1
- Références mises à jour : 2
- Références inchangées : 125
```

## 20. Section `## Avertissements`

Un avertissement est un problème ou risque qui ne bloque pas nécessairement l’action.

Définition :

```text
Avertissement = problème ou risque qui n’a pas nécessairement bloqué l’action.
```

Si aucun avertissement :

```text
Aucun.
```

Exemples :

```text
- La page répond, mais les cartes sont chargées par AJAX et doivent être vérifiées dans le navigateur.
- Une collection absente serait créée.
- Un champ optionnel est vide.
```

## 21. Section `## Erreurs`

Une erreur est un problème qui empêche l’action de réussir complètement.

Définition :

```text
Erreur = problème qui a empêché l’action de réussir complètement.
```

Si aucune erreur :

```text
Aucune.
```

Exemples :

```text
- Le manifeste Médiathèque est introuvable.
- La connexion SSH au serveur a échoué.
- Le fichier JSON est invalide.
```

## 22. Section `## Résultat final`

Le résultat final doit utiliser un statut officiel.

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

Exemple :

```text
Résultat final : Réussi avec avertissements
```

Le rapport doit expliquer pourquoi ce statut a été choisi.

## 23. Section `## Prochaine étape`

Cette section est obligatoire.

Elle indique quoi faire ensuite.

Exemples :

```text
Prochaine étape : ouvrir la Médiathèque serveur dans le navigateur.
```

```text
Prochaine étape : corriger le fichier JSON, puis relancer la validation.
```

```text
Prochaine étape : lire les différences Git avant de créer un commit.
```

Si aucune action n’est nécessaire :

```text
Prochaine étape : aucune action requise.
```

## 24. Section `## Détail technique`

Cette section contient des détails utiles, mais pas trop longs.

Elle peut contenir :

```text
chemins utilisés ;
URL testée ;
nom du service ;
code de retour ;
nom du log lié ;
commande résumée ;
identifiants techniques utiles.
```

Si le détail est long, écrire :

```text
Voir le log technique : ...
```

Règle :

```text
Le rapport ne doit pas devenir un log complet.
```

## 25. Structure obligatoire d’un log technique

Un log technique doit contenir au minimum :

```text
date et heure de début ;
date et heure de fin ;
action ;
cible ;
configuration utilisée ;
commandes exécutées ;
sorties techniques ;
codes de retour ;
erreurs techniques ;
chemin du rapport lié.
```

Le log peut être plus long que le rapport.

Mais il ne doit pas contenir de secrets.

## 26. Données interdites dans les rapports et logs

Les rapports et logs ne doivent jamais contenir :

```text
mots de passe ;
clés SSH privées ;
tokens ;
cookies de session ;
secrets Moodle ;
secrets de base de données ;
config.php serveur complet ;
données personnelles non nécessaires ;
dumps SQL complets.
```

Définition :

```text
Donnée personnelle = information liée à une personne identifiable.
```

Si une valeur sensible est détectée, elle doit être masquée.

Exemple :

```text
token = ****
```

ou :

```text
mot de passe = [masqué]
```

## 27. Résultat affiché dans l’interface

Après chaque action, l’interface doit afficher un résumé court.

Format recommandé :

```text
Statut : ...
Action : ...
Cible : ...
Résumé : ...
Prochaine étape : ...
Rapport : ouvrir
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

## 28. Message de succès

Un message de succès doit dire ce qui a réussi.

Mauvais exemple :

```text
Done.
```

Bon exemple :

```text
Réussi — la source a été copiée vers Moodle local.
```

Autre exemple :

```text
Réussi — le service Médiathèque serveur retourne 128 références.
À vérifier dans le navigateur : https://uckk.org/local/uckk/mediatheque.php
```

## 29. Message d’avertissement

Un avertissement doit expliquer le risque ou la vérification à faire.

Format recommandé :

```text
Réussi avec avertissements — ...
Prochaine étape : ...
```

Exemple :

```text
Réussi avec avertissements — la page Médiathèque répond, mais les cartes sont chargées par AJAX.
Prochaine étape : vérifier la page dans le navigateur.
```

## 30. Message d’erreur

Un message d’erreur doit suivre cette structure :

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
Prochaine étape : vérifier la configuration serveur, puis relancer “Tester connexion serveur”.
Détail technique : code de retour 255.
```

Règle :

```text
Une erreur doit toujours dire ce qui a échoué et quoi faire ensuite.
```

## 31. Message d’annulation

Si l’utilisateur refuse une confirmation, l’action n’est pas une erreur.

Statut :

```text
Annulé
```

Message recommandé :

```text
Annulé — aucune modification n’a été faite.
```

Un rapport peut être produit pour une annulation si l’action était sensible.

## 32. Faux succès interdit

Définition :

```text
Faux succès = message qui annonce une réussite alors qu’une étape nécessaire a échoué ou n’a pas été vérifiée.
```

Exemples interdits :

```text
Réussi — publication terminée.
```

si la synchronisation serveur a échoué.

```text
Réussi — Médiathèque OK.
```

si seule la page HTML a répondu mais le service AJAX n’a pas été vérifié.

Règle :

```text
Le statut doit refléter l’étape la plus grave du workflow.
```

## 33. Échecs partiels

Définition :

```text
Échec partiel = une partie de l’action a réussi, mais une autre partie a échoué.
```

Si une action a un échec partiel, le statut ne doit pas être simplement :

```text
Réussi
```

Statuts possibles :

```text
Réussi avec avertissements
Échoué
```

Le rapport doit expliquer quelles étapes ont réussi et lesquelles ont échoué.

## 34. Vérification navigateur

Certaines actions doivent indiquer une vérification navigateur.

Définition :

```text
Navigateur = application comme Chrome, Edge ou Firefox utilisée pour voir le site comme un utilisateur.
```

La vérification navigateur est nécessaire quand :

```text
la page charge des données par AJAX ;
la page dépend de JavaScript ;
l’action modifie une page visible ;
le test technique ne suffit pas à confirmer l’affichage.
```

Définition :

```text
AJAX = méthode utilisée par une page web pour charger des données après l’ouverture de la page.
```

Définition :

```text
JavaScript = langage utilisé dans le navigateur pour rendre une page interactive.
```

Message recommandé :

```text
À vérifier dans le navigateur : ...
```

## 35. HTTP 200 ne suffit pas toujours

Définition :

```text
HTTP 200 = réponse technique indiquant qu’une page a répondu.
```

Règle :

```text
HTTP 200 confirme que la page répond, mais ne confirme pas toujours que tout l’affichage fonctionne.
```

Exemple :

```text
La page Médiathèque peut répondre HTTP 200, puis charger les cartes par AJAX.
```

Donc le rapport doit distinguer :

```text
page répond ;
service répond ;
données attendues présentes ;
affichage à vérifier dans le navigateur.
```

## 36. Rapports par domaine

Les rapports doivent indiquer leur domaine.

Domaines officiels :

```text
local ;
git ;
serveur ;
mediatheque ;
donnees_moodle ;
tests ;
recovery ;
configuration.
```

Nom visible dans le rapport :

```text
Local
Git
Serveur
Médiathèque
Données Moodle
Tests
Récupération
Configuration
```

Le nom de fichier peut utiliser une version sans accent.

Exemple :

```text
donnees_moodle
```

## 37. Rapports Médiathèque

Un rapport Médiathèque doit inclure :

```text
chemin du manifeste ;
nombre d’entrées dans le manifeste ;
cible locale ou serveur ;
mode simulation ou application ;
nombre de références créées ;
nombre de références mises à jour ;
nombre de références inchangées ;
nombre de collections traitées ;
nombre de tags traités ;
service Médiathèque vérifié si applicable ;
prochaine vérification navigateur.
```

## 38. Rapports Données Moodle

Un rapport Données Moodle doit inclure :

```text
domaine : catégories, cours, programmes, etc. ;
fichier source ;
cible locale ou serveur ;
mode validation, simulation ou application ;
nombre d’éléments lus ;
nombre d’éléments valides ;
nombre d’éléments invalides ;
changements prévus ou effectués ;
prochaine vérification.
```

## 39. Rapports Git

Un rapport Git doit inclure :

```text
branche actuelle ;
fichiers modifiés ;
fichiers ajoutés ;
fichiers supprimés ;
résultat de la vérification des fichiers sensibles ;
commit créé si applicable ;
push effectué si applicable ;
avertissements.
```

Définition :

```text
Branche = ligne de travail dans Git.
```

## 40. Rapports Serveur

Un rapport Serveur doit inclure :

```text
cible serveur ;
connexion SSH ;
dossier source serveur ;
dossier exécuté par Moodle serveur ;
étapes exécutées ;
code récupéré depuis Git ;
synchronisation vers runtime ;
mise à jour Moodle si lancée ;
purge caches si lancée ;
vérification uckk.org ;
prochaine vérification navigateur.
```

## 41. Rapports Récupération

Un rapport Récupération doit inclure :

```text
raison de la récupération ;
niveau de danger ;
sauvegarde utilisée ou créée ;
données lues ;
données modifiées ;
données supprimées si applicable ;
confirmation utilisateur ;
résultat ;
comment vérifier ;
comment revenir en arrière si possible.
```

Définition :

```text
Récupération = action spéciale utilisée quand l’état normal est cassé.
```

## 42. Logs et commandes

Quand une commande est exécutée, le log doit indiquer :

```text
commande ou résumé de commande ;
dossier de travail ;
heure de début ;
heure de fin ;
code de retour ;
sortie standard ;
sortie erreur.
```

Définitions :

```text
Sortie standard = texte normal produit par une commande.

Sortie erreur = texte d’erreur produit par une commande.

Code de retour = nombre donné par une commande pour indiquer si elle a réussi ou échoué.
```

Le rapport ne doit contenir que le résumé utile de cette commande.

## 43. Codes de retour

Règle générale :

```text
Code de retour 0 = réussite habituelle.
Code de retour différent de 0 = erreur ou situation spéciale.
```

Le rapport doit traduire le code de retour.

Mauvais exemple :

```text
Exit code: 255
```

Bon exemple :

```text
L’action a échoué.
Cause probable : la connexion SSH a été refusée ou impossible.
Détail technique : code de retour 255.
```

## 44. Exceptions

Si le code de l’application produit une exception, l’interface doit afficher un message lisible.

Le log peut contenir le détail technique.

Message recommandé :

```text
L’action a échoué.
Cause probable : une erreur interne est survenue.
Prochaine étape : ouvrir le rapport et le log technique.
Détail technique : exception = ...
```

Règle :

```text
Ne pas afficher une longue trace technique comme message principal.
```

## 45. Écriture atomique des rapports

Définition :

```text
Écriture atomique = écrire un fichier de manière à éviter un rapport partiellement corrompu si l’action échoue.
```

Règle recommandée :

```text
Écrire d’abord dans un fichier temporaire, puis renommer vers le nom final.
```

Exemple :

```text
20260609_143012_mediatheque_simulation_serveur.md.tmp
```

puis :

```text
20260609_143012_mediatheque_simulation_serveur.md
```

Cette règle est recommandée pour éviter les rapports incomplets.

## 46. Rapport même en cas d’échec

Si une action importante échoue, l’application doit produire un rapport si possible.

Règle :

```text
Un échec doit laisser une trace lisible.
```

Si le rapport ne peut pas être écrit, l’interface doit le dire :

```text
L’action a échoué.
Cause probable : ...
Prochaine étape : ...
Détail technique : le rapport n’a pas pu être écrit.
```

## 47. Dernier rapport

L’application doit pouvoir retrouver le dernier rapport.

Définition :

```text
Dernier rapport = rapport le plus récent produit par l’application.
```

L’Accueil et l’onglet Historique doivent pouvoir proposer :

```text
Ouvrir le dernier rapport
```

Si aucun rapport n’existe :

```text
Aucun rapport disponible pour le moment.
```

## 48. Historique des rapports

L’onglet Historique peut afficher les rapports par :

```text
date ;
domaine ;
statut ;
cible ;
action.
```

Définition :

```text
Filtrer = afficher seulement une partie d’une liste selon un critère.
```

L’historique ne doit pas relancer automatiquement une action.

Il sert à lire, ouvrir et comprendre.

## 49. Conservation des rapports

La configuration peut définir combien de rapports afficher ou conserver.

Champ possible :

```text
reports.keepLast
```

Règle :

```text
L’application ne doit pas supprimer silencieusement des rapports sans règle explicite.
```

Si une suppression automatique est ajoutée un jour, elle doit être documentée.

## 50. Conservation des logs

Les logs peuvent devenir volumineux.

La configuration peut définir une politique de conservation.

Mais au départ :

```text
ne pas supprimer automatiquement sans règle documentée.
```

Si une suppression est nécessaire, l’utilisateur doit pouvoir comprendre ce qui est conservé.

## 51. Niveaux de log

Niveaux possibles :

```text
normal
debug
```

Définition :

```text
normal = niveau de détail habituel.

debug = niveau plus détaillé utilisé pour diagnostiquer un problème.
```

Dans l’interface, utiliser :

```text
Niveau normal
Niveau détaillé
```

plutôt que seulement :

```text
debug
```

## 52. Horodatage

Chaque rapport et log doit contenir un horodatage.

Définition :

```text
Horodatage = date et heure associées à une action.
```

Format recommandé :

```text
YYYY-MM-DD HH:MM:SS
```

Pour les noms de fichiers :

```text
YYYYMMDD_HHMMSS
```

## 53. Fuseau horaire

Le fuseau horaire local attendu est :

```text
America/Montreal
```

Définition :

```text
Fuseau horaire = règle qui détermine l’heure locale d’un endroit.
```

Les rapports doivent utiliser l’heure locale de l’utilisateur si possible.

Si l’application utilise UTC dans les logs techniques, elle doit l’indiquer clairement.

Définition :

```text
UTC = heure universelle de référence.
```

## 54. Résumé dans l’interface

L’interface doit afficher un résumé, pas le rapport entier.

Exemple :

```text
Réussi — simulation Médiathèque serveur terminée.
Aucune donnée Moodle n’a été modifiée.
Rapport : ouvrir
```

Le rapport contient le détail.

Le log contient le diagnostic.

## 55. Anti-dérive pour l’IA

Pendant le codage, l’IA ne doit pas :

```text
afficher seulement une sortie technique brute ;
annoncer un succès si une étape critique a échoué ;
ignorer la prochaine étape ;
écrire des rapports sans structure stable ;
mélanger rapport et log ;
mettre des secrets dans les rapports ;
mettre des secrets dans les logs ;
supprimer des rapports silencieusement ;
inventer des statuts non documentés ;
remplacer “Simulation” par “dry-run” comme mot principal ;
oublier de lier un rapport à son log technique ;
utiliser HTTP 200 comme preuve suffisante pour les pages AJAX.
```

Si un nouveau type de rapport est nécessaire, il doit respecter la structure obligatoire ou ce document doit être mis à jour.

## 56. Résumé obligatoire

Règles finales :

```text
Le rapport explique.
Le log diagnostique.
L’interface résume.
Une erreur dit quoi faire ensuite.
Un succès dit ce qui a réussi.
Un avertissement dit quoi vérifier.
Un faux succès est interdit.
Les secrets sont interdits dans les rapports et les logs.
Toute action importante laisse une trace lisible.
```


## Mise à jour — persistance automatique et verbosité

L'interface finalise désormais les artefacts déclarés par les actions :

- `ProducesLog = true` écrit un log technique dans `logs/`;
- `ProducesReport = true` écrit un rapport Markdown dans `reports/`.

Les résultats locaux de processus exposent au minimum la commande, le dossier courant,
le code de sortie, le timeout, la durée, STDOUT et STDERR. Pour une chaîne composite,
le résultat complet de l'étape fautive est conservé sous `data.failedResult`.

L'UI affiche ces informations directement lorsque `ui.verboseResults = true`.
