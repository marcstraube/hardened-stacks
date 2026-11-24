# ImmichFrame

Turns browsers, tablets and TVs into digital photo frames that show photos from [Immich](../immich/). See the
[ImmichFrame documentation](https://immichframe.dev/docs/).

## Requirements

- Immich v3.3 or newer
- The Immich URL must be reachable **from the container**: `localhost` / `127.0.0.1` is the container itself,
  so use the public URL of the reverse proxy.

## First Start

1. `sudo ./stacks setup immichframe`, then `sudo chown -R <PUID>:<PGID> config/ cache/` in the stack directory
   (the container does not start without write access to `config/`).
2. `./stacks deploy immichframe`, open `/admin` and log in with `IMMICHFRAME_ADMIN_PASSWORD` from `.env`.
3. Create an API key in Immich (Account Settings → API Keys) with only the permissions listed below.
4. Add the account in the admin UI; **Test connection** checks the URL and the key.

ImmichFrame only reads from Immich. Select exactly these permissions:

`album.read`, `album.statistics`, `asset.read`, `asset.statistics`, `asset.view`, `face.read`, `memory.read`,
`person.read`, `person.statistics`, `tag.read`

The admin password is always set, because without it the first visitor could choose one on the setup screen.

## Access Control

Without further settings, everyone who can reach the page sees the photos. Do not expose ImmichFrame to the
internet. Set *AuthenticationSecret* in the admin UI to require a secret, which frames pass as
`?authsecret=<secret>`. The secret then appears in the proxy's access log.

The admin UI transmits the Immich API keys in plain text, so always use HTTPS. To limit what a frame can show
at all, create the API key with a separate Immich user, share albums with that user and select them under
*Albums*.

## Photo Selection

By default all photos of the account are shown. Favorites, albums, people, tags and memories each **restrict**
the selection; several of them are combined. Memories only contain photos matching the current date, so with
*ShowMemories* as the only source a frame may repeat a single photo or stay empty.

## Settings

Settings are stored in an SQLite database in `config/`, including the API keys — back up this directory and
keep it private. Apart from the variables in `docker-compose.yml`, ImmichFrame no longer reads settings from
the environment. Images are only cached in `cache/` when *DownloadImages* is enabled.

## Private Certificate Authority

If the reverse proxy uses a certificate of a private CA, copy the root certificate (PEM, readable by `PUID`)
to `certs/`, e.g. `certs/root-ca.crt`, and restart the container. It is trusted in addition to the public CAs.
