# Bootstrap de développement de plateforme

Ce repository fournit un bootstrap local réutilisable pour créer rapidement un environnement de développement Kubernetes cohérent entre plusieurs projets.

Il est conçu pour être utilisé comme un outil autonome depuis n'importe quel repository consommateur.

Le bootstrap fournit aujourd'hui :

- un socle `core` basé sur Kind, un registry OCI local sécurisé en TLS et Crossplane ;
- une extension `ai` permettant d'ajouter le support GPU NVIDIA à un cluster Kind local.

Le socle `core` configure notamment :

- Kind ;
- un registry OCI local sécurisé en TLS ;
- le trust du registry dans les runtimes containerd des nodes Kind ;
- Crossplane ;
- le trust du registry OCI dans Crossplane.

L'extension `ai` ajoute :

- une image de node Kind intégrant NVIDIA Container Toolkit ;
- un worker Kind dédié au GPU ;
- le support NVIDIA CDI ;
- la configuration du runtime NVIDIA dans containerd ;
- NVIDIA Device Plugin ;
- l'exposition de la ressource Kubernetes `nvidia.com/gpu`.

## Installation

### Installation depuis une release

Télécharger l'archive correspondant à la version souhaitée depuis les releases GitHub.

Exemple :

```text
platform-bootstrap-v0.4.0-linux.tar.gz
```

Extraire l'archive :

```bash
tar -xzf platform-bootstrap-v0.4.0-linux.tar.gz
cd platform-bootstrap-v0.4.0-linux
```

Installer :

```bash
./install.sh
```

Par défaut, l'installation utilise le préfixe :

```text
~/.local
```

Les principaux fichiers sont installés sous :

```text
~/.local/
├── bin/
│   ├── platform-bootstrap
│   └── platform-bootstrap-uninstall
├── lib/
│   └── platform-bootstrap/
└── share/
    └── bash-completion/
        └── completions/
            └── platform-bootstrap
```

Une fois l'installation terminée, le dossier extrait peut être supprimé.

Vérifier l'installation :

```bash
which platform-bootstrap
platform-bootstrap --help
```

La commande peut ensuite être appelée depuis n'importe quel repository consommateur.

### Autocomplétion Bash

L'installateur déploie automatiquement l'autocomplétion Bash.

Dans un nouveau terminal, il est possible par exemple de compléter :

```text
platform-bootstrap boo<TAB>
```

ou :

```text
platform-bootstrap --reg<TAB>
```

Les instances existantes peuvent également être proposées après :

```text
platform-bootstrap -n <TAB>
```

L'autocomplétion nécessite que `bash-completion` soit installé et chargé dans l'environnement.

### Désinstallation

La désinstallation reste disponible même après suppression de l'archive et du dossier extrait :

```bash
platform-bootstrap-uninstall
```

Cette commande supprime :

- la CLI installée ;
- les fichiers de `platform-bootstrap` sous `~/.local/lib` ;
- l'autocomplétion Bash ;
- la commande de désinstallation elle-même.

Elle ne supprime pas automatiquement les instances Kubernetes existantes.

Pour supprimer une instance avant de désinstaller l'outil :

```bash
platform-bootstrap -n my-platform destroy
platform-bootstrap-uninstall
```

### Installation depuis les sources

Pour développer ou modifier `platform-bootstrap`, le repository peut également être cloné puis installé directement :

```bash
git clone <repository>
cd platform-bootstrap
./packaging/install.sh
```

L'installation utilise le même layout sous `~/.local` que l'installation depuis une release.

## Usage rapide

### Bootstrap standard

Pour créer une instance nommée `my-platform` :

```bash
platform-bootstrap -n my-platform doctor
platform-bootstrap -n my-platform bootstrap
platform-bootstrap -n my-platform verify
```

### Bootstrap mononœud

Pour les configurations matérielles plus limitées, le bootstrap `core` peut créer un cluster Kind avec un unique `control-plane` servant également de worker :

```bash
platform-bootstrap \
  -n my-platform \
  --single-node \
  bootstrap
```

Le taint `NoSchedule` du control-plane est alors retiré afin de permettre l'exécution des workloads sur ce nœud.

Le mode `single-node` concerne uniquement le bootstrap `core`.

### Bootstrap AI

Pour créer une instance avec support GPU NVIDIA :

```bash
platform-bootstrap -n my-platform doctor
platform-bootstrap -n my-platform doctor-ai
platform-bootstrap -n my-platform bootstrap-ai
platform-bootstrap -n my-platform verify-ai
platform-bootstrap -n my-platform test-ai
```

`verify-ai` vérifie que le GPU est correctement exposé par Kubernetes.

`test-ai` va plus loin en lançant un workload demandant réellement une ressource :

```text
nvidia.com/gpu: 1
```

et en exécutant `nvidia-smi` depuis le pod.

Le profil `ai` conserve sa topologie dédiée avec worker GPU et ne supporte pas l'option `--single-node`.

### Suppression

Pour supprimer complètement une instance :

```bash
platform-bootstrap -n my-platform destroy
```

Pour une instance AI, le `destroy` supprime également l'image Kind NVIDIA lorsqu'elle n'est plus utilisée par une autre instance.

Afficher l'aide :

```bash
platform-bootstrap --help
```

## Nom d'instance

L'option `-n` ou `--name` définit le nom logique de l'instance :

```bash
platform-bootstrap -n my-platform bootstrap
```

À partir de ce nom, le bootstrap dérive par défaut :

```text
cluster Kind      : my-platform
registry Docker   : my-platform-registry
registry DNS      : registry.my-platform.local
state runtime     : ~/.local/state/platform-bootstrap/my-platform/
```

Les paramètres peuvent être surchargés individuellement si nécessaire.

## Profils d'instance

Chaque instance possède un profil persisté dans son état :

```text
PLATFORM_BOOTSTRAP_PROFILE=core
```

ou :

```text
PLATFORM_BOOTSTRAP_PROFILE=ai
```

Le profil `core` correspond au bootstrap standard.

Le profil `ai` correspond à un bootstrap intégrant le support GPU NVIDIA.

Le profil est notamment utilisé lors du cycle de vie de l'instance afin d'appliquer les opérations de nettoyage spécifiques à l'extension AI.

## Topologie Kind

Le bootstrap `core` supporte deux topologies Kind :

```text
standard
single-node
```

### Topologie standard

La topologie par défaut est :

```text
KIND_TOPOLOGY=standard
```

Elle crée un cluster composé de :

```text
1 control-plane
2 workers
```

Le control-plane conserve son taint Kubernetes `NoSchedule` et les workloads sont exécutés sur les workers.

Une création standard ne nécessite aucun flag particulier :

```bash
platform-bootstrap \
  -n my-platform \
  bootstrap
```

### Topologie single-node

Pour les configurations matérielles plus limitées :

```bash
platform-bootstrap \
  -n my-platform \
  --single-node \
  bootstrap
```

La topologie contient alors uniquement :

```text
1 control-plane
```

Le taint `node-role.kubernetes.io/control-plane:NoSchedule` est retiré lors de la création afin que le control-plane puisse également exécuter les workloads.

La configuration persistée contient :

```text
KIND_TOPOLOGY=single-node
```

Le mode `single-node` est uniquement disponible avec la commande `bootstrap`.

Il n'est pas supporté par `bootstrap-ai`, qui conserve sa topologie dédiée avec worker GPU.

### Consultation de la topologie

La topologie d'une instance peut être consultée avec :

```bash
platform-bootstrap list --detail
```

Exemple :

```text
Instance       : my-platform
Profile        : core
Topology       : single-node
Kind cluster   : my-platform
Kind context   : kind-my-platform
Kind status    : present
...
```

Pour assurer la compatibilité avec les instances créées avant l'introduction de `KIND_TOPOLOGY`, une instance ne possédant pas cette propriété dans son état est considérée comme utilisant la topologie `standard`.

## Ports et configuration

Les ports peuvent être fournis directement à la CLI lors du bootstrap :

```bash
platform-bootstrap \
  -n my-platform \
  --http-port 8080 \
  --https-port 8443 \
  --registry-port 5001 \
  bootstrap
```

Les options de ports peuvent être combinées avec `--single-node` :

```bash
platform-bootstrap \
  -n my-platform \
  --single-node \
  --http-port 8080 \
  --https-port 8443 \
  --registry-port 5001 \
  bootstrap
```

Les mêmes options de ports sont disponibles avec le bootstrap AI :

```bash
platform-bootstrap \
  -n my-platform \
  --http-port 8080 \
  --https-port 8443 \
  --registry-port 5001 \
  bootstrap-ai
```

Les options de ports s'appliquent uniquement aux commandes :

```text
bootstrap
bootstrap-ai
```

Les ports peuvent également être fournis via les variables d'environnement :

```text
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

Le bootstrap vérifie les ports avant la création du cluster et échoue explicitement lorsqu'un port est déjà utilisé.

Exemple :

```bash
platform-bootstrap -n my-platform check-ports
```

Les valeurs effectives utilisées lors de la création d'une instance sont persistées dans `instance.env`.

La précédence de configuration est :

```text
arguments CLI
        >
variables d'environnement
        >
configuration persistée dans instance.env
        >
valeurs par défaut
```

Par exemple, si l'instance utilise le port registry `5001` :

```bash
platform-bootstrap -n my-platform registry-verify
```

réutilise automatiquement cette valeur depuis `instance.env`.

Un override par variable d'environnement reste possible pour les commandes ciblées :

```bash
REGISTRY_PORT=5010 \
platform-bootstrap -n my-platform registry-verify
```

## État runtime

Aucun état généré n'est écrit dans le repository du bootstrap ni dans le repository consommateur.

L'état est isolé par instance sous :

```text
~/.local/state/platform-bootstrap/my-platform/
```

Exemple :

```text
~/.local/state/platform-bootstrap/my-platform/
├── instance.env
├── kind/
│   ├── kind.yaml
│   └── storage/
└── registry/
    ├── certs/
    └── data/
```

Pour une instance AI, une configuration Kind spécifique peut également être générée sous l'état de l'instance.

Le fichier `instance.env` conserve les paramètres nécessaires à la réutilisation de l'instance, par exemple :

```text
PLATFORM_BOOTSTRAP_NAME=my-platform
PLATFORM_BOOTSTRAP_PROFILE=core
KIND_CLUSTER=my-platform
KIND_TOPOLOGY=single-node
KIND_HTTP_PORT=8080
KIND_HTTPS_PORT=8443
REGISTRY_NAME=my-platform-registry
REGISTRY_HOST=registry.my-platform.local
REGISTRY_PORT=5001
```

Une instance standard contient :

```text
KIND_TOPOLOGY=standard
```

## Résolution DNS locale

Le registry local de l'instance `my-platform` utilise le hostname :

```text
registry.my-platform.local
```

Le bootstrap ajoute une entrée marquée dans `/etc/hosts` :

```text
127.0.0.1 registry.my-platform.local # platform-bootstrap:my-platform
```

Cette entrée est supprimée uniquement lors du `destroy` complet de l'instance.

Une suppression ciblée du registry conserve volontairement :

- le certificat TLS ;
- l'entrée `/etc/hosts` ;
- l'identité du registry.

Cela permet de recréer le container registry sans provoquer une rotation de certificat ni casser le trust Crossplane.

## Commandes principales

- `platform-bootstrap list` — liste les instances connues.
- `platform-bootstrap list --detail` — affiche la configuration et l'état détaillé des instances.
- `platform-bootstrap -n <instance> doctor` — vérifie les prérequis nécessaires au bootstrap standard.
- `platform-bootstrap -n <instance> check-ports` — vérifie que les ports requis par l'instance sont disponibles.
- `platform-bootstrap -n <instance> bootstrap` — crée et configure un environnement local standard.
- `platform-bootstrap -n <instance> --single-node bootstrap` — crée un environnement local mononœud.
- `platform-bootstrap -n <instance> verify` — vérifie l'état du cluster, du registry et de Crossplane.
- `platform-bootstrap -n <instance> bootstrap-ai` — crée un environnement local avec support GPU NVIDIA.
- `platform-bootstrap -n <instance> verify-ai` — vérifie l'exposition du GPU dans Kubernetes.
- `platform-bootstrap -n <instance> test-ai` — exécute un workload Kubernetes consommant réellement un GPU.
- `platform-bootstrap -n <instance> destroy` — supprime complètement l'instance et nettoie les ressources associées.

## Commandes ciblées

### Kind

- `platform-bootstrap -n <instance> kind-config` — génère la configuration Kind de l'instance.
- `platform-bootstrap -n <instance> kind-create` — crée le cluster Kind.
- `platform-bootstrap -n <instance> kind-status` — affiche l'état des nodes du cluster Kind.
- `platform-bootstrap -n <instance> kind-delete` — supprime uniquement le cluster Kind.

### Registry

- `platform-bootstrap -n <instance> registry-create` — crée et démarre le registry OCI local.
- `platform-bootstrap -n <instance> registry-delete` — supprime le container et les données du registry tout en conservant son identité TLS.
- `platform-bootstrap -n <instance> registry-configure-kind` — configure les nodes Kind pour faire confiance au registry local.
- `platform-bootstrap -n <instance> registry-verify` — vérifie l'accès au registry et le trust containerd depuis les nodes Kind.

### Crossplane

- `platform-bootstrap -n <instance> crossplane-install` — installe ou met à jour Crossplane dans le cluster.
- `platform-bootstrap -n <instance> crossplane-verify` — vérifie l'état de Crossplane et son accès au registry OCI local.
- `platform-bootstrap -n <instance> crossplane-status` — affiche l'état des composants Crossplane.
- `platform-bootstrap -n <instance> crossplane-uninstall` — désinstalle Crossplane du cluster.

### AI

- `platform-bootstrap doctor-ai` — vérifie l'accès au GPU NVIDIA depuis l'hôte et Docker.
- `platform-bootstrap build-ai-node-image` — construit l'image Kind intégrant NVIDIA Container Toolkit.
- `platform-bootstrap -n <instance> kind-ai-config` — génère la configuration Kind avec worker GPU.
- `platform-bootstrap -n <instance> kind-ai-create` — crée le cluster Kind avec worker GPU.
- `platform-bootstrap -n <instance> configure-ai-containerd` — configure containerd avec le runtime NVIDIA et CDI.
- `platform-bootstrap -n <instance> install-ai-device-plugin` — installe NVIDIA Device Plugin.
- `platform-bootstrap -n <instance> verify-ai` — vérifie que Kubernetes expose la ressource `nvidia.com/gpu`.
- `platform-bootstrap -n <instance> test-ai` — lance un pod demandant un GPU et exécute `nvidia-smi`.

Les commandes AI ciblées sont principalement destinées au diagnostic, au développement du bootstrap ou à l'exécution manuelle d'une étape précise.

## Packaging

Une archive distribuable peut être générée depuis le repository avec :

```bash
make package VERSION=v0.4.0
```

Le package est produit sous :

```text
dist/platform-bootstrap-v0.4.0-linux.tar.gz
```

Le répertoire `dist/` contient uniquement des artefacts générés et n'est pas versionné dans Git.

L'archive contient notamment :

```text
platform-bootstrap-v0.4.0-linux/
├── install.sh
├── uninstall.sh
├── Makefile
├── README.md
├── bin/
├── core/
├── ai/
├── completion/
└── docs/
```

Le package est conçu pour être autonome : après `./install.sh`, le dossier extrait peut être supprimé.

## Structure du repository

```text
.
├── Makefile
├── README.md
├── bin/
│   └── platform-bootstrap
├── completion/
│   └── platform-bootstrap.bash
├── packaging/
│   ├── install.sh
│   └── uninstall.sh
├── core/
│   ├── Makefile
│   ├── README.md
│   ├── versions.env
│   ├── kind/
│   ├── registry/
│   ├── crossplane/
│   └── scripts/
├── ai/
│   ├── Makefile
│   ├── README.md
│   ├── versions.env
│   ├── kind/
│   └── scripts/
├── docs/
│   └── developpement-local.md
└── tests/
```

## Documentation

- [Documentation du socle core](core/README.md)
- [Documentation Kind](core/kind/README.md)
- [Documentation du socle ai](ai/README.md)
- [Workflow de développement local](docs/developpement-local.md)