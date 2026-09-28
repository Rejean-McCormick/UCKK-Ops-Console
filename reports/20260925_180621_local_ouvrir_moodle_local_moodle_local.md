# Rapport — Ouvrir Moodle local

## Résumé

Statut : Échoué

Réussi — Moodle local répond et a été ouvert : http://127.0.0.1:8000/?theme=uckk

## Action demandée

Ouvrir Moodle local

## Cible

Moodle local

## Niveau de danger

0

## Mode

navigation

## Source utilisée

Non applicable.

## Étapes exécutées

- {"name":"Vérifier Moodle local","status":"Échoué","summary":"Moodle local ne répond pas encore.","detail":"Aucune connexion n’a pu être établie car l’ordinateur cible l’a expressément refusée. (127.0.0.1:8000)","data":{"success":false,"url":"http://127.0.0.1:8000","statusCode":null,"detail":"Aucune connexion n’a pu être établie car l’ordinateur cible l’a expressément refusée. (127.0.0.1:8000)"},"timestamp":"2026-09-25 18:06:16"}
- {"name":"Démarrer Moodle local","status":"Réussi","summary":"Réussi — Moodle local a été démarré et répond : http://127.0.0.1:8000","detail":"Ouvrir Moodle local ou tester les pages locales.","data":{"success":true,"status":"Réussi","action":"Démarrer Moodle local","domain":"local","target":"Moodle local","dangerLevel":2,"mode":"application","summary":"Réussi — Moodle local a été démarré et répond : http://127.0.0.1:8000","warnings":[],"errors":[],"nextStep":"Ouvrir Moodle local ou tester les pages locales.","reportPath":"","logPath":"","data":{"baseUrl":"http://127.0.0.1:8000","localRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","phpBinary":"php","arguments":["-S","127.0.0.1:8000","-t","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"processId":48948,"readyCheck":{"success":true,"url":"http://127.0.0.1:8000","statusCode":200,"detail":"OK"}},"steps":[{"name":"Lancer serveur PHP local","status":"Réussi","summary":"Serveur PHP local lancé.","detail":"php -S 127.0.0.1:8000 -t C:\\mycode\\UCKK\\moodle\\moodle\\public","data":{"runtime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","baseUrl":"http://127.0.0.1:8000","processId":48948},"timestamp":"2026-09-25 18:06:18"},{"name":"Attendre Moodle local","status":"Réussi","summary":"Moodle local répond.","detail":"http://127.0.0.1:8000","data":{"success":true,"url":"http://127.0.0.1:8000","statusCode":200,"detail":"OK"},"timestamp":"2026-09-25 18:06:21"}],"startedAt":"2026-09-25 18:06:16","finishedAt":"2026-09-25 18:06:21","durationSeconds":5.0},"timestamp":"2026-09-25 18:06:21"}
- {"name":"Ouvrir navigateur","status":"Réussi","summary":"Navigateur ouvert.","detail":"http://127.0.0.1:8000/?theme=uckk","data":null,"timestamp":"2026-09-25 18:06:21"}

## Changements

Non applicable.

## Avertissements

Aucun.

## Erreurs

Aucune.

## Résultat final

Échoué

## Prochaine étape

Vérifier la page dans le navigateur.

## Détail technique

~~~text
Domaine : local
Statut : Échoué
Généré le : 2026-09-25 18:06:21
Fuseau horaire : Eastern Standard Time
Log technique : C:\mycode\UCKK\UCKK_ops_console\logs\20260925_180621_local_ouvrir_moodle_local_moodle_local.log
~~~

## Données structurées

~~~text
{"baseUrl":"http://127.0.0.1:8000","url":"http://127.0.0.1:8000/?theme=uckk","baseCheck":{"success":true,"url":"http://127.0.0.1:8000","statusCode":200,"detail":"OK"}}
~~~