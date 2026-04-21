#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

deploy_service() {
  local service="$1"
  local dir="$ROOT_DIR/$service"

  if [[ ! -f "$dir/docker-compose.yml" ]]; then
    echo "Unknown service: $service"
    return 1
  fi

  echo "Deploying $service..."

  # Ensure .env exists
  if [[ ! -f "$dir/.env" ]] && [[ -f "$dir/.env.example" ]]; then
    echo "  .env missing, running setup first..."
    "$ROOT_DIR/scripts/setup.sh" "$service"
  fi

  docker compose -f "$dir/docker-compose.yml" pull
  docker compose -f "$dir/docker-compose.yml" up -d
  echo "  done"
  echo ""
}

# Pull latest repo changes if a remote is configured
if git -C "$ROOT_DIR" remote get-url origin &>/dev/null; then
  echo "Updating repository..."
  git -C "$ROOT_DIR" pull --ff-only
  echo ""
fi

services=(activepieces adguard-home authentik diun forgejo homarr immich jellyfin monitoring n8n paperless-ngx uptime-kuma)

if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    deploy_service "$arg"
  done
else
  for svc in "${services[@]}"; do
    deploy_service "$svc"
  done
fi

echo "Deploy complete."
