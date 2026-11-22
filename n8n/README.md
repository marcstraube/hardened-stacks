# n8n

Workflow automation. See the [n8n documentation](https://docs.n8n.io/).

## Task Runners

Code nodes (JavaScript and Python) do not run in the n8n process, which holds the credentials and the
encryption key, but in the separate `runners` container
([external mode](https://docs.n8n.io/hosting/configuration/task-runners/)). n8n and the runners connect
with `N8N_RUNNERS_AUTH_TOKEN`; the `n8nio/runners` image must always have the same version as `n8nio/n8n`.

### Allowing modules in Code nodes

By default, Code nodes may only import a few modules:

| Language   | Allowed by default                 |
| ---------- | ---------------------------------- |
| JavaScript | `crypto` (built-in), `moment`      |
| Python     | none (standard library or package) |

The allow lists are set in the launcher configuration of the runners image (`/etc/n8n-task-runners.json`),
not through environment variables of the container. To change them:

1. Copy the configuration of the running version next to `docker-compose.yml`:

   ```bash
   docker run --rm --entrypoint cat n8nio/runners:<version> /etc/n8n-task-runners.json > n8n-task-runners.json
   ```

2. Edit `env-overrides` of the runner in question (comma-separated lists, `*` allows everything):

   | Variable                       | Runner     | Purpose                       |
   | ------------------------------ | ---------- | ----------------------------- |
   | `NODE_FUNCTION_ALLOW_BUILTIN`  | JavaScript | Node.js built-ins, e.g. `fs`  |
   | `NODE_FUNCTION_ALLOW_EXTERNAL` | JavaScript | npm packages in the image     |
   | `N8N_RUNNERS_STDLIB_ALLOW`     | Python     | Standard library, e.g. `json` |
   | `N8N_RUNNERS_EXTERNAL_ALLOW`   | Python     | pip packages in the image     |

3. Uncomment the volume of the `runners` service in `docker-compose.yml` and run `./stacks deploy n8n`.

After an update of n8n, compare the file with the one in the new image, so that changed paths or arguments
are not overwritten by the old copy. Packages that are not part of the image require a
[custom runners image](https://docs.n8n.io/hosting/configuration/task-runners/#adding-extra-dependencies).
