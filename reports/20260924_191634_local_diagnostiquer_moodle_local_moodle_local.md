# Rapport — Diagnostiquer Moodle local

## Résumé

Statut : Réussi avec avertissements

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

- {"name":"Vérifier PHP CLI","status":"Réussi","summary":"PHP CLI répond.","detail":"Commande : php -v\r\nDossier courant : C:\\mycode\\UCKK\\moodle\\moodle\r\nCode de sortie : 0\r\nTimeout : False\r\nDurée : 0.233 s\r\n\r\nSTDOUT :\r\nPHP 8.4.21 (cli) (built: May  6 2026 09:30:51) (NTS Visual C++ 2022 x64)\nCopyright (c) The PHP Group\nBuilt by The PHP Group\nZend Engine v4.4.21, Copyright (c) Zend Technologies\n    with Zend OPcache v8.4.21, Copyright (c), by Zend Technologies\r\n\r\nSTDERR :\r\n(vide)","data":{"success":true,"timedOut":false,"exitCode":0,"stdout":"PHP 8.4.21 (cli) (built: May  6 2026 09:30:51) (NTS Visual C++ 2022 x64)\nCopyright (c) The PHP Group\nBuilt by The PHP Group\nZend Engine v4.4.21, Copyright (c) Zend Technologies\n    with Zend OPcache v8.4.21, Copyright (c), by Zend Technologies\n","stderr":"","filePath":"php","arguments":["-v"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSeconds":30,"commandLine":"php -v","startedAt":"2026-09-24 19:16:34.146","finishedAt":"2026-09-24 19:16:34.379","durationSeconds":0.233},"timestamp":"2026-09-24 19:16:34"}
- {"name":"Lire version et maturité Moodle","status":"Réussi avec avertissements","summary":"version.php non lisible ou maturité non détectée.","detail":"version.php : C:\\mycode\\UCKK\\moodle\\moodle\\version.php\r\nVersion : (non détectée)\r\nRelease : (non détectée)\r\nBranche : (non détectée)\r\nMaturité : (non détectée)\r\n--allow-unstable requis : False","data":{"success":false,"versionFile":"C:\\mycode\\UCKK\\moodle\\moodle\\version.php","version":"","release":"","branch":"","maturity":"","isUnstable":false,"allowUnstableRequired":false},"timestamp":"2026-09-24 19:16:34"}
- {"name":"Résoudre admin/cli/upgrade.php","status":"Réussi","summary":"Script trouvé dans C:\\mycode\\UCKK\\moodle\\moodle.","detail":"Racine code configurée : C:\\mycode\\UCKK\\moodle\\moodle\r\nWebroot configuré : C:\\mycode\\UCKK\\moodle\\moodle\\public\r\nScript demandé : admin/cli/upgrade.php\r\nScript résolu : C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php\r\n\r\nChemins testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php => absent\r\n\r\nconfig.php testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\config.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php => trouvé","data":{"success":true,"scriptRelativePath":"admin/cli/upgrade.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"timestamp":"2026-09-24 19:16:34"}
- {"name":"Résoudre admin/cli/purge_caches.php","status":"Réussi","summary":"Script trouvé dans C:\\mycode\\UCKK\\moodle\\moodle.","detail":"Racine code configurée : C:\\mycode\\UCKK\\moodle\\moodle\r\nWebroot configuré : C:\\mycode\\UCKK\\moodle\\moodle\\public\r\nScript demandé : admin/cli/purge_caches.php\r\nScript résolu : C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php\r\n\r\nChemins testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php => absent\r\n\r\nconfig.php testés :\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\config.php => trouvé\r\n- C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php => trouvé","data":{"success":true,"scriptRelativePath":"admin/cli/purge_caches.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"timestamp":"2026-09-24 19:16:34"}

## Changements

Non applicable.

## Avertissements

Aucun.

## Erreurs

Aucune.

## Résultat final

Réussi avec avertissements

## Prochaine étape

Synchroniser les plugins puis lancer l upgrade Moodle local.

## Détail technique

~~~text
Domaine : local
Statut : Réussi avec avertissements
Généré le : 2026-09-24 19:16:34
Fuseau horaire : Eastern Standard Time
Log technique : C:\mycode\UCKK\UCKK_ops_console\logs\20260924_191634_local_diagnostiquer_moodle_local_moodle_local.log
~~~

## Données structurées

~~~text
{"phpBinary":"php","phpCheck":{"success":true,"timedOut":false,"exitCode":0,"stdout":"PHP 8.4.21 (cli) (built: May  6 2026 09:30:51) (NTS Visual C++ 2022 x64)\nCopyright (c) The PHP Group\nBuilt by The PHP Group\nZend Engine v4.4.21, Copyright (c) Zend Technologies\n    with Zend OPcache v8.4.21, Copyright (c), by Zend Technologies\n","stderr":"","filePath":"php","arguments":["-v"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSeconds":30,"commandLine":"php -v","startedAt":"2026-09-24 19:16:34.146","finishedAt":"2026-09-24 19:16:34.379","durationSeconds":0.233},"releaseInfo":{"success":false,"versionFile":"C:\\mycode\\UCKK\\moodle\\moodle\\version.php","version":"","release":"","branch":"","maturity":"","isUnstable":false,"allowUnstableRequired":false},"upgradeContext":{"success":true,"scriptRelativePath":"admin/cli/upgrade.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\upgrade.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]},"purgeContext":{"success":true,"scriptRelativePath":"admin/cli/purge_caches.php","cliRoot":"C:\\mycode\\UCKK\\moodle\\moodle","scriptPath":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","localMoodleRoot":"C:\\mycode\\UCKK\\moodle\\moodle","localMoodleRuntime":"C:\\mycode\\UCKK\\moodle\\moodle\\public","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle","C:\\mycode\\UCKK\\moodle\\moodle\\public"],"probes":[{"root":"C:\\mycode\\UCKK\\moodle\\moodle","script":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\purge_caches.php","scriptExists":true,"rootExists":true},{"root":"C:\\mycode\\UCKK\\moodle\\moodle\\public","script":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\admin\\cli\\purge_caches.php","scriptExists":false,"rootExists":true}],"configProbes":[{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\config.php","exists":true},{"path":"C:\\mycode\\UCKK\\moodle\\moodle\\public\\config.php","exists":true}]}}
~~~