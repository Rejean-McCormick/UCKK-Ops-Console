<!-- kOA Doc Server · Docs IA · lot 03 · projet : UCKK_ops_console · proposition dérivée à valider -->
# Contexte IA — UCKK_ops_console

## Identité et périmètre observés

Console locale de gestion des opérations UCKK : contrôles, synchronisation de code, publications et reprises supervisées.

**Limite d'autorité :** Les modules propriétaires Moodle, Publisher et Médiathèque sont responsables de leurs effets; la console orchestre sous prévol et approbation.

**Provenance :** `SmartDump_20261120_221507.zip` → `UCKK_ops_console_Code_snapshot.zip` (20 novembre 2026). Les sources citées sont celles de cette capture; le propriétaire du dépôt conserve l'autorité sur les révisions présentes et futures.

## Avant toute proposition de modification

1. Déterminer si le travail demandé porte sur **un document, un contrat, une donnée, un exécutable ou un résultat dérivé**.
2. Consulter les fichiers propriétaires, dans cet ordre :
   - [`README.md`](../../README.md)
   - [`legacy/README.md`](../../legacy/README.md)
   - [`recovery/README.md`](../../recovery/README.md)
   - [`app/UckkOpsConsole.Gui.ps1`](../../app/UckkOpsConsole.Gui.ps1)

3. Vérifier les éventuels `AGENTS.md`, manifests, locks, schémas ou décisions de ce checkout; ne pas traiter cette fiche dérivée comme un substitut.
4. Cartographier producteur, consommateur, format, version et permissions pour chaque frontière franchie.

## Procédure adaptée

**Tâche type :** Lire les modules de console et les précautions de synchronisation, effectuer une prévisualisation et confirmer la cible avant toute opération ayant des effets.

**Éviter précisément :** Ne pas transformer la console en terminal arbitraire, exécuter des scripts legacy ou manipuler directement les tables Moodle.

**Contrôles attendus avant la conclusion :** identifier les tests, validateurs et rapports réellement présents sur le système cible; exécuter uniquement ceux qui sont non destructifs et appropriés; relier chaque résultat à une révision et un environnement précis. En absence de code/test (ou si les sources sont insuffisantes), écrire « non vérifié », jamais « PASS ».

## Utilisation par kOA Doc Server

- **Lecture et export :** n'inclure que les documents explicitement sélectionnés, avec chemins relatifs, empreintes et provenance.
- **RepoSurveyor :** profils mesurés séparément à partir du code local. Ne pas fabriquer `ENGINEERING_PROFILE.md` depuis cette fiche; l'alias français est `PROFIL_INGENIERIE.md` après génération réelle.
- **Diagnostics :** observations datées, preuves historiques et états certifiés restent distincts. Aucune promotion automatique.
- **Wikis et vues :** documents dérivés, jamais propriétaires des contrats ni des permissions.
- **Confidentialité :** filtrer secrets, données personnelles, médias sous droits, caches, backups et rapports privés avant un ZIP de contexte IA.
- **Standard Kristal Framework v11 :** si pertinent, consulter le cadre comme référence possible, sans l'exiger pour naviguer ni forcer une migration du profil historique du dépôt.

## État de cette fiche

`DOCUMENTATION_REDACTIONNELLE_A_REVOIR` : elle facilite le démarrage d'un agent, mais **ne prouve aucun état d'intégration, publication, conformité ni maturité**.
