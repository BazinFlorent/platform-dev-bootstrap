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

## Installation de la CLI

Le repository expose la commande :

```bash
platform-bootstrap
```

Depuis le repository cloné :

```bash
mkdir -p ~/.local/bin

ln -sf \
  "$(pwd)/bin/platform-bootstrap" \
  ~/.local/bin/platform-bootstrap
```

Vérifier que `~/.local/bin` est présent dans le `PATH` :

```bash
which platform-bootstrap
```

La commande peut ensuite être appelée depuis n'importe quel dossier.

## Usage rapide

### Bootstrap standard

Pour créer une instance nommée `my-platform` :

```bash
platform-bootstrap -n my-platform doctor
platform-bootstrap -n my-platform bootstrap
platform-bootstrap -n my-platform verify
```

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

Les variables peuvent être surchargées individuellement si nécessaire.

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

## Ports et configuration

Les ports sont configurables par variables d'environnement :

```bash
platform-bootstrap \
  -n my-platform \
  --http-port 8080 \
  --https-port 8443 \
  --registry-port 5001 \
  bootstrap
```

Les ports peuvent également être fournis via les variables d'environnement
KIND_HTTP_PORT, KIND_HTTPS_PORT et REGISTRY_PORT.

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
variable explicitement fournie à la commande
        >
configuration persistée dans instance.env
        >
valeur par défaut
```

Par exemple, si l'instance utilise le port registry `5001` :

```bash
platform-bootstrap -n my-platform registry-verify
```

réutilise automatiquement cette valeur.

Un override reste néanmoins possible :

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
PLATFORM_BOOTSTRAP_PROFILE=ai
KIND_CLUSTER=my-platform
KIND_HTTP_PORT=8080
KIND_HTTPS_PORT=8443
REGISTRY_NAME=my-platform-registry
REGISTRY_HOST=registry.my-platform.local
REGISTRY_PORT=5001
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

- `platform-bootstrap -n <instance> doctor` — vérifie les prérequis nécessaires au bootstrap standard.
- `platform-bootstrap -n <instance> check-ports` — vérifie que les ports requis par l'instance sont disponibles.
- `platform-bootstrap -n <instance> bootstrap` — crée et configure un environnement local standard.
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

## Structure du repository

```text
.
├── Makefile
├── README.md
├── bin/
│   └── platform-bootstrap
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
|   ├── README.md
│   ├── versions.env
│   ├── kind/
│   └── scripts/
├── docs/
│   └── developpement-local.md
└── tests/
```

## Documentation

- [Documentation du socle core](core/README.md)
- [Documentation du socle ai](ai/README.md)
- [Workflow de développement local](docs/developpement-local.md)