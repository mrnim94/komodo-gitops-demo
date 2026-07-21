# Komodo GitOps Demo

Full GitOps automation for managing Docker Compose stacks across multiple
physical servers using [Komodo](https://komo.do/).

## Architecture

```text
GitHub push
     ↓
GitHub Actions (1 workflow, path-based detection)
     ↓
Komodo webhook → ResourceSync diff → create/update/deploy
     ↓
komodo-periphery agents on physical servers
```

## Repository structure

```
├── servers/                          # Server infrastructure
│   ├── servers.toml                  # All server definitions
│   ├── deployments.toml              # Direct Docker containers
│   └── repos.toml                    # Repo clone + script hooks
│
├── stacks/                           # Per-server Docker Compose stacks
│   └── <server-name>/
│       ├── stacks.toml               # Stack definitions for this server
│       └── <app-name>/
│           └── compose.yaml          # Compose file
│
├── automation/                       # Komodo orchestration
│   ├── actions.toml                  # TypeScript API scripts
│   └── procedures.toml               # Multi-stage pipelines
│
├── bootstrap/                        # Self-managing ResourceSyncs
│   └── resource-syncs.toml           # Declares ALL other syncs
│
├── scripts/                          # Server automation scripts
│   └── deploy.sh
│
└── .github/workflows/
    └── komodo-sync.yml               # Single workflow for everything
```

## Bootstrap (one-time setup)

1. Create **one** ResourceSync manually on Komodo:
   - Name: `bootstrap`
   - Repo: `mrnim94/komodo-gitops-demo`
   - Branch: `master`
   - Resource path: `bootstrap/resource-syncs.toml`

2. Run Sync → Komodo creates all other ResourceSyncs automatically.

3. Each child ResourceSync syncs its own TOML files → servers, stacks,
   actions, procedures are all created.

4. Set **2 GitHub Secrets**:
   - `KOMODO_HOST` — e.g. `https://komodo.nimtechnology.com`
   - `KOMODO_WEBHOOK_SECRET` — from Komodo Core config

From this point, everything is automated.

## Day-to-day operations

### Add a new server

1. Add `[[server]]` to `servers/servers.toml`
2. Create `stacks/<server-name>/stacks.toml` + compose files
3. Add `[[resource_sync]]` to `bootstrap/resource-syncs.toml`
4. `git push` → done

### Add a stack to an existing server

1. Add `[[stack]]` to `stacks/<server-name>/stacks.toml`
2. Add compose file to `stacks/<server-name>/<app>/compose.yaml`
3. `git push` → sync runs → stack created/deployed

### Update a compose file

1. Edit `stacks/<server-name>/<app>/compose.yaml`
2. `git push` → Komodo detects change → redeploy

## GitHub Actions

One workflow (`komodo-sync.yml`) handles everything:

| Changed path | Komodo action |
|---|---|
| `bootstrap/**` | Sync bootstrap → creates/updates all ResourceSyncs |
| `servers/**` | Sync servers, deployments, repos |
| `stacks/<srv>/**` | Sync that server's stacks |
| `automation/**` | Sync actions + procedures |
| `scripts/**` | Trigger Repo pull → run deploy.sh |

Only **2 secrets** needed: `KOMODO_HOST` and `KOMODO_WEBHOOK_SECRET`.

## Scaling to 10+ servers

```toml
# bootstrap/resource-syncs.toml — just add blocks:

[[resource_sync]]
name = "sync-srv05-stacks"
[resource_sync.config]
repo = "mrnim94/komodo-gitops-demo"
branch = "master"
git_provider = "github.com"
resource_path = ["stacks/srv05/stacks.toml"]
webhook_enabled = true
```

The workflow auto-detects server folders — no workflow changes needed.

## Local validation

```bash
# TOML syntax check
python3 -c "
import pathlib, tomllib
for p in sorted(pathlib.Path('.').rglob('*.toml')):
    tomllib.loads(p.read_text())
    print(f'OK {p}')
"

# Compose validation
for f in stacks/*/*/compose.yaml; do
  echo "--- $f ---"
  docker compose -f "$f" config --quiet && echo "OK"
done
```
