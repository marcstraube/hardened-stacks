# Contributing to Hardened Stacks

Thank you for your interest in contributing! This document provides guidelines
and instructions for contributing to this project.

## Development Setup

### Prerequisites

- Docker or Podman with Compose support
- pre-commit (`pacman -S pre-commit` or `pip install pre-commit`)
- Node.js 22 (see `.nvmrc`)
- Git

### Clone and Setup

```bash
git clone https://github.com/marcstraube/hardened-stacks.git
cd hardened-stacks
pre-commit install
sudo ./stacks setup
```

## Linting

```bash
./stacks lint                    # Custom policy checks
pre-commit run --all-files       # All pre-commit hooks
```

### Custom policy checks (`./stacks lint`)

- Ports, logging, restart, hardening, image tags
- docker compose config validation
- yamllint, markdownlint, shellcheck (when available)

### Pre-commit hooks

- **yamllint** — YAML syntax and formatting
- **markdownlint** — Markdown formatting
- **shellcheck** — Shell script quality
- **detect-secrets** — Prevent accidental secret commits
- **trailing-whitespace** — Remove trailing whitespace
- **end-of-file-fixer** — Ensure files end with newline
- **check-yaml** — Validate YAML syntax
- **check-added-large-files** — Block files > 500KB
- **mixed-line-ending** — Enforce LF line endings

## Adding a New Stack

1. Create a directory with `docker-compose.yml` and `.env.example`
2. Follow the existing patterns:
   - Ports bound to `127.0.0.1` via `.env` variable
   - `security_opt: [no-new-privileges:true]`
   - `cap_drop: [ALL]` on every container
   - `mem_limit` on every container
   - Logging with `json-file` driver
   - `restart: unless-stopped`
   - Pinned image versions, no `:latest`
   - Secrets as `changeme` with `openssl` generation comment
3. Add the service to `scripts/setup.sh` (dirs list + services list)
4. Add a matrix entry in `.github/workflows/update-images.yml`
5. Update `README.md`
6. Run `./stacks lint` to verify

## Pull Request Process

1. Run `./stacks lint` and ensure it passes
2. Use conventional commit format:
   - `feat(paperless): add new stack`
   - `fix(authentik): correct port binding`
   - `chore(monitoring): update prometheus image`

## License

By contributing, you agree that your contributions will be licensed under
the MIT License.
