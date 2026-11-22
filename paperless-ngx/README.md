# Paperless-ngx

Document management with OCR. See the [Paperless-ngx documentation](https://docs.paperless-ngx.com/).

The stack consists of Paperless, Postgres, Redis, [Tika](https://tika.apache.org/) (text extraction from
Office documents and emails) and [Gotenberg](https://gotenberg.dev/) (conversion to PDF).

## OCR and Archive Files

Paperless stores up to two files per document:

- the **original**, unchanged
- an **archive version**: a PDF/A with an OCR text layer, used for display and download

Search uses the text stored in the database, not the files. Two independent settings control processing
(both default to `auto`):

| Setting                             | `auto` behaviour                                                        |
| ----------------------------------- | ----------------------------------------------------------------------- |
| `PAPERLESS_OCR_MODE`                | OCR only if the document has no (or not enough) embedded text           |
| `PAPERLESS_ARCHIVE_FILE_GENERATION` | Archive only for scans and images; born-digital PDFs are not duplicated |

Recommendations:

- **Scanners:** save scans as image-only PDF (OCR disabled in the scan software). Paperless then runs OCR
  itself with the configured languages (`PAPERLESS_OCR_LANGUAGE`) and creates an archive file.
- If documents arrive with a poor text layer (e.g. scanner-side OCR), set `PAPERLESS_OCR_MODE=redo` to
  replace it. Single documents can be reprocessed in the web interface.
- `PAPERLESS_ARCHIVE_FILE_GENERATION=always` restores the v2 behaviour (a PDF/A for every document).

## Duplicates

`PAPERLESS_CONSUMER_DELETE_DUPLICATES=true` rejects files that are byte-identical to an existing document and
deletes them from the consume folder. Without it, Paperless v3 imports duplicates and marks them in the web
interface. A second scan of the same paper is never byte-identical and is not detected either way.

## Pinned Helper Versions

- **Gotenberg 8.x:** Gotenberg 9 changed its API; Paperless still uses the v8 API.
- **Tika 3.x:** Tika 4 removed endpoints that Paperless relies on.

Do not accept automatic major updates for these two images before Paperless supports them.

## Reverse Proxy

If logins fail with `403 Forbidden` behind the reverse proxy, set `PAPERLESS_URL` to the public URL and add
`PAPERLESS_TRUSTED_PROXIES` (the proxy's source IP or network).

## Backup and Upgrades

In addition to a file backup, Paperless can export all documents and metadata in a version-independent
format:

```bash
docker exec paperless document_exporter ../export
```

Upgrading from 2.x to 3.x requires 2.20.15 first. A major Postgres upgrade requires a dump and restore;
since Postgres 18 the data is mounted at `/var/lib/postgresql` instead of `/var/lib/postgresql/data`.
