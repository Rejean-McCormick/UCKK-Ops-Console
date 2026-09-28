# Rapport — Diagnostiquer Moodle local

## Résumé

Statut : Réussi

Réussi — Moodle CLI est prêt. Racine CLI : C:\mycode\UCKK\moodle\moodle

## Action demandée

Diagnostiquer Moodle local

## Cible

Moodle local

## Niveau de danger

1

## Mode

vérification

## Source utilisée

Non applicable.

## Étapes exécutées

- {"name":"Vérifier PHP CLI","status":"Réussi","summary":"PHP CLI répond.","detail":"Commande : php -v\r\nDossier courant : C:\\mycode\\UCKK\\moodle\\moodle\r\nCode de sortie : 0\r\nTimeout : False\r\nDurée : 0.211 s\r\n\r\nSTDOUT :\r\nPHP 8.4.21 (cli) (built: May  6 2026 09:30:51) (NTS Visual C++ 2022 x64)\nCopyright (c) The PHP Group\nBuilt by The PHP Group\nZend Engine v4.4.21, Copyright (c) Zend Technologies\n    with Zend OPcache v8.4.21, Copyright (c), by Zend Technologies\r\n\r\nSTDERR :\r\n(vide)","data":{"success":true,"timedOut":false,"exitCode":0,"stdout":"PHP 8.4.21 (cli) (built: May  6 2026 09:30:51) (NTS Visual C++ 2022 x64)\nCopyright (c) The PHP Group\nBuilt by The PHP Group\nZend Engine v4.4.21, Copyright (c) Zend Technologies\n    with Zend OPcache v8.4.21, Copyright (c), by Zend Technologies\n","stderr":"","filePath":"php","arguments":["-v"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSeconds":30,"commandLine":"php -v","startedAt":"2026-09-25 17:42:38.775","finishedAt":"2026-09-25 17:42:38.986","durationSeconds":0.211},"timestamp":"2026-09-25 17:42:39"}
- {"name":"Lire version et maturité Moodle","status":"Réussi","summary":"Maturité Moodle : MATURITY_STABLE","detail":"version.php retenu : C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php\r\nversion.php testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\version.php => absent\r\nVersion : 2026042003.01\r\nRelease : 5.2.3+ (Build: 20260916)\r\nBranche : 502\r\nMaturité : MATURITY_STABLE\r\n--allow-unstable requis : False\r\nMéthode de lecture : line-assignment","data":{"success":true,"versionFile":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php","versionFileCandidates":["C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php","C:\\mycode\\UCKK\\moodle\\moodle\\version.php"],"version":"2026042003.01","release":"5.2.3+ (Build: 20260916)","branch":"502","maturity":"MATURITY_STABLE","isUnstable":false,"allowUnstableRequired":false,"parseMethod":"line-assignment","parseError":""},"timestamp":"2026-09-25 17:42:39"}
- {"name":"Résoudre admin/cli/upgrade.php","status":"Réussi","summary":"Script trouvé dans C:\\mycode\\UCKK\\moodle\\moodle.","detail":"Racine code configurée : C:\\mycode\\UCKK\\moodle\\moodle\r\nWebroot configuré : C:\\mycode\\UCKK\\moodle\\moodle\\public\r\nScript demandé : admin/cli/upgrade.php\r\nScript résolu : C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php\r\n\r\nChemins testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php => absent\r\n\r\nconfig.php testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\config.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php => trouvé","data":{"success":true,"scriptRelativePath":"admin/cli/upgrade.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"timestamp":"2026-09-25 17:42:39"}
- {"name":"Résoudre admin/cli/purge_caches.php","status":"Réussi","summary":"Script trouvé dans C:\\mycode\\UCKK\\moodle\\moodle.","detail":"Racine code configurée : C:\\mycode\\UCKK\\moodle\\moodle\r\nWebroot configuré : C:\\mycode\\UCKK\\moodle\\moodle\\public\r\nScript demandé : admin/cli/purge_caches.php\r\nScript résolu : C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php\r\n\r\nChemins testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php => absent\r\n\r\nconfig.php testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\config.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php => trouvé","data":{"success":true,"scriptRelativePath":"admin/cli/purge_caches.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"timestamp":"2026-09-25 17:42:39"}

## Changements

Non applicable.

## Avertissements

Aucun.

## Erreurs

Aucune.

## Résultat final

Réussi

## Prochaine étape

Synchroniser les plugins puis lancer l upgrade Moodle local.

## Détail technique

~~~text
Domaine : local
Statut : Réussi
Généré le : 2026-09-25 17:42:39
Fuseau horaire : Eastern Standard Time
Log technique : C:\mycode\UCKK\UCKK_ops_console\logs\20260925_174239_local_diagnostiquer_moodle_local_moodle_local.log
~~~

## Données structurées

~~~text
{"phpBinary":"php","phpCheck":{"success":true,"timedOut":false,"exitCode":0,"stdout":"PHP 8.4.21 (cli) (built: May  6 2026 09:30:51) (NTS Visual C++ 2022 x64)\nCopyright (c) The PHP Group\nBuilt by The PHP Group\nZend Engine v4.4.21, Copyright (c) Zend Technologies\n    with Zend OPcache v8.4.21, Copyright (c), by Zend Technologies\n","stderr":"","filePath":"php","arguments":["-v"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSeconds":30,"commandLine":"php -v","startedAt":"2026-09-25 17:42:38.775","finishedAt":"2026-09-25 17:42:38.986","durationSeconds":0.211},"releaseInfo":{"success":true,"versionFile":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php","versionFileCandidates":["C:\\mycode\\UCKK\\moodle\\moodle\\public\\version.php","C:\\mycode\\UCKK\\moodle\\moodle\\version.php"],"version":"2026042003.01","release":"5.2.3+ (Build: 20260916)","branch":"502","maturity":"MATURITY_STABLE","isUnstable":false,"allowUnstableRequired":false,"parseMethod":"line-assignment","parseError":""},"upgradeContext":{"success":true,"scriptRelativePath":"admin/cli/upgrade.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"purgeContext":{"success":true,"scriptRelativePath":"admin/cli/purge_caches.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]}}
~~~