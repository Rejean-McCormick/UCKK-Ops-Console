<!-- kOA Doc Server · Docs IA · lot 03 · projet : UCKK_ops_console · proposition dérivée à valider -->
# Navigation IA — UCKK_ops_console

**Objet constaté :** Console locale de gestion des opérations UCKK : contrôles, synchronisation de code, publications et reprises supervisées.

**Frontière de responsabilité :** Les modules propriétaires Moodle, Publisher et Médiathèque sont responsables de leurs effets; la console orchestre sous prévol et approbation.

**Source :** `SmartDump_20261120_221507.zip` → `UCKK_ops_console_Code_snapshot.zip` (20 novembre 2026). Le chemin Windows est une déclaration de snapshot, pas une vérification de l'état actuel.

**Statut :** Documentation de navigation dérivée de sources propriétaires, à revoir. Ce document ne vaut ni profil d'ingénierie mesuré, ni certification, ni permission d'exécution.

## Ordre de lecture — fichiers réellement présents dans la capture

1. [`README.md`](../../README.md) — SHA-256 `6539d5c2c77df23f…` dans la capture.
2. [`legacy/README.md`](../../legacy/README.md) — SHA-256 `d6d5eaea7b8e16a4…` dans la capture.
3. [`recovery/README.md`](../../recovery/README.md) — SHA-256 `79323688972c9869…` dans la capture.
4. [`app/UckkOpsConsole.Gui.ps1`](../../app/UckkOpsConsole.Gui.ps1) — SHA-256 `40322fb4f2b02be9…` dans la capture.

## Parcours recommandé pour une intervention assistée par IA

1. Identifier la question, le sous-système concerné et les responsabilités du propriétaire.
2. Lire les documents ci-dessus **dans cet ordre**; consulter les contrats et consignes propriétaires plus récents si le checkout a évolué.
3. Lire les modules de console et les précautions de synchronisation, effectuer une prévisualisation et confirmer la cible avant toute opération ayant des effets.
4. Établir les vérifications effectivement disponibles dans la révision locale, consigner les résultats et ne conclure qu'à l'intérieur du périmètre couvert.
5. Proposer les changements; demander une décision explicite avant toute écriture à effet, déploiement, publication ou promotion de preuves.

## Risque propre à ce dépôt

Ne pas transformer la console en terminal arbitraire, exécuter des scripts legacy ou manipuler directement les tables Moodle.

## Compléments

- [`AI_CONTEXT.md`](AI_CONTEXT.md) : règles de travail et frontières de confiance.
- `AGENTS.md` : s'il existe déjà chez le propriétaire, ses consignes priment sur ces propositions; sinon l'overlay peut en ajouter un sans remplacement.
- `PROFIL_INGENIERIE.md` : optionnel, uniquement après exécution réelle de RepoSurveyor sur un dépôt local et accord explicite pour sa copie.
- Le Framework Kristal v11 est un standard documentaire **facultatif** : lire le profil réellement verrouillé, sans imposer de migration.
