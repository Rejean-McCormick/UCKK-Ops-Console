# Rapport — Mettre à jour Moodle local

## Résumé

Statut : Réussi

Réussi — Moodle local est à jour. Racine CLI utilisée : C:\mycode\UCKK\moodle\moodle

## Action demandée

Mettre à jour Moodle local

## Cible

base Moodle locale

## Niveau de danger

3

## Mode

application

## Source utilisée

Non applicable.

## Étapes exécutées

- {"name":"Résoudre racine CLI Moodle","status":"Réussi","summary":"Script upgrade Moodle trouvé.","detail":"Racine code Moodle : C:\\mycode\\UCKK\\moodle\\moodle\r\nWebroot Moodle : C:\\mycode\\UCKK\\moodle\\moodle\\public\r\nScript demandé : admin/cli/upgrade.php\r\nRacine CLI retenue : C:\\mycode\\UCKK\\moodle\\moodle\r\nScript retenu : C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php\r\nversion.php retenu : C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php\r\nVersion Moodle : 2026042003.01\r\nRelease Moodle : 5.2.3+ (Build: 20260916)\r\nMaturité Moodle : MATURITY_STABLE\r\n--allow-unstable requis : False\r\nMéthode de lecture version.php : line-assignment\r\n\r\nCandidats testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php => absent","data":{"success":true,"scriptRelativePath":"admin/cli/upgrade.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"timestamp":"2026-09-28 14:41:10"}
- {"name":"Exécuter upgrade Moodle local","status":"Réussi","summary":"Upgrade Moodle local terminé.","detail":"Commande : php C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php --non-interactive\r\nDossier courant : C:\\mycode\\UCKK\\moodle\\moodle\r\nCode de sortie : 0\r\nTimeout : False\r\nDurée : 3.43 s\r\n\r\nSTDOUT :\r\n(vide)\r\n\r\nSTDERR :\r\nAucune mise à jour nécessaire pour la version installée 5.2.3+ (Build: 20260916) (2026042003.01). C’était quand même sympa de venir !","data":{"success":true,"timedOut":false,"exitCode":0,"stdout":"","stderr":"Aucune mise à jour nécessaire pour la version installée 5.2.3+ (Build: 20260916) (2026042003.01). C’était quand même sympa de venir !\r\n\r\n","filePath":"php","arguments":["C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","--non-interactive"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSeconds":600,"commandLine":"php C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php --non-interactive","startedAt":"2026-09-28 14:41:10.263","finishedAt":"2026-09-28 14:41:13.693","durationSeconds":3.43},"timestamp":"2026-09-28 14:41:13"}

## Changements

Non applicable.

## Avertissements

Aucun.

## Erreurs

Aucune.

## Résultat final

Réussi

## Prochaine étape

Purger les caches locaux puis démarrer Moodle local.

## Détail technique

~~~text
Domaine : local
Statut : Réussi
Généré le : 2026-09-28 14:41:13
Fuseau horaire : Eastern Standard Time
Log technique : C:\mycode\UCKK\UCKK_ops_console\logs\20260928_144113_local_mettre_a_jour_moodle_local_base_moodle_locale.log
~~~

## Données structurées

~~~text
{"phpBinary":"php","cliContext":{"success":true,"scriptRelativePath":"admin/cli/upgrade.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"releaseInfo":{"success":true,"versionFile":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php","versionFileCandidates":["C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php","C:\\mycode\\UCKK\\moodle\\moodle\\version.php"],"version":"2026042003.01","release":"5.2.3+ (Build: 20260916)","branch":"502","maturity":"MATURITY_STABLE","isUnstable":false,"allowUnstableRequired":false,"parseMethod":"line-assignment","parseError":""},"upgradeArguments":["C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","--non-interactive"],"process":{"success":true,"timedOut":false,"exitCode":0,"stdout":"","stderr":"Aucune mise à jour nécessaire pour la version installée 5.2.3+ (Build: 20260916) (2026042003.01). C’était quand même sympa de venir !\r\n\r\n","filePath":"php","arguments":["C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","--non-interactive"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSeconds":600,"commandLine":"php C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php --non-interactive","startedAt":"2026-09-28 14:41:10.263","finishedAt":"2026-09-28 14:41:13.693","durationSeconds":3.43}}
~~~