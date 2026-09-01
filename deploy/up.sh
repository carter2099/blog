#!/usr/bin/env bash
# Start the deployed blog without depending on the canonical checkout's cwd.
set -euo pipefail

PRODUCTION_ROOT="${BLOG_PRODUCTION_ROOT:-${HOME}/blog}"
readonly PRODUCTION_ROOT
APP_ROOT="$PRODUCTION_ROOT/blog"
readonly APP_ROOT
COMPOSE_FILE="$APP_ROOT/docker-compose.prod.yml"
readonly COMPOSE_FILE
MASTER_KEY="$APP_ROOT/config/master.key"
readonly MASTER_KEY

if (($# > 0)); then
  printf 'usage: %s\n' "$0" >&2
  exit 2
fi
[[ -d "$APP_ROOT" ]] || {
  printf 'production blog checkout is missing: %s\n' "$APP_ROOT" >&2
  exit 1
}
[[ -f "$COMPOSE_FILE" ]] || {
  printf 'production compose file is missing: %s\n' "$COMPOSE_FILE" >&2
  exit 1
}
[[ -f "$MASTER_KEY" ]] || {
  printf 'production Rails master key is missing: %s\n' "$MASTER_KEY" >&2
  exit 1
}
command -v docker >/dev/null || {
  printf 'docker is required\n' >&2
  exit 1
}

export RAILS_MASTER_KEY
RAILS_MASTER_KEY="$(<"$MASTER_KEY")"
cd -- "$APP_ROOT" || exit 1
exec docker compose -f "$COMPOSE_FILE" up -d
