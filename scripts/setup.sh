#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ $EUID -ne 0 ]]; then
  echo "Error: setup must be run as root (use sudo ./stacks setup)"
  exit 1
fi

gen_base64()  { openssl rand -base64 "$1" | tr -d '\n'; }
gen_hex()     { openssl rand -hex "$1"     | tr -d '\n'; }

setup_env() {
  local dir="$1"
  local env_file="$dir/.env"
  local example_file="$dir/.env.example"

  if [[ -f "$env_file" ]]; then
    echo "  .env already exists, skipping"
    return
  fi

  if [[ ! -f "$example_file" ]]; then
    echo "  no .env.example, skipping"
    return
  fi

  cp "$example_file" "$env_file"

  # Replace each 'changeme' with a generated secret based on the comment above it
  local tmpfile
  tmpfile=$(mktemp)
  local prev_comment=""
  while IFS= read -r line; do
    if [[ "$line" =~ ^#.*openssl ]]; then
      prev_comment="$line"
      echo "$line" >> "$tmpfile"
    elif [[ "$line" =~ =changeme$ ]] && [[ -n "$prev_comment" ]]; then
      local key="${line%%=*}"
      local secret
      if [[ "$prev_comment" =~ base64\ ([0-9]+) ]]; then
        secret=$(gen_base64 "${BASH_REMATCH[1]}")
      elif [[ "$prev_comment" =~ hex\ ([0-9]+) ]]; then
        secret=$(gen_hex "${BASH_REMATCH[1]}")
      else
        secret=$(gen_base64 32)
      fi
      echo "${key}=${secret}" >> "$tmpfile"
      prev_comment=""
    else
      echo "$line" >> "$tmpfile"
      prev_comment=""
    fi
  done < "$env_file"
  mv "$tmpfile" "$env_file"
  chmod 600 "$env_file"
  echo "  .env created with generated secrets"
}

setup_dirs() {
  local service="$1"
  local dirs=()

  case "$service" in
    activepieces) dirs=(postgres redis cache) ;;
    adguard-home) dirs=(work conf) ;;
    authentik)    dirs=(postgres media templates certs) ;;
    monitoring)   dirs=(prometheus/data grafana/data) ;;
    n8n)          dirs=(postgres data) ;;
    uptime-kuma)  dirs=(data) ;;
    diun)          dirs=(data) ;;
    forgejo)       dirs=(postgres data) ;;
    homarr)        dirs=(data) ;;
    immich)        dirs=(postgres upload external model-cache) ;;
    jellyfin)      dirs=(config cache media) ;;
    paperless-ngx) dirs=(postgres redis data media export consume) ;;
  esac

  for d in "${dirs[@]}"; do
    mkdir -p "$ROOT_DIR/$service/$d"
  done
  echo "  directories created"
}

setup_service() {
  local service="$1"
  local dir="$ROOT_DIR/$service"

  if [[ ! -d "$dir" ]]; then
    echo "Unknown service: $service"
    return 1
  fi

  echo "Setting up $service..."
  setup_env "$dir"
  setup_dirs "$service"
  echo ""
}

services=(activepieces adguard-home authentik diun forgejo homarr immich jellyfin monitoring n8n paperless-ngx uptime-kuma)

if [[ $# -gt 0 ]]; then
  for arg in "$@"; do
    setup_service "$arg"
  done
else
  for svc in "${services[@]}"; do
    setup_service "$svc"
  done
fi

# Configure git hooks if inside a git repo
if git -C "$ROOT_DIR" rev-parse --git-dir &>/dev/null; then
  git -C "$ROOT_DIR" config core.hooksPath .githooks
  echo "Git hooks configured."
fi

echo "Done."
