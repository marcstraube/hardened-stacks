# Karakeep

Bookmark manager for links, notes, images and PDFs with full-text search and optional AI tagging
(formerly Hoarder). See the [Karakeep documentation](https://docs.karakeep.app/).

## First Start

1. Set `KARAKEEP_URL` in `.env` to the public URL.
2. `./stacks deploy karakeep` and create your account. The first account is the admin.
3. Set `KARAKEEP_DISABLE_SIGNUPS=true` and deploy again.

## Services

- `karakeep`: web interface, API and background workers
- `chrome`: headless Chrome that crawls bookmarked pages (text, images, screenshots)
- `meilisearch`: full-text search index

## AI Tagging

Karakeep can tag and summarize bookmarks via any OpenAI-compatible API. Without
`KARAKEEP_AI_API_KEY`, bookmarks are saved and searchable but not tagged automatically.
`.env.example` contains the settings for Gemini; other providers are listed in the
[documentation](https://docs.karakeep.app/configuration/different-ai-providers). With a hosted provider,
the text of bookmarked pages is sent to that provider. `KARAKEEP_AI_LANG` sets the language of the
generated tags (e.g. `german`).

## Running as Non-Root

The image uses s6-overlay, which requires `/run` to belong to the running user, and Next.js writes its
image cache to `/app/apps/web/.next/cache`. The image prepares both for uid 1000 only, so the stack
mounts both as tmpfs owned by PUID/PGID. Karakeep then runs as that user instead of root.
