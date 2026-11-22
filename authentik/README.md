# authentik

Identity provider and single sign-on. See the [authentik documentation](https://docs.goauthentik.io/).

## First Start

1. `sudo ./stacks setup authentik` and `./stacks deploy authentik`
2. Open `https://<your-domain>/if/flow/initial-setup/` and create the admin account (`akadmin`).

Server and worker run as `PUID`/`PGID` without root. The directories `data/`, `custom-templates/` and
`certs/` must be owned by that user.

## Storage

| Host directory      | Container path | Content                                                 |
| ------------------- | -------------- | ------------------------------------------------------- |
| `data/`             | `/data`        | Uploaded files (`data/media`: icons, branding), reports |
| `custom-templates/` | `/templates`   | Custom email and flow templates                         |
| `certs/`            | `/certs`       | Certificates picked up by the worker                    |

Uploaded files are served under `/files/` (before 2025.12: `/media/`).

## Upgrades

- authentik must be upgraded **one release line at a time** (e.g. 2026.2 → 2026.5 → 2026.8), always to the
  latest patch version of each line. Skipping a line is not supported.
- **Downgrades are not possible** — back up the database (`pg_dump`) before every upgrade.
- After the last step, run `ANALYZE;` on the database.

Forwarded headers are only trusted from `AUTHENTIK_LISTEN__TRUSTED_PROXY_CIDRS` (default: private
networks). If the reverse proxy connects from another address, set it explicitly.

## Database

The official authentik setup uses Postgres 16, which is kept here. authentik does not need Redis.
