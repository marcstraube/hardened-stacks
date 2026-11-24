#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Remove the containers that `docker compose up` would recreate (changed
# configuration or newer image), so that compose creates them fresh instead.
# When recreating, compose first renames the old container to
# "<id>_<name>"; Synology Container Manager tracks containers by name and keeps
# that temporary name, which leaves broken entries in its UI. The downtime is
# the same: compose stops the old container before starting the new one.
remove_outdated() {
  local compose_file="$1"
  shift
  local name svc
  # A dry run lists the containers compose would recreate ("... Recreate")
  for name in $(env "$@" docker compose -f "$compose_file" --dry-run up -d 2>&1 |
    awk '$NF == "Recreate" { print $(NF - 1) }'); do
    svc=$(env "$@" docker inspect -f '{{index .Config.Labels "com.docker.compose.service"}}' "$name")
    echo "  recreating $svc"
    env "$@" docker compose -f "$compose_file" rm -sf "$svc" >/dev/null
  done
}

deploy_service() {
  local service="$1"
  local strict="${2:-0}"  # 1 = fail if the stack cannot be deployed
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

  # Stacks that declare REMOTE_DOCKER_HOST in .env.example must run on that
  # host (e.g. the Forgejo runner VM) and are never deployed locally.
  local docker_host=""
  if grep -q '^REMOTE_DOCKER_HOST=' "$dir/.env.example" 2>/dev/null; then
    docker_host=$(grep -m1 '^REMOTE_DOCKER_HOST=' "$dir/.env" 2>/dev/null | cut -d= -f2- | tr -d '"' || true)
    if [[ -z "$docker_host" ]]; then
      echo "  skipped: REMOTE_DOCKER_HOST is not set in $service/.env"
      echo ""
      return "$strict"
    fi
    echo "  target: $docker_host"
  fi

  local env_args=()
  [[ -n "$docker_host" ]] && env_args=("DOCKER_HOST=$docker_host")

  env "${env_args[@]}" docker compose -f "$dir/docker-compose.yml" pull
  remove_outdated "$dir/docker-compose.yml" "${env_args[@]}"
  env "${env_args[@]}" docker compose -f "$dir/docker-compose.yml" up -d
  echo "  done"
  echo ""
}

# Pull latest repo changes if a remote is configured
if git -C "$ROOT_DIR" remote get-url origin &>/dev/null; then
  echo "Updating repository..."
  git -C "$ROOT_DIR" pull --ff-only
  echo ""
fi

services=(activepieces adguard-home audiobookshelf authentik changedetection diun floppy forgejo forgejo-runner homarr immich immichframe jellyfin karakeep kavita monitoring n8n navidrome paperless-ngx spoolman uptime-kuma)

if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    deploy_service "$arg" 1
  done
else
  for svc in "${services[@]}"; do
    deploy_service "$svc"
  done
fi

echo "Deploy complete."
