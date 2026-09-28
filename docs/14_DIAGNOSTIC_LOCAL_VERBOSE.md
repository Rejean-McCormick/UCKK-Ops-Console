# Diagnostic Moodle local et résultats verboses

## But

Cette version de l'Ops Console distingue explicitement :

- `paths.localMoodleRoot` : racine du code Moodle utilisée pour les commandes CLI ;
- `paths.localMoodleRuntime` : webroot servi par le serveur PHP local.

Dans l'installation actuelle :

```text
C:\mycode\UCKK\moodle\moodle
    = racine Moodle / CLI

C:\mycode\UCKK\moodle\moodle\public
    = webroot HTTP
```

L'Ops Console ne suppose toutefois plus aveuglément un emplacement. Pour chaque script CLI,
elle teste la racine Moodle, le webroot configuré et `localMoodleRoot/public`, puis rapporte
chaque chemin testé.

## Nouvelle action

L'onglet **Local** et l'onglet **Tests** contiennent :

```text
Diagnostiquer Moodle local
```

Cette action vérifie sans modifier la base :

1. le binaire PHP CLI ;
2. `php -v` ;
3. la racine Moodle configurée ;
4. le webroot configuré ;
5. `admin/cli/upgrade.php` ;
6. `admin/cli/purge_caches.php` ;
7. les emplacements possibles de `config.php`.

Elle affiche le chemin retenu et tous les candidats rejetés.

## Upgrade et purge

`Mettre à jour Moodle local` et `Purger les caches locaux` affichent maintenant :

```text
Commande
Dossier courant
Code de sortie
Timeout
Durée
STDOUT
STDERR
```

En cas d'échec, le message d'erreur reprend également la sortie PHP la plus utile.

## Bouton Accueil

La chaîne **Préparer local et ouvrir Moodle** exécute désormais :

```text
configuration
→ chemins locaux
→ diagnostic Moodle CLI
→ synchronisation source vers runtime
→ upgrade Moodle
→ purge caches
→ démarrage
→ ouverture UCKK
```

Si une étape échoue, le résultat composite conserve `failedResult`, c'est-à-dire le résultat
complet de l'étape fautive. L'UI développe automatiquement ce résultat.

## Rapports et logs

Les actions marquées `ProducesReport` et `ProducesLog` écrivent maintenant effectivement :

```text
reports/*.md
logs/*.log
```

Le rapport contient les données structurées du résultat.
Le log contient le résultat technique complet avec masquage des motifs sensibles déjà fourni
par `UckkOps.Log.psm1`.

## Verbosité UI

Configuration :

```json
"ui": {
  "verboseResults": true,
  "maxCommandOutputChars": 20000
}
```

`verboseResults = true` affiche les étapes détaillées et les processus.

L'UI limite une très longue sortie de commande pour rester utilisable. Le résultat structuré
reste disponible dans le rapport/log.

## Sécurité

Le diagnostic ne modifie pas Moodle.

L'upgrade local conserve sa confirmation obligatoire car il peut modifier la base locale.


## Barre de résultats

La barre sous les onglets contient maintenant :

```text
Copier le log
Effacer le log
Ouvrir rapport
Ouvrir log
```

`Ouvrir rapport` et `Ouvrir log` ciblent les artefacts de la dernière action exécutée.

## Diagnostic PowerShell 7 de la maturité Moodle

Le diagnostic local lit aussi `version.php` dans la racine code Moodle et affiche :

```text
Version
Release
Branche
Maturité
--allow-unstable requis : True/False
```

Les maturités suivantes sont considérées instables pour l'upgrade CLI :

```text
MATURITY_ALPHA
MATURITY_BETA
MATURITY_RC
```

Si une de ces maturités est détectée, **Diagnostiquer Moodle local** reste strictement en lecture seule et affiche un avertissement.

L'action **Mettre à jour Moodle local**, qui exige déjà une confirmation, ajoute alors :

```text
--allow-unstable
```

à cette commande uniquement. Le flag, la maturité et la ligne de commande finale sont consignés dans le résultat verbose, le rapport et le log. Aucun réglage global de Moodle, PHP ou PowerShell n'est modifié.
