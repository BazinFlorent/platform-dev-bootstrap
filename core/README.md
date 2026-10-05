# Socle core

Le répertoire `core/` contient le socle générique du bootstrap de développement local.

Il est indépendant des projets consommateurs et ne suppose pas que le bootstrap soit embarqué dans leur repository.

## Composants

Le core fournit :

- un cluster Kubernetes local avec Kind ;
- un registry OCI local sécurisé en TLS ;
- la configuration du trust du registry dans containerd ;
- Crossplane ;
- la configuration du trust du registry dans Crossplane ;
- les commandes de vérification et de destruction associées.

## Prérequis

Les outils suivants doivent être disponibles dans le `PATH` :

| Outil | Usage |
|---|---|
| Git | gestion du code source |
| Docker | exécution de Kind et du registry OCI |
| kubectl | interaction avec Kubernetes |
| Kind | création du cluster local |
| Helm | installation de Crossplane |
| Crossplane CLI | développement et packaging des projets Crossplane |
| OpenSSL | génération du certificat TLS local |
| curl | vérifications HTTP/HTTPS |
| sed | génération de configuration |
| awk | scripts de bootstrap |

Vérification :

```bash
platform-bootstrap -n my-platform doctor
```

## Exemples d'installation sur Ubuntu / WSL Ubuntu

### Paquets de base

```bash
sudo apt update

sudo apt install -y \
  git \
  curl \
  openssl \
  ca-certificates
```

### kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
```

### Kind

```bash
curl -Lo ./kind \
  https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

### Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

### Crossplane CLI

Installer la CLI Crossplane selon la procédure officielle puis vérifier :

```bash
crossplane --version
```

### Docker

Le daemon Docker doit être accessible depuis l'environnement utilisé pour exécuter le bootstrap.

```bash
docker version
docker ps
```

Sous WSL2, Docker Desktop peut être utilisé avec l'intégration WSL activée.

## Paramétrage de l'instance

La variable principale est :

```bash
PLATFORM_BOOTSTRAP_NAME
```

Elle est normalement définie via la CLI :

```bash
platform-bootstrap -n my-platform bootstrap
```

Les objets techniques sont dérivés de ce nom.

### Nom du cluster Kind

```text
KIND_CLUSTER=<instance>
```

### Identité du registry

```text
REGISTRY_NAME=<instance>-registry
REGISTRY_HOST=registry.<instance>.local
```

### Répertoire de state

```text
~/.local/state/platform-bootstrap/<instance>/
```

## Ports

Variables disponibles :

```bash
KIND_HTTP_PORT
KIND_HTTPS_PORT
REGISTRY_PORT
```

Valeurs par défaut :

```text
HTTP      : 80
HTTPS     : 443
Registry  : 5000
```

Exemple :

```bash
KIND_HTTP_PORT=8080 \
KIND_HTTPS_PORT=8443 \
REGISTRY_PORT=5001 \
platform-bootstrap -n my-platform bootstrap
```

Avant de créer le cluster, les ports sont contrôlés :

```bash
platform-bootstrap -n my-platform check-ports
```

## Cycle de bootstrap

La commande :

```bash
platform-bootstrap -n my-platform bootstrap
```

enchaîne :

```text
doctor
  ↓
kind-create
  ↓
registry-create
  ↓
registry-configure-kind
  ↓
crossplane-install
  ↓
crossplane-verify
```

Le réseau Docker `kind` est donc créé avant le démarrage du registry.

## Kind

Le template source est :

```text
core/kind/kind.yaml.tpl
```

Le fichier généré est stocké dans le state de l'instance :

```text
~/.local/state/platform-bootstrap/<instance>/kind/kind.yaml
```

Les volumes locaux sont stockés sous :

```text
~/.local/state/platform-bootstrap/<instance>/kind/storage/
```

Les ports HTTP et HTTPS sont injectés lors de la génération de la configuration.

## Registry OCI local

Le registry est accessible depuis le poste et depuis les nodes Kind avec le même endpoint :

```text
https://registry.<instance>.local:<port>
```

Le registry écoute sur le même port à l'intérieur du container et sur le host afin d'éviter une différence entre :

- l'accès depuis le poste ;
- l'accès direct depuis le réseau Docker `kind`.

Le certificat et la clé sont stockés sous :

```text
~/.local/state/platform-bootstrap/<instance>/registry/certs/
```

Les données OCI sont stockées sous :

```text
~/.local/state/platform-bootstrap/<instance>/registry/data/
```

### Suppression ciblée du registry

```bash
platform-bootstrap -n my-platform registry-delete
```

Cette commande supprime le container registry et ses données OCI, mais conserve volontairement :

- le certificat TLS ;
- la résolution `/etc/hosts`.

Cela permet une recréation sans rotation de l'identité TLS.

## Gestion de `/etc/hosts`

Lors du premier bootstrap d'une instance, le registry local doit être résolu depuis le poste.

Une entrée est ajoutée sous la forme :

```text
127.0.0.1 registry.my-platform.local # platform-bootstrap:my-platform
```

Le marqueur permet de distinguer une entrée gérée par le bootstrap d'une entrée externe.

Règles :

- si une entrée marquée existe déjà et correspond à la configuration attendue, elle est conservée ;
- si le hostname est déjà résolu par une configuration externe cohérente, cette configuration n'est pas modifiée ;
- si une résolution externe pointe vers une autre adresse, le bootstrap échoue au lieu de l'écraser ;
- seule une entrée portant le marqueur de l'instance est supprimée lors du `destroy`.

Une élévation `sudo` peut être demandée lors du premier ajout ou de la suppression de l'entrée.

## Crossplane

La version de Crossplane est centralisée dans :

```text
core/versions.env
```

L'installation Helm utilise :

```text
core/crossplane/values.yaml
```

Le certificat du registry est injecté dans Crossplane afin de permettre le téléchargement de packages OCI depuis le registry local.

Vérification ciblée :

```bash
platform-bootstrap -n my-platform crossplane-verify
```

Le test crée temporairement une `Configuration` pointant vers un package volontairement inexistant dans le registry local.

Le résultat attendu est une erreur de type `manifest unknown` ou équivalent : elle prouve que Crossplane a atteint le registry avec un trust TLS valide.

Une erreur `x509` est considérée comme un échec.

## Vérification complète

```bash
platform-bootstrap -n my-platform verify
```

La vérification contrôle notamment :

- l'état `Ready` des nodes Kubernetes ;
- l'API HTTPS du registry ;
- le trust containerd vers le registry ;
- l'installation Helm de Crossplane ;
- les deployments Crossplane ;
- les CRD Crossplane ;
- le trust Crossplane vers le registry OCI.

Une exécution valide se termine par :

```text
Bootstrap READY.
```

## Destruction

```bash
platform-bootstrap -n my-platform destroy
```

Le `destroy` supprime :

1. le container registry ;
2. l'entrée `/etc/hosts` marquée pour l'instance ;
3. le cluster Kind ;
4. le state Kind ;
5. le state registry, certificat compris.

La suppression est limitée à l'instance ciblée.

## Troubleshooting

### Port déjà utilisé

Exemple :

```text
ERROR: HTTP port 80 is already in use.
```

Utiliser des ports alternatifs :

```bash
KIND_HTTP_PORT=8080 \
KIND_HTTPS_PORT=8443 \
REGISTRY_PORT=5001 \
platform-bootstrap -n my-platform bootstrap
```

### Docker inaccessible

```bash
docker ps
```

Sous WSL2, vérifier l'intégration de la distribution dans Docker Desktop.

### Registry inaccessible

```bash
platform-bootstrap -n my-platform registry-verify
```

Ou vérifier directement :

```bash
curl \
  --cacert ~/.local/state/platform-bootstrap/my-platform/registry/certs/domain.crt \
  https://registry.my-platform.local:5000/v2/
```

### Trust registry dans Kind

```bash
docker exec my-platform-control-plane \
  containerd config dump | grep -A3 -B2 config_path
```

La configuration attendue contient :

```text
config_path = '/etc/containerd/certs.d'
```

### Diagnostic Crossplane

```bash
platform-bootstrap -n my-platform crossplane-status
```

Logs :

```bash
kubectl --context kind-my-platform \
  logs -n crossplane-system deployment/crossplane
```

## Workflow développeur

Le workflow complet de consommation depuis un projet est décrit dans :

[Développement local avec Crossplane](../docs/developpement-local.md)