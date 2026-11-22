# Kavita

Reading server for manga, comics and e-books (CBZ, CBR, PDF, EPUB). See the
[Kavita wiki](https://wiki.kavitareader.com/).

## First Start

1. Set `KAVITA_MEDIA_PATH` in `.env` to the library folder on the host.
2. `./stacks deploy kavita`. The first visit asks for the admin account.
3. Add a library in the server settings. Inside the container, the media folder is at `/library`.
   Kavita expects one folder per series; see the
   [scanner documentation](https://wiki.kavitareader.com/guides/scanner/).

## Slow Storage

On the first start Kavita creates its database and aborts after five minutes if the migrations are not
finished (`Failed to run critical Migrations` in the log, followed by a restart loop). This can happen on
a NAS under heavy disk load. In that case, create the database in RAM once and copy it to disk:

```bash
docker compose rm -sf kavita
rm -rf config && mkdir config
docker run -d --name kavita-init --user "$(id -u):$(id -g)" --cap-drop ALL \
  --tmpfs /kavita/config:uid="$(id -u)",gid="$(id -g)" jvmilazz0/kavita:<version>
# wait until "docker exec kavita-init curl -fsS http://localhost:5000/api/health" succeeds
docker exec kavita-init tar -C /kavita/config -cf - . | tar -xf - -C config
docker rm -f kavita-init
docker compose up -d
```

Use the PUID/PGID from `.env` if they differ from your user.

## Read-Only Library

The library is mounted read-only. Kavita stores covers, read progress and metadata in `config/`. To let
Kavita write covers or metadata into the library, remove `:ro` from the volume in `docker-compose.yml`.

## Integrations

Kavita provides an OPDS feed (URL with API key in the user settings) for e-reader apps. Mihon/Tachiyomi
and Paperback have Kavita extensions, and Floppy can import read progress from Kavita. Kavita+ (a paid
subscription) adds external metadata and AniList scrobbling; it is not needed for the tracking in Floppy.

## Updates

Kavita publishes hotfixes (e.g. `v0.9.1.4`) under the minor image tag (`0.9.1`), so the tag stays the
same and only the image digest changes. Diun reports these as an updated image.
