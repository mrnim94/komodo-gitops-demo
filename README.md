# Komodo GitOps demo

A small, safe reference repository for declaring Docker resources in
[Komodo](https://komo.do/). It separates the three common operations so a
resource has exactly one owner.

## Architecture

```text
GitHub repository (master)
        │
        ├─ GitOps · Docker deployments ────── resources/deployments.toml
        ├─ GitOps · Server automation ─────── resources/app-repo.toml
        └─ GitOps · Docker Compose stacks ─── resources/stacks.toml
                                              │
                                              ▼
                              Komodo Core → komodo-periphery
```

The three Resource Syncs are intentionally independent. Each one reads one
TOML file, so the review / apply screen shows only changes for that management
mode.

| Goal | Komodo resource | GitOps TOML | Result |
| --- | --- | --- | --- |
| Manage a single Docker container | `Deployment` | `resources/deployments.toml` | Komodo owns `docker run`, lifecycle, logs and image updates. |
| Run arbitrary server automation | `Repo` | `resources/app-repo.toml` | Komodo clones/pulls the repo and runs hooks such as shell scripts, package updates or migrations. |
| Manage a Compose application | `Stack` | `resources/stacks.toml` | Komodo owns `docker compose` lifecycle, service status, logs and updates. |

## Resource definitions

### 1. Direct Docker management

`resources/deployments.toml` declares `demo-nginx-container`, a direct Komodo
Deployment using `nginx:1.27-alpine` on host port `8081`.

It starts with `deploy = false`: applying the Resource Sync only creates or
updates the Deployment definition. Use **Deploy** in Komodo when ready. This
avoids accidental conflict with a manually managed container.

### 2. Arbitrary commands or scripts

`resources/app-repo.toml` declares `komodo-gitops-demo-script` as a Repo.
Komodo executes `bash scripts/deploy.sh` after its initial clone and after a
pull. Put non-Compose work here, for example:

```bash
apt-get update
./scripts/migrate-database.sh
systemctl reload nginx
```

The example script is harmless: it only logs its start and finish.

### 3. Docker Compose management

`resources/stacks.toml` declares `demo-nginx`, sourcing
`nginx-demo/compose.yaml`. The stack starts with `deploy = false`, so applying that
Resource Sync creates or updates the Stack definition without immediately
starting Compose. Use **Deploy** in Komodo when ready. Do not also run
`docker compose up` from `scripts/deploy.sh`; a Stack must be its only
deployment owner.

> The current Compose sample uses container name `komodo-demo-nginx` and host
> port `8080`. Stop or rename any manually created container with the same name
> before applying this Stack sync.

## Komodo Core setup

Create these Resource Syncs in Komodo, all sourced from this public GitHub
repository:

```text
repo:         mrnim94/komodo-gitops-demo
branch:       master
git provider: github.com
server:       komodo-periphery
```

| Resource Sync name | Resource path |
| --- | --- |
| `GitOps · Docker deployments` | `resources/deployments.toml` |
| `GitOps · Server automation` | `resources/app-repo.toml` |
| `GitOps · Docker Compose stacks` | `resources/stacks.toml` |

For every sync: **Refresh** → review the Pending diff → **Run Sync**. This
repository is public, so no `git_account` is needed. Configure a GitHub account
in Komodo only after making the repository private.

## Validation locally

```bash
# Check TOML syntax (Python 3.11+)
python3 - <<'PY'
import pathlib, tomllib
for path in pathlib.Path('resources').glob('*.toml'):
    tomllib.loads(path.read_text())
    print(f'OK {path}')
PY

# Validate the Compose application

docker compose -f nginx-demo/compose.yaml config
```
