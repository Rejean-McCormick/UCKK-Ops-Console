# Rapport — Vérifier Médiathèque locale

## Résumé

Statut : Échoué

La vérification Médiathèque a échoué.

## Action demandée

Vérifier Médiathèque locale

## Cible

Médiathèque locale

## Niveau de danger

1

## Mode

vérification

## Source utilisée

Non applicable.

## Étapes exécutées

Aucune étape détaillée.

## Changements

Non applicable.

## Avertissements

Aucun.

## Erreurs

- archiveId Médiathèque manquant ou invalide.
- courseId Médiathèque manquant ou invalide.
- cmId Médiathèque manquant ou invalide.
- contextId Médiathèque manquant ou invalide.

## Résultat final

Échoué

## Prochaine étape

Lire le rapport et corriger la cause de l’échec.

## Détail technique

~~~text
Domaine : mediatheque
Statut : Échoué
Généré le : 2026-09-28 14:40:34
Fuseau horaire : Eastern Standard Time
Log technique : C:\mycode\UCKK\UCKK_ops_console\logs\20260928_144034_mediatheque_verifier_mediatheque_locale_mediatheque_locale.log
~~~

## Données structurées

~~~text
{"url":"http://127.0.0.1:8000/local/uckk/mediatheque.php","targetConfig":{"Target":"local","ArchiveId":0,"CourseId":0,"CmId":0,"ContextId":0},"verification":{"success":false,"status":"Échoué","action":"Vérifier cible Médiathèque Moodle","domain":"mediatheque","target":"local","dangerLevel":1,"mode":"vérification","summary":"L’action a échoué.","warnings":null,"errors":["archiveId Médiathèque manquant ou invalide.","courseId Médiathèque manquant ou invalide.","cmId Médiathèque manquant ou invalide.","contextId Médiathèque manquant ou invalide."],"nextStep":"Corriger la configuration Médiathèque avant de continuer.","reportPath":"","logPath":"","data":{"target":"local","isServer":false,"moodleRoot":"C:/mycode/UCKK/moodle/moodle","moodleRuntime":"C:/mycode/UCKK/moodle/moodle/public","phpPath":"php","baseUrl":"http://127.0.0.1:8000","mediathequeUrl":"http://127.0.0.1:8000/local/uckk/mediatheque.php","archiveId":0,"courseId":0,"cmId":0,"contextId":0,"serviceName":"mod_uckkarchive_search_mediatheque","tableNames":["uckkarchive_external_work","uckkarchive_media","uckkarchive_media_source","uckkarchive_media_tag","uckkarchive_media_collection","uckkarchive_media_collection_item"]},"steps":null,"startedAt":"2026-09-28 14:40:34","finishedAt":"","durationSeconds":null}}
~~~