# Kind

Le bootstrap `core` supporte deux topologies Kind :

- `standard` : un control-plane et deux workers ;
- `single-node` : un unique control-plane servant également de worker.

La topologie par défaut est :

```text
KIND_TOPOLOGY=standard
```

## Topologie standard

La topologie standard crée :

```text
1 control-plane
2 workers
```

Le control-plane conserve son taint `NoSchedule` et les workloads sont exécutés sur les workers.

## Topologie single-node

Pour les configurations matérielles plus limitées, il est possible de créer un cluster Kind mononœud :

```bash
platform-bootstrap \
  -n my-platform \
  --single-node \
  bootstrap
```

La topologie générée contient uniquement :

```text
1 control-plane
```

Le taint `node-role.kubernetes.io/control-plane:NoSchedule` est retiré lors de la création afin que le control-plane puisse également exécuter les workloads.

La topologie sélectionnée est persistée dans l'état de l'instance :

```text
KIND_TOPOLOGY=single-node
```

Le mode `single-node` est uniquement supporté par le bootstrap `core`.

## Configuration

La configuration source est :

```text
core/kind/kind.yaml.tpl
```

Le fichier Kind effectif est généré dans l'état de l'instance sous :

```text
~/.local/state/platform-bootstrap/<instance>/kind/kind.yaml
```

Le template reste unique. Le bloc workers est ajouté uniquement lorsque :

```text
KIND_TOPOLOGY=standard
```

## Commandes

Création :

```bash
platform-bootstrap -n my-platform bootstrap
```

Création en mode mononœud :

```bash
platform-bootstrap -n my-platform --single-node bootstrap
```

État :

```bash
platform-bootstrap -n my-platform kind-status
```

Suppression complète de l'environnement :

```bash
platform-bootstrap -n my-platform destroy
```

Le support GPU/NVIDIA est une extension distincte sous `ai/` et conserve sa propre topologie avec worker GPU dédié.