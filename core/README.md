# Bootstrap local de la plateforme

Ce répertoire contient le bootstrap générique utilisé pour créer un environnement local Kubernetes reproductible pour le développement de la plateforme.

Le bootstrap fournit le socle technique commun nécessaire au développement local et, à terme, aux exécutions CI.

## 1. Composants installés

Le bootstrap crée et configure :

- un cluster Kubernetes local avec Kind ;
- un registry OCI local sécurisé en TLS ;
- le trust du registry dans les runtimes containerd des nodes Kind ;
- Crossplane ;
- le trust du registry OCI dans Crossplane.

Les commandes principales sont :

```bash
make -C bootstrap doctor
make -C bootstrap bootstrap
make -C bootstrap verify
make -C bootstrap destroy
```

## 2. Prérequis

Le bootstrap suppose que les outils système nécessaires sont déjà installés sur le poste développeur.

Il ne prend pas en charge l'installation de WSL2, Docker, Git ou des outils de développement.

### Environnement validé

L'environnement actuellement validé est :

- Windows 11 ;
- WSL2 ;
- distribution Linux ;
- Docker accessible depuis WSL.

Le bootstrap est conçu pour pouvoir également fonctionner sur un poste Linux natif disposant des mêmes outils.

### Outils requis

Les outils suivants doivent être disponibles dans le `PATH` :

| Outil | Usage |
|---|---|
| Git | gestion du repository |
| Docker | exécution de Kind et du registry OCI |
| kubectl | interaction avec Kubernetes |
| Kind | création du cluster local |
| Helm | installation de composants Kubernetes |
| Crossplane CLI | développement et packaging des projets Crossplane |
| OpenSSL | génération des certificats TLS locaux |
| curl | vérifications HTTP/HTTPS |
| sed | génération de configuration |
| awk | scripts du bootstrap |

La commande suivante vérifie automatiquement les prérequis :

```bash
make -C bootstrap doctor
```

### Exemples d'installation sur Ubuntu / WSL Ubuntu

Les commandes suivantes sont fournies à titre d'exemple. Les versions utilisées par le projet restent définies par le repository.

#### Git, curl et OpenSSL

```bash
sudo apt update

sudo apt install -y   git   curl   openssl   ca-certificates
```

#### kubectl

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s   https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
```

Vérification :

```bash
kubectl version --client
```

#### Kind

```bash
curl -Lo ./kind   https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64

chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind
```

Vérification :

```bash
kind version
```

#### Helm

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Vérification :

```bash
helm version
```

#### Crossplane CLI

Installer la CLI Crossplane conformément à la documentation officielle.

Vérification :

```bash
crossplane --version
```

#### Docker

Docker doit être installé et son daemon accessible depuis l'environnement Linux utilisé pour lancer le bootstrap.

Vérification :

```bash
docker version
docker ps
```

Sous WSL2, Docker Desktop peut être utilisé avec l'intégration WSL activée.

## 3. Installation rapide

Depuis la racine du repository :

```bash
make -C bootstrap doctor
make -C bootstrap bootstrap
make -C bootstrap verify
```

Le bootstrap :

1. vérifie les prérequis ;
2. génère le certificat TLS du registry local ;
3. démarre le registry OCI ;
4. génère la configuration Kind ;
5. crée le cluster Kubernetes ;
6. configure le trust du registry sur chaque node ;
7. installe Crossplane ;
8. configure Crossplane pour accéder au registry local ;
9. vérifie l'installation.

Une installation valide se termine par :

```text
Bootstrap READY.
```

## 4. Organisation du bootstrap

```text
bootstrap/
├── Makefile
├── README.md
├── versions.env
├── kind/
│   ├── kind.yaml.tpl
│   └── kind.yaml
├── crossplane/
│   ├── values.yaml
│   └── scripts/
├── scripts/
└── docs/
    └── developpement-local.md
```

`kind.yaml` est généré localement à partir de :

```text
bootstrap/kind/kind.yaml.tpl
```

Il n'est pas versionné.

Les versions principales du socle sont centralisées dans :

```text
bootstrap/versions.env
```

## 5. Commandes principales

### Vérifier les prérequis

```bash
make -C bootstrap doctor
```

Cette commande ne modifie pas l'environnement.

### Créer l'environnement

```bash
make -C bootstrap bootstrap
```

Cette commande crée l'ensemble du socle local.

### Vérifier l'environnement

```bash
make -C bootstrap verify
```

La vérification contrôle notamment :

- l'état des nodes Kubernetes ;
- l'accès HTTPS au registry ;
- le trust containerd vers le registry ;
- l'installation Helm de Crossplane ;
- les deployments Crossplane ;
- les CRD Crossplane ;
- le trust Crossplane vers le registry OCI.

### Supprimer l'environnement

```bash
make -C bootstrap destroy
```

Cette commande supprime :

- le cluster Kind ;
- le registry local ;
- les données runtime générées par le bootstrap ;
- les certificats locaux générés.

Elle ne supprime pas les sources du repository.

## 6. Registry OCI local

Le registry est exposé par défaut sous :

```text
registry.agentic.local:5000
```

Pour vérifier son API :

```bash
curl   --cacert ${XDG_STATE_HOME:-$HOME/.local/state}/platform-bootstrap/registry/certs/domain.crt   https://registry.agentic.local:5000/v2/
```

Pour afficher les repositories :

```bash
curl   --cacert ${XDG_STATE_HOME:-$HOME/.local/state}/platform-bootstrap/registry/certs/domain.crt   https://registry.agentic.local:5000/v2/_catalog
```

Le registry est utilisé notamment pour construire, publier et tester localement les packages Crossplane.

Le cluster Kind et Crossplane utilisent explicitement la CA générée par le bootstrap.

## 7. Données locales

Deux emplacements sont utilisés.

### Données liées au repository

```text
.local/
```

Ce répertoire contient notamment les données et certificats du registry local.

Il n'est pas versionné.

### Données Kubernetes persistantes

```text
~/.local/state/platform-bootstrap/
```

Ce répertoire contient les volumes locaux utilisés par Kind.

Il est nettoyé par :

```bash
make -C bootstrap destroy
```

## 8. Troubleshooting

Cette section sera enrichie au fur et à mesure des problèmes rencontrés.

### `Permission denied` sur un script

Le bootstrap invoque explicitement ses scripts avec Bash afin de rester robuste aux différences de permissions entre Windows, WSL et Linux.

Exemple :

```bash
bash bootstrap/scripts/doctor.sh
```

### Docker inaccessible

Erreur typique :

```text
Cannot connect to the Docker daemon
```

Vérifier :

```bash
docker ps
```

Sous WSL2 avec Docker Desktop, vérifier que l'intégration WSL est activée pour la distribution utilisée.

### Le cluster existe déjà

Lister les clusters :

```bash
kind get clusters
```

Pour repartir de zéro :

```bash
make -C bootstrap destroy
make -C bootstrap bootstrap
```

### Registry inaccessible

Vérifier le container :

```bash
docker ps --filter name=agentic-registry
```

Puis :

```bash
curl   --cacert ${XDG_STATE_HOME:-$HOME/.local/state}/platform-bootstrap/registry/certs/domain.crt   https://registry.agentic.local:5000/v2/
```

La réponse attendue est :

```json
{}
```

### Le node Kind ne fait pas confiance au registry

Vérifier la configuration containerd :

```bash
docker exec agentic-platform-control-plane   containerd config dump | grep -A3 -B2 config_path
```

La configuration doit contenir :

```text
config_path = '/etc/containerd/certs.d'
```

Puis vérifier la configuration du registry :

```bash
docker exec agentic-platform-control-plane   cat /etc/containerd/certs.d/registry.agentic.local:5000/hosts.toml
```

### Crossplane ne démarre pas

Vérifier les pods :

```bash
kubectl get pods -n crossplane-system
```

Puis la release Helm :

```bash
helm list -n crossplane-system
```

Et les logs si nécessaire :

```bash
kubectl logs   -n crossplane-system   deployment/crossplane
```

## 9. Cycle de validation recommandé

Pour vérifier que l'environnement reste reproductible :

```bash
make -C bootstrap destroy
make -C bootstrap doctor
make -C bootstrap bootstrap
make -C bootstrap verify
```

Le bootstrap est considéré fonctionnel lorsque cette séquence peut être rejouée depuis un environnement vide sans intervention manuelle.

Pour le workflow de développement Crossplane au-dessus de ce socle, voir :

[Développement local avec Crossplane](docs/developpement-local.md)
