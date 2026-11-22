# Forgejo

Self-hosted Git forge. See the [Forgejo documentation](https://forgejo.org/docs/latest/).

## Git over SSH

The web interface is served through the reverse proxy, but SSH cannot be proxied over HTTP. By default the
SSH port is only bound to `127.0.0.1`. To clone and push over SSH from the LAN, set in `.env`:

```bash
FORGEJO_SSH_BIND=0.0.0.0
FORGEJO_SSH_PORT=222
```

Clone URLs then look like `ssh://git@<domain>:222/<user>/<repo>.git`. The built-in SSH server needs the
`SYS_CHROOT` capability.

## Options

| Variable                          | Default | Purpose                                                         |
| --------------------------------- | ------- | --------------------------------------------------------------- |
| `FORGEJO_ENABLE_PUSH_CREATE_USER` | `false` | Create a repository by pushing to a URL that does not exist yet |

Further settings can be added as `FORGEJO__<section>__<KEY>` environment variables, see the
[configuration cheat sheet](https://forgejo.org/docs/latest/admin/config-cheat-sheet/).

## Actions

Forgejo Actions is enabled. Jobs run on the separate [forgejo-runner](../forgejo-runner/) stack, which
must run in a dedicated VM.

## Upgrades

Forgejo migrates the database on startup and allows upgrading directly to the latest version. Check the
release notes for breaking changes and back up `data/` and the database first.

- LTS releases (e.g. 15, 19) are supported for about a year, other releases for about three months.
- Avoid `.0` releases with known issues — e.g. 17.0.0 had push/merge failures fixed in 17.0.1.

## Database

Forgejo's CI tests Postgres 16, which is kept here.
