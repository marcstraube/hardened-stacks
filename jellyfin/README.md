# Jellyfin

Media server for movies, series and music. See the [Jellyfin documentation](https://jellyfin.org/docs/).

## Media

Set `JELLYFIN_MEDIA_PATH` in `.env` to the media library on the host (e.g. `/volume1/media`). It is mounted
read-only at `/media`; add libraries in the web interface with paths below `/media`. To mount several
folders (e.g. video and music), add further read-only volumes to `docker-compose.yml`.

The library must be readable by `PUID`/`PGID`.

## Hardware Transcoding (Intel Quick Sync)

Intel CPUs with an iGPU can transcode in hardware, which is much faster and uses less CPU. Uncomment the
`devices` and `group_add` section in `docker-compose.yml` and set the group ID of the render device:

```bash
stat -c '%g' /dev/dri/renderD128
```

The group differs between systems (Debian/Ubuntu: `render`/`video`, Synology DSM: `videodriver`, e.g.
`937`). Then enable *Intel QuickSync (QSV)* or *VAAPI* under Dashboard → Playback → Transcoding.

## Startup Warnings

The log shows warnings about `DataProtection` (in-memory key repository) and a missing `/wwwroot` on every
start. Both come from the official image and are harmless.
