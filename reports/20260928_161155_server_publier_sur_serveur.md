# Rapport — Publier sur serveur

## Résumé

Statut : Échoué

L action a échoué. Cause probable : la source serveur n a pas pu être mise à jour depuis Git.

## Action demandée

Publier sur serveur

## Cible

uckk.org

## Niveau de danger

5

## Mode

publication

## Source utilisée

Serveur : kx-admin@2.56.97.41

## Étapes exécutées

- En cours — Publier sur serveur — Chaîne de publication démarrée.
- Réussi — Tester connexion serveur — Connexion serveur fonctionnelle.
- Échoué — Récupérer dernier code sur serveur — L action a échoué. Cause probable : Git ne peut pas mettre à jour la source serveur.

## Changements

Non applicable ou voir le détail de l action.

## Avertissements

Aucun.

## Erreurs

- Publication arrêtée : récupération Git serveur échouée.

## Résultat final

Échoué

## Prochaine étape

Lire le rapport Git serveur avant de relancer.

## Détail technique

Rapport : .\reports\20260928_161155_server_publier_sur_serveur.md

Log technique : .\logs\20260928_161155_server_publier_sur_serveur.log

Données :

`json
{
  "subResults": [
    {
      "success": true,
      "status": "Réussi",
      "action": "Tester connexion serveur",
      "domain": "server",
      "target": "serveur",
      "dangerLevel": 1,
      "mode": "vérification",
      "summary": "Réussi — la connexion serveur fonctionne.",
      "warnings": [],
      "errors": [],
      "nextStep": "Aucune action requise.",
      "reportPath": ".\\reports\\20260928_160855_server_tester_connexion_serveur.md",
      "logPath": ".\\logs\\20260928_160855_server_tester_connexion_serveur.log",
      "data": {
        "sshTarget": "kx-admin@2.56.97.41",
        "stdout": "UCKK_SERVER_OK\nv2202609415365517006\nkx-admin\n",
        "sshKeyExists": true,
        "sshPort": 22,
        "connectTimeoutSeconds": 12,
        "sshKey": "C:/Users/rejea/.ssh/id_ed25519"
      },
      "steps": [
        {
          "name": "Lire configuration serveur",
          "status": "Réussi",
          "summary": "kx-admin@2.56.97.41 port 22",
          "detail": ""
        },
        {
          "name": "Tester SSH",
          "status": "Réussi",
          "summary": "La connexion serveur fonctionne.",
          "detail": ""
        }
      ]
    },
    {
      "success": false,
      "status": "Échoué",
      "action": "Récupérer dernier code sur serveur",
      "domain": "server",
      "target": "source serveur",
      "dangerLevel": 5,
      "mode": "publication",
      "summary": "L action a échoué. Cause probable : Git ne peut pas mettre à jour la source serveur.",
      "warnings": [],
      "errors": [
        "Code de retour SSH : 124"
      ],
      "nextStep": "Lire le rapport et vérifier l état Git serveur.",
      "reportPath": ".\\reports\\20260928_161155_server_r_cup_rer_dernier_code_sur_serveur.md",
      "logPath": ".\\logs\\20260928_161155_server_r_cup_rer_dernier_code_sur_serveur.log",
      "data": {
        "stderr": "\r\nSSH command timed out after 180 seconds.",
        "exitCode": 124
      },
      "steps": [
        {
          "name": "Récupérer dernier code sur serveur",
          "status": "Échoué",
          "summary": "Git pull a échoué sur le serveur.",
          "detail": ""
        }
      ]
    }
  ]
}
``

