# Rapport — Démarrer Moodle local

## Résumé

Statut : Réussi

Réussi — Moodle local a été démarré et répond : http://127.0.0.1:8000

## Action demandée

Démarrer Moodle local

## Cible

Moodle local

## Niveau de danger

2

## Mode

application

## Source utilisée

Non applicable.

## Étapes exécutées

- {"name":"Lancer serveur PHP local","status":"Réussi","summary":"Serveur PHP local lancé.","detail":"php -S 127.0.0.1:8000 -t C:\\mycode\\UCKK\\moodle\\moodle\\public","data":{"processId":33596,"baseUrl":"http://127.0.0.1:8000","runtime":"C:\\mycode\\UCKK\\moodle\\moodle\\public"},"timestamp":"2026-09-24 22:32:41"}
- {"name":"Attendre Moodle local","status":"Réussi","summary":"Moodle local répond.","detail":"http://127.0.0.1:8000","data":{"success":true,"url":"http://127.0.0.1:8000","statusCode":200,"detail":"OK"},"timestamp":"2026-09-24 22:32:43"}

## Changements

Non applicable.

## Avertissements

Aucun.

## Erreurs

Aucune.

## Résultat final

Réussi

## Prochaine étape

Ouvrir Moodle local ou tester les pages locales.

## Détail technique

~~~text
Domaine : local
Statut : Réussi
Généré le : 2026-09-24 22:32:43
Fuseau horaire : Eastern Standard Time
Log technique : C:\mycode\UCKK\UCKK_ops_console\logs\20260924_223243_local_demarrer_moodle_local_moodle_local.log
~~~

## Données structurées

~~~text
{"baseUrl":"http://127.0.0.1:8000","localRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","phpBinary":"php","arguments":["-S","127.0.0.1:8000","-t","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"processId":33596,"readyCheck":{"success":true,"url":"http://127.0.0.1:8000","statusCode":200,"detail":"OK"}}
~~~