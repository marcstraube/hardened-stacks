#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0
warnings=0

err()  { echo "  ERROR: $1"; errors=$((errors + 1)); }
warn() { echo "  WARN:  $1"; warnings=$((warnings + 1)); }
ok()   { echo "  OK:    $1"; }

for dir in "$ROOT_DIR"/*/; do
  service="$(basename "$dir")"
  compose="$dir/docker-compose.yml"

  [[ -f "$compose" ]] || continue
  echo "[$service]"

  # 1. Check .env.example exists if compose references variables
  vars_in_compose=$(grep -oP '\$\{(\w+)' "$compose" | sed 's/\${//' | sort -u || true)
  env_example="$dir/.env.example"

  if [[ -n "$vars_in_compose" ]]; then
    if [[ -f "$env_example" ]]; then
      for var in $vars_in_compose; do
        if ! grep -q "^${var}=" "$env_example"; then
          err "$var referenced in compose but missing in .env.example"
        fi
      done
      ok ".env.example present"
    else
      err "compose references variables but no .env.example found"
    fi
  fi

  # 2. Check no :latest tags
  if grep -qP 'image:.*:latest' "$compose"; then
    err "uses :latest tag"
  else
    ok "no :latest tags"
  fi

  # 3. Check all services have logging config
  # Count services and logging blocks
  svc_count=$(grep -c '^\s\+image:' "$compose" || true)
  log_count=$(grep -c 'driver: json-file' "$compose" || true)
  if [[ "$log_count" -lt "$svc_count" ]]; then
    err "logging missing on $((svc_count - log_count))/$svc_count container(s)"
  else
    ok "logging configured on all containers"
  fi

  # 4. Check all services have restart policy
  restart_count=$(grep -c 'restart:' "$compose" || true)
  if [[ "$restart_count" -lt "$svc_count" ]]; then
    err "restart policy missing on $((svc_count - restart_count))/$svc_count container(s)"
  else
    ok "restart policy on all containers"
  fi

  # 5. Check ports are bound to 127.0.0.1
  exposed_ports=$(grep -P '^\s+- "\d+' "$compose" | grep -v '127.0.0.1' || true)
  if [[ -n "$exposed_ports" ]]; then
    err "ports not bound to 127.0.0.1:$(echo "$exposed_ports" | sed 's/^/\n          /')"
  elif grep -qP '^\s+- "127.0.0.1:' "$compose"; then
    ok "all ports bound to 127.0.0.1"
  fi

  # 6. Check security hardening
  sec_count=$(grep -c 'no-new-privileges' "$compose" || true)
  if [[ "$sec_count" -lt "$svc_count" ]]; then
    # Not an error if cap_drop is set instead (some containers need privilege switching)
    cap_check=$(grep -c 'cap_drop:' "$compose" || true)
    if [[ "$cap_check" -lt "$svc_count" ]]; then
      err "no-new-privileges or cap_drop missing on some container(s)"
    else
      ok "hardening via cap_drop (no-new-privileges on $sec_count/$svc_count)"
    fi
  else
    ok "no-new-privileges on all containers"
  fi

  cap_count=$(grep -c 'cap_drop:' "$compose" || true)
  if [[ "$cap_count" -lt "$svc_count" ]]; then
    err "cap_drop missing on $((svc_count - cap_count))/$svc_count container(s)"
  else
    ok "cap_drop on all containers"
  fi

  mem_count=$(grep -c 'mem_limit:' "$compose" || true)
  if [[ "$mem_count" -lt "$svc_count" ]]; then
    err "mem_limit missing on $((svc_count - mem_count))/$svc_count container(s)"
  else
    ok "mem_limit on all containers"
  fi

  # 7. Check setup.sh has entry for this service
  if ! grep -q "$service)" "$ROOT_DIR/scripts/setup.sh"; then
    warn "$service not listed in setup.sh"
  fi

  # 8. Check volume dirs listed in setup.sh match compose mounts
  # Extract host-side relative volume mounts from compose
  compose_dirs=$(grep -oP '\- \./\K[^:]+' "$compose" | grep '/' | sed 's|/.*||' | sort -u || true)
  compose_dirs+=$'\n'
  compose_dirs+=$(grep -oP '\- \./\K[^:/]+' "$compose" | sort -u || true)
  compose_dirs=$(echo "$compose_dirs" | sort -u | grep -v '^$' || true)

  if [[ -n "$compose_dirs" ]]; then
    setup_dirs=$(grep -A1 "${service})" "$ROOT_DIR/scripts/setup.sh" | grep -oP 'dirs=\(\K[^)]+' | tr ' ' '\n' | sort -u || true)
    for d in $compose_dirs; do
      if [[ -n "$setup_dirs" ]] && ! echo "$setup_dirs" | grep -q "^${d}\(/\|$\)"; then
        warn "volume ./$d mounted in compose but not created by setup.sh"
      fi
    done
  fi

  # 9. Validate compose file with docker compose config
  if command -v docker &>/dev/null; then
    env_file="$dir/.env"
    generated_env=false

    # Generate temporary .env if missing
    if [[ ! -f "$env_file" ]] && [[ -f "$dir/.env.example" ]]; then
      cp "$dir/.env.example" "$env_file"
      # Replace changeme with dummy values so config validation passes
      sed -i 's/=changeme$/=dummy-lint-value/' "$env_file"
      generated_env=true
    fi

    if docker compose -f "$compose" config -q 2>/dev/null; then
      ok "docker compose config valid"
    else
      err "docker compose config invalid"
    fi

    # Clean up temporary .env
    if [[ "$generated_env" == true ]]; then
      rm -f "$env_file"
    fi
  fi

  echo ""
done

# Lint YAML files
echo "[yaml]"
if command -v yamllint &>/dev/null; then
  yaml_errors=0
  while IFS= read -r -d '' yf; do
    name="${yf#"$ROOT_DIR/"}"
    if yamllint -s "$yf" >/dev/null 2>&1; then
      ok "$name"
    else
      err "$name"
      yaml_errors=$((yaml_errors + 1))
    fi
  done < <(find "$ROOT_DIR" -name '*.yml' -not -path '*/.git/*' -print0 | sort -z)
  if [[ "$yaml_errors" -eq 0 ]]; then
    ok "all YAML files pass yamllint"
  fi
else
  warn "yamllint not installed, skipping"
fi
echo ""

# Lint markdown files
echo "[markdown]"
if command -v markdownlint-cli2 &>/dev/null; then
  if markdownlint-cli2 "$ROOT_DIR"/**/*.md >/dev/null 2>&1; then
    ok "all markdown files pass markdownlint"
  else
    err "markdownlint found issues"
  fi
elif command -v markdownlint &>/dev/null; then
  if markdownlint "$ROOT_DIR"/**/*.md >/dev/null 2>&1; then
    ok "all markdown files pass markdownlint"
  else
    err "markdownlint found issues"
  fi
else
  warn "markdownlint not installed, skipping"
fi
echo ""

# Lint shell scripts
echo "[shell scripts]"
if command -v shellcheck &>/dev/null; then
  shell_errors=0
  for script in "$ROOT_DIR"/scripts/*.sh "$ROOT_DIR"/stacks; do
    if shellcheck -S warning "$script" >/dev/null 2>&1; then
      ok "$(basename "$script")"
    else
      err "$(basename "$script") has shellcheck warnings"
      shell_errors=$((shell_errors + 1))
    fi
  done
  if [[ "$shell_errors" -eq 0 ]]; then
    ok "all scripts pass shellcheck"
  fi
else
  warn "shellcheck not installed, skipping"
fi
echo ""

echo "---"
echo "Results: $errors error(s), $warnings warning(s)"
exit "$errors"
