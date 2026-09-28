# Rapport — Purger les caches locaux

## Résumé

Statut : Réussi

Réussi — les caches Moodle locaux ont été purgés. Racine CLI utilisée : C:\mycode\UCKK\moodle\moodle

## Action demandée

Purger les caches locaux

## Cible

Moodle local

## Niveau de danger

2

## Mode

application

## Source utilisée

Non applicable.

## Étapes exécutées

- {"name":"Résoudre racine CLI Moodle","status":"Réussi","summary":"Script de purge Moodle trouvé.","detail":"Racine code Moodle : C:\\mycode\\UCKK\\moodle\\moodle\r\nWebroot Moodle : C:\\mycode\\UCKK\\moodle\\moodle\\public\r\nScript demandé : admin/cli/purge_caches.php\r\nRacine CLI retenue : C:\\mycode\\UCKK\\moodle\\moodle\r\nScript retenu : C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php\r\n\r\nCandidats testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php => absent","data":{"success":true,"scriptRelativePath":"admin/cli/purge_caches.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"timestamp":"2026-09-25 07:38:11"}
- {"name":"Exécuter purge caches","status":"Réussi","summary":"Caches Moodle locaux purgés.","detail":"Commande : php C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php\r\nDossier courant : C:\\mycode\\UCKK\\moodle\\moodle\r\nCode de sortie : 0\r\nTimeout : False\r\nDurée : 2.652 s\r\n\r\nSTDOUT :\r\n(vide)\r\n\r\nSTDERR :\r\n(vide)","data":{"success":true,"timedOut":false,"exitCode":0,"stdout":"","stderr":"","filePath":"php","arguments":["C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSeconds":180,"commandLine":"php C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","startedAt":"2026-09-25 07:38:11.155","finishedAt":"2026-09-25 07:38:13.807","durationSeconds":2.652},"timestamp":"2026-09-25 07:38:13"}

## Changements

Non applicable.

## Avertissements

Aucun.

## Erreurs

Aucune.

## Résultat final

Réussi

## Prochaine étape

Ouvrir Moodle local et vérifier les pages concernées.

## Détail technique

~~~text
Domaine : local
Statut : Réussi
Généré le : 2026-09-25 07:38:13
Fuseau horaire : Eastern Standard Time
Log technique : C:\mycode\UCKK\UCKK_ops_console\logs\20260925_073813_local_purger_les_caches_locaux_moodle_local.log
~~~

## Données structurées

~~~text
{"phpBinary":"php","cliContext":{"success":true,"scriptRelativePath":"admin/cli/purge_caches.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"process":{"success":true,"timedOut":false,"exitCode":0,"stdout":"","stderr":"","filePath":"php","arguments":["C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSeconds":180,"commandLine":"php C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","startedAt":"2026-09-25 07:38:11.155","finishedAt":"2026-09-25 07:38:13.807","durationSeconds":2.652}}
~~~