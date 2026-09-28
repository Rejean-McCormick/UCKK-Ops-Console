# Rapport — Mettre à jour Moodle local

## Résumé

Statut : Réussi

Réussi — Moodle local est à jour.

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

- {"name":"Vérifier script upgrade Moodle","status":"Réussi","summary":"Script Moodle trouvé.","detail":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","data":null,"timestamp":"2026-09-24 22:23:54"}
- {"name":"Exécuter upgrade Moodle local","status":"Réussi","summary":"Upgrade Moodle local terminé.","detail":"","data":{"success":true,"timedOut":false,"exitCode":0,"stdout":"","stderr":"Aucune mise à jour nécessaire pour la version installée 5.2.3+ (Build: 20260916) (2026042003.01). C’était quand même sympa de venir !\r\n\r\n","filePath":"php","arguments":["C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","--non-interactive"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSecond":600},"timestamp":"2026-09-24 22:23:58"}

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
Généré le : 2026-09-24 22:23:58
Fuseau horaire : Eastern Standard Time
Log technique : C:\mycode\UCKK\UCKK_ops_console\logs\20260924_222358_local_mettre_a_jour_moodle_local_base_moodle_locale.log
~~~

## Données structurées

~~~text
{"phpBinary":"php","upgradeRoot":"C:\\mycode\\UCKK\\moodle\\moodle","upgradeScript":"C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","candidateRoots":["C:\\mycode\\UCKK\\moodle\\moodle\\public","C:\\mycode\\UCKK\\moodle\\moodle"],"process":{"success":true,"timedOut":false,"exitCode":0,"stdout":"","stderr":"Aucune mise à jour nécessaire pour la version installée 5.2.3+ (Build: 20260916) (2026042003.01). C’était quand même sympa de venir !\r\n\r\n","filePath":"php","arguments":["C:\\mycode\\UCKK\\moodle\\moodle\\admin\\cli\\upgrade.php","--non-interactive"],"workingDir":"C:\\mycode\\UCKK\\moodle\\moodle","timeoutSecond":600}}
~~~