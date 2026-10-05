# Kind

Le cluster Kind du bootstrap est volontairement générique : un control-plane et deux workers standards.

La configuration source est :

```text
bootstrap/kind/kind.yaml.tpl
```

Le fichier suivant est généré localement et ignoré par Git :

```text
bootstrap/kind/kind.yaml
```

Création :

```bash
make -C bootstrap kind-create
```

État :

```bash
make -C bootstrap kind-status
```

Suppression complète de l'environnement :

```bash
make -C bootstrap destroy
```

Le support GPU/NVIDIA est une extension IA distincte sous `ai/infrastructure/`.
