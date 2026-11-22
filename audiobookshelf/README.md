# Audiobookshelf

Server for audiobooks and podcasts with apps for Android and iOS. See the
[Audiobookshelf documentation](https://www.audiobookshelf.org/docs).

## First Start

1. Set `AUDIOBOOKSHELF_MEDIA_PATH` (and optionally `AUDIOBOOKSHELF_PODCAST_PATH`) in `.env`.
2. `./stacks deploy audiobookshelf` and open the web interface. The first visit creates the root
   (admin) account — do this right away, before anyone else can reach the page.
3. Add libraries with paths below `/audiobooks` (e.g. `/audiobooks/Hörspiele`) or `/podcasts`.

The libraries must be readable by `PUID`/`PGID`.

## Read-Only Library

The audiobook library is mounted read-only, so Audiobookshelf cannot change or delete your files. Covers
and metadata are stored in `metadata/` instead. Leave *Store covers with item* and *Store metadata with
item* (Settings) disabled.

The tools that rewrite files (embed metadata, merge into M4B) and deleting items from disk need write
access: remove `:ro` from the volume in `docker-compose.yml` if you want to use them.

## Podcasts

Podcast episodes are downloaded into `AUDIOBOOKSHELF_PODCAST_PATH`, which therefore stays writable.

## Mobile Apps

The apps connect to the public URL of the reverse proxy. Enable WebSocket support for the proxy entry,
otherwise playback progress does not sync.
