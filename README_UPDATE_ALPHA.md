# Mise à jour Ops Console — diagnostic PS7 + Moodle instable

Appliquer cet overlay sur la version Ops Console verbose/switcher courante.

Changements :
- diagnostic Moodle local lit `version.php` et affiche version/release/branche/maturité ;
- Alpha/Beta/RC sont signalés comme versions instables ;
- l'upgrade local ajoute `--allow-unstable` uniquement après la confirmation normale de l'action ;
- la maturité, le flag et la commande finale sont présents dans les résultats verboses/rapports/logs ;
- `tools/Diagnose-UckkMoodleLocal.ps1` fournit le même diagnostic en PowerShell 7 standalone et lecture seule.

Aucune politique PowerShell globale n'est changée.

## Mise à jour Médiathèque site-wide — 2026-09-28

- `Vérifier Médiathèque locale` accepte maintenant la cible site-wide `0/0/0/0` ;
- une configuration mixte entre zéros et IDs positifs est refusée ;
- les IDs négatifs sont refusés ;
- la simulation/application avec une cible site-wide reste bloquée tant que le pipeline d'écriture n'est pas pleinement *library-aware* ;
- `Get-UckkMediathequeTargetSettings` expose maintenant `targetMode` (`site-wide`, `activity-bound` ou `invalid`) dans les données de diagnostic.

## Alignement VPS UCKK Publisher — 2026-09-28

- les valeurs serveur par défaut de l’Ops Console reprennent désormais le VPS configuré dans `UCKK Publisher` ;
- la cible SSH par défaut utilise `kx-admin` sur le VPS Netcup Publisher ;
- `sshPort` et le chemin `sshKey` sont désormais présents dans la configuration Ops Console ;
- les exécutions SSH serveur prennent effectivement en compte le port et la clé configurés ;
- `remoteRoot`, `domain`, `konnaxionInstance`, `konnaxionRoot` et `edgeNetwork` sont conservés comme métadonnées serveur alignées sur Publisher ;
- aucun contenu de clé privée ni mot de passe n’est intégré à la configuration.

## 2026-09-28 — Publication vers uckk.org : ne plus ouvrir localhost

- Corrigé le workflow d’accueil `Publier jusqu’à uckk.org`.
- Suppression de l’étape `local.open_uckk` de la chaîne de publication.
- Moodle local peut toujours être préparé/démarré pour les contrôles préalables, mais `127.0.0.1:8000` n’est plus ouvert automatiquement.
- Après une publication réussie, seule l’action finale `server.open_public_site` ouvre `urls.serverBase` (`https://uckk.org`).
- En cas d’échec avant la fin de la chaîne, aucun navigateur local n’est ouvert comme résultat de la publication.

### 2026-09-28 — SSH serveur aligné sur UCKK Publisher

- ajout de `-T` et `StrictHostKeyChecking=accept-new` à l'appel OpenSSH ;
- authentification forcée en clé publique (`PreferredAuthentications=publickey`) ;
- mot de passe et keyboard-interactive désactivés ;
- vérification explicite de l'existence de la clé SSH avant connexion ;
- `connectTimeoutSeconds` par défaut fixé à `12`, comme UCKK Publisher ;
- diagnostic de connexion enrichi avec port, chemin de clé, présence de la clé et timeout ;
- corrige notamment le cas où la première connexion pouvait rester bloquée sur la confirmation d'empreinte du VPS puis finir en code `124`.

