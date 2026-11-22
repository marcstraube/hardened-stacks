# Homarr

Dashboard for the homelab. See the [Homarr documentation](https://homarr.dev/docs/getting-started/).

## Port

The container port is `7575` — Homarr's built-in proxy for the web interface and websockets. Port `3000`
is only the Next.js app behind it; mapping it directly breaks live updates.

## Docker Integration

Homarr reads containers through a read-only Docker socket proxy:

| Variable           | Value                 |
| ------------------ | --------------------- |
| `DOCKER_HOSTNAMES` | `docker-socket-proxy` |
| `DOCKER_PORTS`     | `2375`                |

Homarr ignores `DOCKER_HOST`. The socket proxy allows `CONTAINERS` and `IMAGES` with `POST=0`, so Homarr
can list containers but cannot start, stop or remove them. To enable the start/stop buttons on app tiles,
set `POST=1` on the socket proxy — this gives Homarr control over **all** containers on the host.

`ENABLE_DNS_CACHING=false` makes Homarr resolve the socket proxy freshly, because its IP changes when the
container is recreated.

## Secrets and Upgrades

`SECRET_ENCRYPTION_KEY` encrypts integration credentials in the database. Keep it together with the backup
of `data/` — without it, stored credentials cannot be decrypted.

Upgrades migrate the SQLite database in place. Going back to an older version is only possible by restoring
a backup (e.g. v2 cannot be downgraded to v1).
