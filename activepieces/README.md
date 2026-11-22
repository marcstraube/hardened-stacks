# Activepieces

Workflow automation (MIT-licensed community edition). See the
[Activepieces documentation](https://www.activepieces.com/docs).

## pgvector

The database runs on `pgvector/pgvector` (Postgres 16 with the pgvector extension). It enables two
features for AI agents:

- the **knowledge base** (documents that agents search before answering)
- **semantic tool search** (agents find matching tools by meaning instead of keywords)

Embeddings are calculated by the configured AI provider, not locally; pgvector itself needs little memory.
Without these features, plain `postgres:16-alpine` works as well — switching between the two images
requires a dump and restore (Debian vs. Alpine collations).

Activepieces only tests Postgres 14 and 16 and Redis 7, so neither is upgraded to a newer major version.

## Memory

App and worker run in one container. The worker executes up to five flows in parallel, each in its own
process, so the container needs about 1 GB without any flows and has a 2 GB limit.

## Upgrades

Activepieces runs its database migrations on startup. After skipping several versions, the first start can
take 15 minutes or more; the worker logs `Socket.IO connection error` until the app is ready. Do not
restart the container during that time.

Code steps run in Deno since 0.93 and see no environment variables in the default `UNSANDBOXED` mode
(`AP_SANDBOX_PROPAGATED_ENV_VARS` passes selected variables).
