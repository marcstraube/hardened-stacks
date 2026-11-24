# Hardened Stacks

[![CI](https://github.com/marcstraube/hardened-stacks/workflows/CI/badge.svg)](https://github.com/marcstraube/hardened-stacks/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support-ff5e5b?logo=ko-fi&logoColor=white)](https://ko-fi.com/marcstraube)

A curated collection of security-hardened, pre-configured container stacks for
self-hosting. All stacks are designed to run behind a reverse proxy and follow
consistent security practices out of the box.

## Requirements

- Docker/Podman with Compose support
- A reverse proxy (e.g. Nginx, Traefik, Synology built-in) — all services bind
  to `127.0.0.1` and are **not directly accessible** without one

## Stacks

| Stack                               | Description                  | Default Port            | Docs                                                                                                   |
| ----------------------------------- | ---------------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------ |
| [activepieces](activepieces/)       | Workflow automation          | 8080                    | [activepieces.com](https://www.activepieces.com/docs/install/docker)                                   |
| [adguard-home](adguard-home/)       | DNS ad blocker               | Host network (UI: 3001) | [adguard.com](https://adguard.com/adguard-home/overview.html)                                          |
| [audiobookshelf](audiobookshelf/)   | Audiobook and podcast server | 13378                   | [audiobookshelf.org](https://www.audiobookshelf.org/docs)                                              |
| [authentik](authentik/)             | Identity provider / SSO      | 9000                    | [goauthentik.io](https://docs.goauthentik.io/)                                                         |
| [changedetection](changedetection/) | Website change monitoring    | 5050                    | [github.com](https://github.com/dgtlmoon/changedetection.io/wiki)                                      |
| [diun](diun/)                       | Docker image update notifier | —                       | [crazymax.dev](https://crazymax.dev/diun/)                                                             |
| [floppy](floppy/)                   | Media tracker                | 8010                    | [github.com](https://github.com/dannyvfilms/Floppy/wiki)                                               |
| [forgejo](forgejo/)                 | Self-hosted Git              | 3003 (HTTP) / 222 (SSH) | [forgejo.org](https://forgejo.org/docs/latest/)                                                        |
| [forgejo-runner](forgejo-runner/)   | Forgejo Actions runner (VM)  | —                       | [forgejo.org](https://forgejo.org/docs/latest/admin/actions/)                                          |
| [homarr](homarr/)                   | Homepage / dashboard         | 7575                    | [homarr.dev](https://homarr.dev/docs/getting-started/)                                                 |
| [immich](immich/)                   | Photo management             | 2283                    | [immich.app](https://immich.app/docs/overview/introduction)                                            |
| [immichframe](immichframe/)         | Photo frame for Immich       | 8085                    | [immichframe.dev](https://immichframe.dev/docs/)                                                       |
| [jellyfin](jellyfin/)               | Media server                 | 8096                    | [jellyfin.org](https://jellyfin.org/docs/)                                                             |
| [karakeep](karakeep/)               | Bookmarks with AI tagging    | 3010                    | [docs.karakeep.app](https://docs.karakeep.app/)                                                        |
| [kavita](kavita/)                   | Manga, comics and e-books    | 5010                    | [kavitareader.com](https://wiki.kavitareader.com/)                                                     |
| [monitoring](monitoring/)           | Prometheus + Grafana         | 9090 / 3000             | [prometheus.io](https://prometheus.io/docs/) / [grafana.com](https://grafana.com/docs/grafana/latest/) |
| [n8n](n8n/)                         | Workflow automation          | 5678                    | [docs.n8n.io](https://docs.n8n.io/)                                                                    |
| [navidrome](navidrome/)             | Music server (Subsonic)      | 4533                    | [navidrome.org](https://www.navidrome.org/docs/)                                                       |
| [paperless-ngx](paperless-ngx/)     | Document management with OCR | 8000                    | [docs.paperless-ngx.com](https://docs.paperless-ngx.com/)                                              |
| [spoolman](spoolman/)               | 3D printer filament manager  | 7912                    | [github.com](https://github.com/Donkie/Spoolman)                                                       |
| [uptime-kuma](uptime-kuma/)         | Uptime monitoring            | 3002                    | [github.com](https://github.com/louislam/uptime-kuma/wiki)                                             |

## Usage

```bash
sudo ./stacks setup  [service...]  # Generate .env files and create directories
     ./stacks deploy [service...]  # Git pull, pull images, start containers
     ./stacks lint                 # Validate all configs
```

If no service is specified, the command applies to all stacks.

### Setup

`./stacks setup` will:

1. Copy `.env.example` to `.env` (skipped if `.env` already exists)
2. Generate random secrets, replacing all `changeme` placeholders
3. Set `.env` permissions to `600`
4. Create required data directories
5. Configure git hooks (if inside a git repo)

### Deploy

`./stacks deploy authentik` will:

1. Pull the latest repo changes (`git pull --ff-only`)
2. Pull the latest images (`docker compose pull`)
3. Recreate changed containers (`docker compose up -d`)

Stacks with `REMOTE_DOCKER_HOST` in their `.env` are deployed to that Docker host over SSH instead of
locally (used by [forgejo-runner](forgejo-runner/), which runs in a dedicated VM).

### Configuration

Each stack has a `.env.example` with configurable ports and secrets:

```bash
vim authentik/.env
```

## Reverse Proxy

All stacks bind to `127.0.0.1` and require a reverse proxy for access.

### General Settings

- **Target**: `127.0.0.1:<port>` (see port table above)
- **WebSocket headers**: `Upgrade: $http_upgrade`, `Connection: $connection_upgrade`
- **HSTS**: enabled
- **Timeout**: 300s minimum

### Per-Stack Notes

| Stack           | Proxy entries            | WebSocket    | Timeout |
| --------------- | ------------------------ | ------------ | ------- |
| activepieces    | 1                        | Yes          | 300s    |
| adguard-home    | 1 (UI: 3001)             | Yes          | 300s    |
| audiobookshelf  | 1                        | Yes          | 300s    |
| authentik       | 1                        | Yes          | 300s    |
| changedetection | 1                        | Yes          | 300s    |
| diun            | —                        | —            | —       |
| floppy          | 1                        | Yes          | 300s    |
| forgejo         | 1                        | Yes          | 600s    |
| forgejo-runner  | —                        | —            | —       |
| homarr          | 1                        | Yes          | 300s    |
| immich          | 1                        | Yes          | 300s    |
| immichframe     | 1                        | No           | 300s    |
| jellyfin        | 1                        | Yes          | 300s    |
| karakeep        | 1                        | Yes          | 300s    |
| kavita          | 1                        | Yes          | 300s    |
| monitoring      | 2 (Prometheus + Grafana) | Grafana only | 300s    |
| n8n             | 1                        | Yes          | 300s    |
| navidrome       | 1                        | Yes          | 300s    |
| paperless-ngx   | 1                        | Yes          | 300s    |
| spoolman        | 1                        | Yes          | 300s    |
| uptime-kuma     | 1                        | Yes          | 300s    |

Diun has no web UI and does not need a reverse proxy entry. The Forgejo runner only makes outgoing
connections and runs in a separate VM. Spoolman can additionally be bound to the LAN interface
(`SPOOLMAN_BIND`), so that 3D printers can reach its API directly.

## Security

All stacks are hardened with:

- Ports bound to `127.0.0.1` — a reverse proxy is required for access
- Dropped capabilities (`cap_drop`); only the capabilities an image needs are added back
- `no-new-privileges` wherever the image allows it
- Memory limits per container
- Docker socket access via read-only socket proxy (Diun, Homarr)
- Secrets in `.env` files with `chmod 600`
- Pinned image versions, no `:latest` tags

Deliberate exceptions:

- [adguard-home](adguard-home/) uses the host network, because it serves DNS to the LAN.
- The SSH port of [forgejo](forgejo/) and the API of [spoolman](spoolman/) can be bound to the LAN via `.env`
  (default: `127.0.0.1`).
- Images whose entrypoint switches users (e.g. Forgejo, Paperless, Homarr) run without `no-new-privileges`;
  Immich keeps the capabilities of its official rootless setup (`cap_drop: NET_RAW`).
- The Docker-in-Docker container of [forgejo-runner](forgejo-runner/) must be privileged and therefore runs in
  a dedicated VM.

Stack-specific notes are in the `README.md` of each stack directory.

## Linting

```bash
./stacks lint
```

Validates all stacks for consistent logging, restart policies, port binding,
image tags, and `.env.example` completeness. Includes `docker compose config`,
`yamllint`, `markdownlint` and `shellcheck` when available. Also runs as a pre-commit hook.

## Updates

All images are pinned to specific versions — no `:latest` tags. New versions are found in two ways:

- The `update-images` workflow ([.github/images.json](.github/images.json)) opens a pull request with new
  versions of the main images.
- [Diun](diun/) watches the tag lists of all running containers and sends notifications, including helper
  images such as Postgres and Redis.

Before updating a stack:

1. Read the release notes — some applications require intermediate versions (e.g. authentik, Paperless-ngx)
   and cannot be downgraded afterwards.
2. Stop the stack and back up its directory, plus a `pg_dump` for stacks with Postgres.
3. Update the version in `docker-compose.yml` and run `./stacks deploy <stack>`.
4. Check the logs until migrations have finished.

### Postgres

Each stack uses the Postgres major version its application supports or ships in its official setup. Minor
versions (e.g. 16.10 → 16.15) are a simple image update. A **major** upgrade (e.g. 16 → 18) requires a dump
of the database, an empty data directory and a restore — the new version cannot read the old data files.

Since Postgres 18, the official image keeps its data in a versioned subdirectory: the volume must be mounted
at `/var/lib/postgresql` instead of `/var/lib/postgresql/data`.

Postgres containers carry Diun labels that report new minor releases of their major version only (see
[diun](diun/README.md#per-container-labels)).

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## Support

If you find this project useful, consider
[supporting its development](https://ko-fi.com/marcstraube).

## License

MIT

## Author

Marc Straube ([email@marcstraube.de](mailto:email@marcstraube.de))
