# Diun

Notifies about new versions of the images used by all running containers. See the
[Diun documentation](https://crazymax.dev/diun/). Diun has no web interface.

Diun reads containers through a read-only Docker socket proxy (`CONTAINERS=1`, `IMAGES=1`, `POST=0`).

## Notifications

All `DIUN_*` variables in `.env` are passed to Diun. Uncomment and fill in at least one notifier, e.g.
Telegram:

```bash
DIUN_NOTIF_TELEGRAM_TOKEN=123456:ABC...
DIUN_NOTIF_TELEGRAM_CHATIDS=123456789
```

Other notifiers (email, ntfy, Pushover, …) are listed in the
[notifier documentation](https://crazymax.dev/diun/config/notif/).

## How Updates Are Detected

Images are pinned to exact versions, so watching only the digest of the running tag would never report
anything. Diun therefore watches the **tag list** of every image (`DIUN_DEFAULTS_WATCHMODE: all`):

- Only full version tags count (`1.2.3`, `v1.2.3`); floating tags such as `17.0` or `latest` are ignored.
- The newest `DIUN_MAXTAGS` tags (default 5) are compared, sorted as semver.
- On the very first check of an image Diun only records the tags and sends no notification.

When a stack starts watching an image repository that Diun already knows, every matching tag is reported
once as new — expect a burst of notifications after adding labels or new images.

## Per-Container Labels

Images whose tags do not fit the default need labels on the container, for example Postgres (two-part tags
such as `16.15-alpine`, which cannot be sorted as semver):

```yaml
labels:
  diun.include_tags: '^16\.\d+-alpine$$'
  diun.max_tags: "100"
```

This reports new minor releases of the running major version only (major upgrades need a dump and restore).
`$$` escapes `$` in Compose files. Without `max_tags`, only the alphabetically first tags would be compared and
newer versions would never be reported.

## Additional Images

`images.yml` lists images that Diun watches in addition to the running containers. n8n publishes beta
releases with the same version scheme as stable ones (e.g. `2.48.x` beta while `2.47.x` is stable), so the
tag list cannot tell them apart. The n8n containers are therefore excluded with `diun.enable: "false"`, and
Diun watches the digest of the `n8nio/n8n:stable` tag instead, which only moves on stable releases. The
notification names the tag, not the version; check the
[n8n releases](https://github.com/n8n-io/n8n/releases) for the new number.

## Rate Limits

Every check queries the registries. Two parallel workers (`DIUN_WATCH_WORKERS`) keep the burst of DNS
queries low enough for a local resolver with rate limiting (e.g. AdGuard Home). Unauthenticated Docker Hub
pulls are rate-limited; Diun compares digests first, which does not count against the limit.
