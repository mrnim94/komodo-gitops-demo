# Komodo GitOps demo

This repository demonstrates two different Komodo resource types. They are
independent; use either one or both depending on the job.

## Which resource should I use?

| Goal | Resource | File |
| --- | --- | --- |
| Run a Docker Compose application | `[[stack]]` | `resources/stacks.toml` |
| Clone a Git repository and run commands | `[[repo]]` | `resources/app-repo.toml` |

### `[[stack]]`: Docker Compose lifecycle

Use a Stack when you want Komodo to deploy and manage services defined in a
Compose file. The Stack clones this Git repository, loads
`nginx-demo/compose.yaml`, and manages deploys, status, logs, and updates.

Do not add `docker compose up` to `scripts/deploy.sh` for this application. That
would create two deployment owners: the Stack and the script.

### `[[repo]]`: arbitrary automation

Use a Repo when the main job is running scripts rather than managing a Compose
application. Komodo clones or pulls the repository and runs the configured
`on_clone` or `on_pull` hook. In this demo both hooks call:

```sh
bash scripts/deploy.sh
```

Replace the example commands inside that script with tasks such as builds,
migrations, file generation, or service reloads.

## Applying the resources

Configure a Komodo Resource Sync to read the files under `resources/`, refresh
the sync, review its proposed changes, and apply them.

The referenced server resource must be named `komodo-periphery`. Because the
GitHub repository is public, no `git_account` is required. Add one in Komodo and
in these resource configs only if the repository becomes private.

