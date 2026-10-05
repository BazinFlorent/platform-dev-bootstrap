# Fondation Crossplane

Crossplane fait partie de la **fondation de la plateforme et de son plan de contrôle**.

Sa version est définie dans `core/versions.env`. La version du cœur Crossplane ne doit pas être codée en dur dans les scripts de bootstrap.

## Installation

Prérequis :

- un cluster Kubernetes/Kind opérationnel ;
- `kubectl` ;
- `helm`.

```bash id="c6bg2p"
./bootstrap/crossplane/scripts/install.sh
./bootstrap/crossplane/scripts/verify.sh
```

L'installation peut également être contrôlée avec :

```bash id="fxgmgq"
kubectl get pods -n crossplane-system
helm list -n crossplane-system
```

## Spike minimal

Le spike valide le fonctionnement du plan de contrôle Crossplane indépendamment de vLLM ou de tout autre plan d'exécution.

Il valide la chaîne complète de réconciliation :

```text id="5kghsi"
PlatformTest XRD
      |
      v
PlatformTest XR
      |
      v
Composition
      |
      v
function-patch-and-transform
      |
      v
ConfigMap
```

Le spike historique a validé cette chaîne de réconciliation. Les scripts associés ne font plus partie du bootstrap générique.

### Résultat attendu

La ressource composée doit être créée :

```text id="ns12ip"
ConfigMap/crossplane-spike-hello
```

et la ressource composite doit atteindre l'état :

```text id="u58n8s"
SYNCED=True
READY=True
```

Vérification :

```bash id="5q0d2s"
kubectl get platformtest hello -n default
```

État attendu :

```text id="dg42yj"
NAME    SYNCED   READY   COMPOSITION
hello   True     True    platformtest-minimal
```

Le script du spike doit se terminer avec :

```text id="5e7ilj"
SUCCESS: XRD -> XR -> Composition -> ConfigMap reconciliation works.
```

### Gestion de la disponibilité

Un `ConfigMap` Kubernetes n'expose pas de condition `Ready`.

La `Composition` du spike indique donc explicitement que la ressource composée est considérée comme disponible dès qu'elle existe :

```yaml id="2qf3ij"
readinessChecks:
  - type: None
```

Sans cette vérification de disponibilité, la ressource peut être correctement créée et réconciliée alors que la ressource composite reste dans l'état :

```text id="0i8xrz"
SYNCED=True
READY=False
```

### Inspection

```bash id="m2td9m"
kubectl get platformtests -A
kubectl describe platformtest hello -n default
kubectl get configmap crossplane-spike-hello -n default -o yaml
kubectl get compositions
kubectl get compositionrevisions
```

La `Composition Function` validée par le spike appartient à la fondation Crossplane et non à une expérimentation spécifique.

## Socle validé

Le spike initial a permis de valider la chaîne suivante sur l'environnement Kind local :

```text id="tz3fpi"
XRD
  -> XR
  -> Composition
  -> Composition Function
  -> Ressource Kubernetes
  -> Réconciliation Crossplane
```

La ressource `PlatformTest` obtenue atteint bien :

```text id="e7oqjp"
SYNCED=True
READY=True
```

Cette validation constitue le socle Crossplane minimal nécessaire avant l'introduction des véritables contrats de capacités de la plateforme.

## Politique de mise à niveau

Le cœur Crossplane et les `Composition Functions` sont versionnés indépendamment dans la BOM.

Pour une mise à niveau :

1. consulter les notes de version du projet ;
2. mettre à jour `core/versions.env` ;
3. réinstaller avec `install.sh` ;
4. exécuter `verify.sh` ;
5. exécuter le spike ;
6. exécuter les tests de contrats et les tests E2E des capacités ;
7. documenter les migrations lorsque cela est nécessaire.

Les versions mineures de Crossplane doivent être mises à niveau séquentiellement, sans saut de version mineure.

## Politique de configuration

`values.yaml` contient uniquement les valeurs explicitement gérées par la plateforme.

Les valeurs complètes du chart Helm amont ne doivent pas être copiées dans ce dépôt.

L'objectif est de conserver uniquement les choix de configuration dont la plateforme souhaite explicitement être propriétaire.

## Périmètre actuel

Inclus actuellement :

- cœur Crossplane ;
- modèle XRD `Namespaced` de Crossplane v2 ;
- une `Composition Function` versionnée ;
- scripts d'installation et de vérification ;
- gestion des versions via la BOM ;
- spike minimal de réconciliation XRD / XR / Composition.

Pas encore inclus :

- Providers ;
- Compositions de production ;
- `Model` ;
- `ModelServing` ;
- vLLM ;
- Backstage.

## Prochaine étape

La prochaine expérimentation concerne le runtime d'inférence vLLM.

La progression prévue est :

```text id="07dlk9"
Kind
  -> Crossplane
  -> Spike vLLM
  -> Contrats Model / ModelServing
  -> Composition Crossplane
```

vLLM sera d'abord validé comme runtime d'exécution indépendamment de Crossplane.

Une fois son installation, son fonctionnement et son exposition rendus reproductibles, il pourra être intégré derrière le contrat de plateforme `ModelServing`.