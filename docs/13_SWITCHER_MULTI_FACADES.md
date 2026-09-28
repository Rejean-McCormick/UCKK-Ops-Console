# 13 — Switcher multi-façades UCKK / UCC / Math

## 1. But

L'Ops Console exploite une seule instance Moodle qui expose trois façades publiques :

- **UCKK** → thème Moodle `uckk` ;
- **UCC — Univers-Cité Catho** → thème Moodle `ucc` ;
- **Math — Univers-Cité des mathématiques** → thème Moodle `ucmath`.

Le choix de façade repose sur le mécanisme Moodle de changement de thème par URL/session. L'Ops Console ne crée ni cookie parallèle, ni base parallèle, ni registre de session propre.

## 2. Configuration

Les façades sont décrites dans `publicFacades.sites`.

Chaque entrée contient :

- `id` : identifiant Ops Console ;
- `label` : texte UI ;
- `theme` : shortname du thème Moodle ;
- `expectedMarker` : texte attendu sur la page d'accueil pour confirmer que le contenu a basculé.

Les pages HTTP de diagnostic sont dans `publicFacades.testPaths`.

## 3. Préparation locale

Le bouton **Préparer local et ouvrir Moodle** exécute :

1. Vérifier la configuration ;
2. Vérifier les chemins locaux ;
3. Synchroniser `uckk-moodle` vers le runtime Moodle local ;
4. Exécuter `admin/cli/upgrade.php --non-interactive` ;
5. Purger les caches Moodle locaux ;
6. Démarrer Moodle local ;
7. Ouvrir la façade UCKK.

L'étape 4 peut modifier la base Moodle locale. Le workflow demande donc une confirmation unique avant de démarrer.

## 4. Navigation

L'onglet **Local** expose :

- Ouvrir UCKK ;
- Ouvrir UCC ;
- Ouvrir Math.

Les URLs sont dérivées de `urls.localBase` :

```text
/?theme=uckk
/?theme=ucc
/?theme=ucmath
```

Aucune URL locale n'est codée en dur dans les handlers.

## 5. Diagnostic du switcher

L'action **Tester switcher UCKK / UCC / Math** :

- teste chaque façade avec son paramètre `theme` ;
- teste les principales pages publiques configurées ;
- exige un statut HTTP 2xx/3xx ;
- sur l'accueil, cherche `expectedMarker` pour détecter le cas où Moodle ignore `?theme=`.

Si UCC ou Math retourne l'identité UCKK, vérifier dans Moodle :

**Administration du site → Apparence → Thèmes → Réglages des thèmes → Autoriser le changement de thème dans l'URL.**

Puis purger les caches et relancer le test.

## 6. Frontière architecturale

Le switcher ne change pas la propriété des données :

- code/source versionnée → `uckk-moodle` ;
- état actif → base Moodle ;
- fichiers → moodledata ;
- les trois façades partagent les mêmes services Moodle et permissions.

Les thèmes sont des frontières de présentation, pas des frontières de sécurité.

## 7. Publication serveur

Le workflow serveur reste protégé par confirmation. L'ajout du switcher ne transforme pas l'Ops Console en système de multitenancy.

L'action **Vérifier uckk.org — UCKK / UCC / Math** teste également :

```text
/?theme=uckk
/?theme=ucc
/?theme=ucmath
```

et confirme le marqueur d'identité attendu de chaque façade. Si le serveur ignore `?theme=`, la vérification échoue volontairement.

Avant publication :

1. valider les trois façades localement ;
2. vérifier Git ;
3. publier avec le workflow serveur ;
4. exécuter la vérification des trois façades sur le serveur.
