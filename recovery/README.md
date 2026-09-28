# Recovery

## Role

This folder contains recovery tools only.

Recovery tools are used when the normal workflow is broken and a controlled repair is needed.

They are not part of the normal workflow.

## Definition

Recovery means:

```text
repairing a broken state with a special, higher-risk action
````

Examples:

```text
wipe
rebuild
restore from backup
repair tables
reconstruct links
compare local and server deeply
recover from a failed publish
```

## Rule

Nothing in this folder should run automatically.

Nothing in this folder should be called from:

```text
Accueil
Local
Git
Serveur
Médiathèque
Données Moodle
Tests
Historique
```

Recovery actions may only be exposed through:

```text
Récupération
```

## Danger level

Recovery actions are normally:

```text
Danger level 7 — Récupération
```

Any recovery action that modifies data must require:

```text
strong confirmation
backup
report
technical log
clear source
clear target
```

## Required confirmation

Before a recovery action modifies anything, the application must show:

```text
This action is a recovery action, not a normal operation.
It can modify several data sets.
A backup must exist before continuing.
Continue?
```

French UI version:

```text
Cette action est une récupération, pas une opération normale.
Elle peut modifier plusieurs données.
Une sauvegarde doit exister avant de continuer.
Continuer ?
```

## Backup rule

No destructive recovery action may run without a verified backup.

Destructive means:

```text
delete
replace
rebuild
restore over existing data
copy tables over existing tables
```

Rule:

```text
No verified backup = no destructive recovery.
```

## Reports

Every recovery action must produce a readable report.

The report must include:

```text
action name
reason for recovery
danger level
backup used or created
source read
target modified
data created
data updated
data deleted
warnings
errors
final result
next verification
rollback option if possible
```

## Logs

Every recovery action must produce a technical log.

The log may include:

```text
commands
paths
timestamps
exit codes
stdout
stderr
technical errors
```

The log must not include:

```text
passwords
tokens
private keys
database secrets
server config.php contents
personal data
```

## Forbidden as normal workflow

The following must never become normal workflow actions:

```text
wipe
rebuild
SQL dump import
direct table copy
restore from backup
public page export as source of truth
legacy importer
dated repair script
manual server repair
```

## Médiathèque recovery

Médiathèque recovery may include:

```text
rebuild from external_work
rebuild collections
repair media/media_source links
compare expected count with actual count
restore from backup
```

But the normal Médiathèque workflow remains:

```text
manifest → simulation → apply → verify
```

Recovery must not replace that workflow.

## Données Moodle recovery

Données Moodle recovery may include:

```text
restore data from backup
repair broken categories
repair broken course links
compare JSON source with Moodle state
```

But the normal Données Moodle workflow remains:

```text
source file → validation → simulation → apply → verify
```

Recovery must not replace that workflow.

## Legacy relationship

Some legacy tools may be useful during recovery.

But a legacy tool must not run until it is classified as:

```text
legacy
recovery
test
normal
```

Unclassified tools must not run.

## Naming rule

Recovery scripts must have clear names.

Good names:

```text
Compare-UckkMediathequeLocalServer.ps1
Backup-UckkMediathequeServer.ps1
Restore-UckkMediathequeServerFromBackup.ps1
Rebuild-UckkMediathequeCollections.ps1
```

Bad names:

```text
fix.ps1
repair.ps1
run_old.ps1
final-working.ps1
v9.ps1
tmp.ps1
```

## Startup rule

Recovery tools must never run when the app starts.

At startup, the app may only:

```text
load configuration
validate configuration
create reports/logs folders
show the interface
```

## Final rule

Recovery is allowed only when the normal path is broken.

The normal path must stay simple, documented and safe.

```text
Recovery repairs.
Recovery does not define the normal workflow.
```

