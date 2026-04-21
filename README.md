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

| Stack                             | Description                  | Default Port            | Docs                                                                                                   |
| --------------------------------- | ---------------------------- | ----------------------- | ------------------------------------------------------------------------------------------------------ |
| [activepieces](activepieces/)     | Workflow automation          | 8080                    | [activepieces.com](https://www.activepieces.com/docs/install/docker)                                   |
| [adguard-home](adguard-home/)     | DNS ad blocker               | Host network (UI: 3001) | [adguard.com](https://adguard.com/adguard-home/overview.html)                                          |
| [authentik](authentik/)           | Identity provider / SSO      | 9000                    | [goauthentik.io](https://docs.goauthentik.io/)                                                         |
| [diun](diun/)                     | Docker image update notifier | 8899                    | [crazymax.dev](https://crazymax.dev/diun/)                                                             |
| [forgejo](forgejo/)               | Self-hosted Git              | 3003 (HTTP) / 222 (SSH) | [forgejo.org](https://forgejo.org/docs/latest/)                                                        |
| [homarr](homarr/)                 | Homepage / dashboard         | 7575                    | [homarr.dev](https://homarr.dev/docs/getting-started/)                                                 |
| [immich](immich/)                 | Photo management             | 2283                    | [immich.app](https://immich.app/docs/overview/introduction)                                            |
| [jellyfin](jellyfin/)             | Media server                 | 8096                    | [jellyfin.org](https://jellyfin.org/docs/)                                                             |
| [monitoring](monitoring/)         | Prometheus + Grafana         | 9090 / 3000             | [prometheus.io](https://prometheus.io/docs/) / [grafana.com](https://grafana.com/docs/grafana/latest/) |
| [n8n](n8n/)                       | Workflow automation          | 5678                    | [docs.n8n.io](https://docs.n8n.io/)                                                                    |
| [paperless-ngx](paperless-ngx/)   | Document management with OCR | 8000                    | [docs.paperless-ngx.com](https://docs.paperless-ngx.com/)                                              |
| [uptime-kuma](uptime-kuma/)       | Uptime monitoring            | 3002                    | [github.com](https://github.com/louislam/uptime-kuma/wiki)                                             |

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

| Stack         | Proxy entries            | WebSocket    | Timeout |
| ------------- | ------------------------ | ------------ | ------- |
| activepieces  | 1                        | Yes          | 300s    |
| adguard-home  | 1 (UI: 3001)             | Yes          | 300s    |
| authentik     | 1                        | Yes          | 300s    |
| diun          | —                        | —            | —       |
| forgejo       | 1                        | Yes          | 600s    |
| homarr        | 1                        | Yes          | 300s    |
| immich        | 1                        | Yes          | 300s    |
| jellyfin      | 1                        | Yes          | 300s    |
| monitoring    | 2 (Prometheus + Grafana) | Grafana only | 300s    |
| n8n           | 1                        | Yes          | 300s    |
| paperless-ngx | 1                        | Yes          | 300s    |
| uptime-kuma   | 1                        | Yes          | 300s    |

Diun has no web UI and does not need a reverse proxy entry.

## Security

All stacks are hardened with:

- Ports bound to `127.0.0.1` only — a reverse proxy is required for access
- `no-new-privileges` and `cap_drop: ALL` on every container
- Memory limits per container
- Docker socket access via read-only socket proxy (Diun, Homarr)
- Secrets in `.env` files with `chmod 600`
- Pinned image versions, no `:latest` tags

## Linting

```bash
./stacks lint
```

Validates all stacks for consistent logging, restart policies, port binding,
image tags, and `.env.example` completeness. Includes `docker compose config`,
`yamllint`, and `shellcheck` when available. Also runs as a pre-commit hook.

## Image Versions

All images are pinned to specific versions — no `:latest` tags.
[Diun](diun/) monitors for updates and sends notifications.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

## Support

If you find this project useful, consider
[supporting its development](https://ko-fi.com/marcstraube).

## License

MIT

## Author

Marc Straube ([email@marcstraube.de](mailto:email@marcstraube.de))
