# Floppy

Tracker for movies, series, anime, manga, games, books, comics, music and podcasts. Floppy is a fork of
Yamtrack. See the [Floppy wiki](https://github.com/dannyvfilms/Floppy/wiki).

## First Start

1. Set `FLOPPY_URLS` in `.env` to the public URL (e.g. `https://floppy.example.com`). It is used for
   CSRF protection and the allowed hosts; logins fail with a CSRF error if it does not match.
2. `./stacks deploy floppy` and create your account on the sign-up page. The first start runs all
   database migrations and can take several minutes.
3. Set `FLOPPY_REGISTRATION=false` and deploy again. Otherwise anyone who can reach the page can create an
   account.
4. Promote your account to superuser. Floppy never does this automatically, but instance-wide settings
   (metadata providers, image cache) are only available to superusers:

   ```bash
   docker exec -u abc floppy python manage.py promote_superuser <username>
   ```

   Sign out and back in for the change to take effect. `--list` shows all accounts and their status.

The default port is `8010`, because Paperless-ngx already uses `8000`. The interface language can be
changed in the user settings.

## Language

`FLOPPY_TMDB_LANG` sets the language of movie and series titles and descriptions (e.g. `de-DE`); TMDB
falls back to English where no translation exists. The other providers (anime, manga, games, books) have
no language setting.

## Integrations

Floppy imports watch and reading progress from Jellyfin, Plex, Emby, Audiobookshelf, Komga, Kavita and
others, and history from Trakt, AniList, MyAnimeList, Goodreads and more. All of them are configured in
the Floppy settings. A REST API, webhooks and an MCP server are available for custom automation.

## Database

The official Floppy setup uses Postgres 16, which is kept here. `data/` holds keys generated on the first
start; keep it together with the database in backups. Floppy writes its own exports to `backups/`.
