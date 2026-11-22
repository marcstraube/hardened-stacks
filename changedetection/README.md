# changedetection.io

Monitors websites and APIs for changes (new releases, prices, stock, text) and sends notifications. See
the [changedetection.io wiki](https://github.com/dgtlmoon/changedetection.io/wiki).

## First Start

1. Set `CHANGEDETECTION_BASE_URL` in `.env` to the public URL; it is used for links in notifications.
2. `./stacks deploy changedetection`.
3. **Set a password right away** under Settings → General. changedetection.io has no login by default,
   so anyone who can reach the page can see and change all watches.

## Notifications

Notifications use [Apprise](https://github.com/caronc/apprise/wiki) URLs, e.g. `tgram://<bot-token>/<chat-id>`
for Telegram. They can be set globally under Settings → Notifications or per watch.

## JavaScript Pages

This stack fetches pages with plain HTTP requests, which covers most sites and JSON APIs. Pages that
only render their content with JavaScript need a browser; see the
[browser setup in the wiki](https://github.com/dgtlmoon/changedetection.io/wiki/Fetching-pages-with-WebDriver).
If a site offers an API or RSS feed, watching that is lighter and more reliable.

## Check Intervals

Each watch has its own interval (e.g. every 6 hours) and can be limited to specific days and times.
`FETCH_WORKERS` limits parallel checks to keep the load low.
