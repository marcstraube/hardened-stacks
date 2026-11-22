# Navidrome

Music server with a web player and the Subsonic API, so it works with many apps (e.g. Symfonium,
Substreamer, Feishin, Tempo). See the [Navidrome documentation](https://www.navidrome.org/docs/).

## First Start

1. Set `NAVIDROME_MUSIC_PATH` in `.env` to the music folder on the host.
2. `./stacks deploy navidrome`. The first visit creates the admin account.
3. The first scan starts automatically; large libraries take a while.

## Library

The music folder is mounted read-only. Navidrome reads tags and cover art from the files and keeps
everything else (play counts, ratings, playlists) in its database under `data/`. New files are picked up
by the file watcher, and a full rescan runs once a day (`ND_SCANSCHEDULE`).

## Apps

Clients connect with the Navidrome URL, username and password over the Subsonic API. Playlists can
be imported as `.m3u` files from the library folder.
