# Bootstrap de développement de plateforme

Ce repository fournit un bootstrap local réutilisable pour créer rapidement un environnement de développement Kubernetes cohérent entre plusieurs projets.

Il est conçu pour être utilisé comme un outil autonome depuis n'importe quel repository consommateur.

Le bootstrap fournit aujourd'hui un socle `core` basé sur :

- Kind ;
- un registry OCI local sécurisé en TLS ;
- le trust du registry dans les runtimes containerd des nodes Kind ;
- Crossplane ;
- le trust du registry OCI dans Crossplane.

> **À venir :** une extension `ai/` complétera ce socle avec les composants nécessaires à l'exécution locale des workloads IA.

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

Pour créer une instance nommée `my-platform` :

```bash
platform-bootstrap -n my-platform doctor
platform-bootstrap -n my-platform bootstrap
platform-bootstrap -n my-platform verify
```

Pour supprimer complètement l'instance :

```bash
platform-bootstrap -n my-platform destroy
```

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

## Ports

Les ports sont configurables par variables d'environnement :

```bash
KIND_HTTP_PORT=8080 \
KIND_HTTPS_PORT=8443 \
REGISTRY_PORT=5001 \
platform-bootstrap -n my-platform bootstrap
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

## État runtime

Aucun état généré n'est écrit dans le repository du bootstrap ni dans le repository consommateur.

L'état est isolé par instance sous :

```text
~/.local/state/platform-bootstrap/my-platform/
```

Exemple :

```text
~/.local/state/platform-bootstrap/my-platform/
├── kind/
│   ├── kind.yaml
│   └── storage/
└── registry/
    ├── certs/
    └── data/
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

### Commandes principales

- `platform-bootstrap -n <instance> doctor` — vérifie que les prérequis nécessaires sont disponibles sur le poste.
- `platform-bootstrap -n <instance> check-ports` — vérifie que les ports requis par l'instance sont disponibles.
- `platform-bootstrap -n <instance> bootstrap` — crée et configure l'environnement local complet.
- `platform-bootstrap -n <instance> verify` — vérifie l'état du cluster, du registry et de Crossplane.
- `platform-bootstrap -n <instance> destroy` — supprime complètement l'instance et nettoie les ressources associées.

### Commandes ciblées

- `platform-bootstrap -n <instance> kind-config` — génère la configuration Kind de l'instance.
- `platform-bootstrap -n <instance> kind-create` — crée le cluster Kind.
- `platform-bootstrap -n <instance> kind-status` — affiche l'état des nodes du cluster Kind.
- `platform-bootstrap -n <instance> kind-delete` — supprime uniquement le cluster Kind.

- `platform-bootstrap -n <instance> registry-create` — crée et démarre le registry OCI local.
- `platform-bootstrap -n <instance> registry-delete` — supprime le container et les données du registry tout en conservant son identité TLS.
- `platform-bootstrap -n <instance> registry-configure-kind` — configure les nodes Kind pour faire confiance au registry local.
- `platform-bootstrap -n <instance> registry-verify` — vérifie l'accès au registry et le trust containerd depuis les nodes Kind.

- `platform-bootstrap -n <instance> crossplane-install` — installe ou met à jour Crossplane dans le cluster.
- `platform-bootstrap -n <instance> crossplane-verify` — vérifie l'état de Crossplane et son accès au registry OCI local.
- `platform-bootstrap -n <instance> crossplane-status` — affiche l'état des composants Crossplane.
- `platform-bootstrap -n <instance> crossplane-uninstall` — désinstalle Crossplane du cluster.

## Structure du repository

```text
.
├── Makefile
├── bin/
│   └── platform-bootstrap
├── core/
│   ├── Makefile
│   ├── README.md
│   ├── versions.env
│   ├── kind/
│   ├── registry/
│   ├── crossplane/
│   ├── scripts/
│
├── ai/
├── docs/
    └── developpement-local.md
└── tests/
```

## Documentation

- [Documentation du socle core](core/README.md)
- [Workflow de développement local](docs/developpement-local.md)
