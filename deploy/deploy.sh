#!/usr/bin/env bash
# Fast-forward the production checkout, build, start, and health-check the blog.
set -euo pipefail
umask 077

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
SOURCE_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
readonly SOURCE_ROOT
PRODUCTION_ROOT="${BLOG_PRODUCTION_ROOT:-${HOME}/blog}"
readonly PRODUCTION_ROOT
PRODUCTION_APP="$PRODUCTION_ROOT/blog"
readonly PRODUCTION_APP
COMPOSE_FILE="$PRODUCTION_APP/docker-compose.prod.yml"
readonly COMPOSE_FILE
MASTER_KEY="$PRODUCTION_APP/config/master.key"
readonly MASTER_KEY
HEALTH_URL="${BLOG_HEALTH_URL:-http://127.0.0.1:33099/up}"
readonly HEALTH_URL
HEALTH_TIMEOUT="${BLOG_HEALTH_TIMEOUT:-60}"
readonly HEALTH_TIMEOUT
BRANCH='main'
readonly BRANCH

rollback_dir=""
transaction_started=0
committed=0
rollback_done=0
rollback_failed=0
old_commit=""
old_image_id=""
rollback_tag=""
cleanup() {
  local status=$?
  trap - EXIT INT TERM HUP
  if ((transaction_started && ! committed)); then
    if ! rollback; then
      status=1
    fi
  fi
  if [[ -n "$rollback_dir" && -d "$rollback_dir" ]] &&
     ((committed || ! rollback_failed)); then
    rm -rf -- "$rollback_dir"
  fi
  if [[ -n "$rollback_tag" ]] && ((committed || ! rollback_failed)); then
    docker image rm --force "$rollback_tag" >/dev/null 2>&1 || true
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

die() {
  printf '%s\n' "$1" >&2
  exit 1
}

[[ "$HEALTH_TIMEOUT" =~ ^[1-9][0-9]*$ ]] || die 'BLOG_HEALTH_TIMEOUT must be a positive integer'
[[ "$BRANCH" == main ]] || die 'production deployments are restricted to the main branch'
[[ "$PRODUCTION_ROOT" != / && "$PRODUCTION_ROOT" != "$SOURCE_ROOT" ]] ||
  die "unsafe production root: $PRODUCTION_ROOT"
[[ -d "$PRODUCTION_ROOT" && ! -L "$PRODUCTION_ROOT" ]] ||
  die "production root must be a real directory: $PRODUCTION_ROOT"
[[ -e "$SOURCE_ROOT/.git" ]] || die "canonical git repository is missing: $SOURCE_ROOT"
[[ -e "$PRODUCTION_APP/.git" ]] || die "production git checkout is missing: $PRODUCTION_APP"
[[ -f "$COMPOSE_FILE" && ! -L "$COMPOSE_FILE" ]] ||
  die "production compose file must be regular: $COMPOSE_FILE"
[[ -f "$MASTER_KEY" && ! -L "$MASTER_KEY" ]] ||
  die "production Rails master key must be regular: $MASTER_KEY"
master_key_owner="$(stat -c '%U' "$MASTER_KEY")"
master_key_mode="$(stat -c '%a' "$MASTER_KEY")"
master_key_links="$(stat -c '%h' "$MASTER_KEY")"
[[ "$master_key_owner" == "$(id -un)" &&
   "$master_key_mode" == 600 &&
   "$master_key_links" == 1 ]] ||
  die "production Rails master key must be owned by $(id -un), mode 0600, with one link"
for wrapper in "$PRODUCTION_ROOT/up.sh" "$PRODUCTION_ROOT/release.sh"; do
  [[ ! -L "$wrapper" ]] || die "refusing symlinked deployment wrapper: $wrapper"
done
command -v git >/dev/null || die 'git is required'
command -v docker >/dev/null || die 'docker is required'
command -v curl >/dev/null || die 'curl is required for the health check'

source_branch="$(git -C "$SOURCE_ROOT" symbolic-ref --short HEAD)"
[[ "$source_branch" == "$BRANCH" ]] || die "canonical checkout must be on $BRANCH"
[[ -z "$(git -C "$SOURCE_ROOT" status --porcelain)" ]] || die 'canonical checkout has uncommitted changes'
production_branch="$(git -C "$PRODUCTION_APP" symbolic-ref --short HEAD)"
[[ "$production_branch" == "$BRANCH" ]] || die "production checkout must be on $BRANCH"
[[ -z "$(git -C "$PRODUCTION_APP" status --porcelain)" ]] || die 'production checkout has uncommitted changes'

old_commit="$(git -C "$PRODUCTION_APP" rev-parse HEAD)"
canonical_commit="$(git -C "$SOURCE_ROOT" rev-parse "$BRANCH")"
git -C "$PRODUCTION_APP" fetch --prune origin "$BRANCH"
remote_commit="$(git -C "$PRODUCTION_APP" rev-parse "origin/$BRANCH")"
[[ "$canonical_commit" == "$remote_commit" ]] || die 'canonical main must be pushed before deployment'
if ! git -C "$PRODUCTION_APP" merge-base --is-ancestor "$old_commit" "$remote_commit"; then
  die 'production checkout is not behind origin/main; refusing a non-fast-forward update'
fi

old_image_id="$(docker image inspect blog-web --format '{{.Id}}' 2>/dev/null || true)"
[[ -n "$old_image_id" ]] || die 'no existing blog-web image is available for rollback'
rollback_tag="blog-web:rollback-${old_commit:0:12}-${BASHPID}"
docker image tag "$old_image_id" "$rollback_tag"

rollback_dir="$(mktemp -d "${TMPDIR:-/tmp}/blog-deploy-rollback.XXXXXX")"
backup_wrapper() {
  local path="$1"
  local name="$2"
  if [[ -e "$path" || -L "$path" ]]; then
    cp -a -- "$path" "$rollback_dir/$name"
    : > "$rollback_dir/$name.present"
  fi
}
backup_wrapper "$PRODUCTION_ROOT/up.sh" up.sh
backup_wrapper "$PRODUCTION_ROOT/release.sh" release.sh

compose() {
  (cd -- "$PRODUCTION_APP" && docker compose -f "$COMPOSE_FILE" "$@")
}

wait_for_health() {
  local attempt
  for ((attempt = 0; attempt < HEALTH_TIMEOUT; attempt++)); do
    if curl --fail --silent --show-error --max-time 3 "$HEALTH_URL" >/dev/null; then
      return 0
    fi
    sleep 1
  done
  return 1
}

restore_wrapper() {
  local destination="$1"
  local name="$2"
  local temporary
  if [[ -e "$rollback_dir/$name.present" ]]; then
    temporary="$(mktemp "${destination}.rollback.XXXXXX")"
    if ! install -m 0755 "$rollback_dir/$name" "$temporary"; then
      rm -f -- "$temporary"
      return 1
    fi
    mv -f -- "$temporary" "$destination"
  else
    rm -f -- "$destination"
  fi
}

install_wrapper() {
  local destination="$1"
  local target="$2"
  local temporary
  temporary="$(mktemp "${destination}.tmp.XXXXXX")"
  if ! {
    printf '%s\n' '#!/usr/bin/env bash'
    printf '%s\n' 'set -euo pipefail'
    printf 'exec %q "$%s"\n' "$target" '@'
  } >"$temporary"; then
    rm -f -- "$temporary"
    return 1
  fi
  chmod 0755 "$temporary"
  mv -f -- "$temporary" "$destination"
}

rollback() {
  local failed=0
  if ((rollback_done)); then
    ((rollback_failed == 0))
    return
  fi
  rollback_done=1
  git -C "$PRODUCTION_APP" reset --hard "$old_commit" >/dev/null 2>&1 || failed=1
  docker image tag "$rollback_tag" blog-web >/dev/null 2>&1 || failed=1
  compose up -d --no-build --force-recreate web >/dev/null 2>&1 || failed=1
  restore_wrapper "$PRODUCTION_ROOT/up.sh" up.sh || failed=1
  restore_wrapper "$PRODUCTION_ROOT/release.sh" release.sh || failed=1
  wait_for_health || failed=1
  rollback_failed="$failed"
  if ((failed)); then
    printf 'Blog rollback failed; preserved %s and %s\n' \
      "$rollback_dir" "$rollback_tag" >&2
    return 1
  fi
  printf '%s\n' 'Blog deployment rolled back and restored health.' >&2
  return 0
}

export RAILS_MASTER_KEY
RAILS_MASTER_KEY="$(<"$MASTER_KEY")"
transaction_started=1

if ! git -C "$PRODUCTION_APP" merge --ff-only "origin/$BRANCH"; then
  rollback
  exit 1
fi
if ! compose build web; then
  rollback
  exit 1
fi
if ! compose up -d --no-build web; then
  rollback
  exit 1
fi

if ! wait_for_health; then
  printf 'blog health check failed: %s\n' "$HEALTH_URL" >&2
  rollback
  exit 1
fi

# Keep the old /home/carter/blog entry points working while making the
# canonical deploy and startup wrappers live in this repository.
if ! install_wrapper "$PRODUCTION_ROOT/up.sh" "$SCRIPT_DIR/up.sh"; then
  rollback
  exit 1
fi
if ! install_wrapper "$PRODUCTION_ROOT/release.sh" "$SCRIPT_DIR/release.sh"; then
  rollback
  exit 1
fi

committed=1
printf 'Blog deployed at %s\n' "$(git -C "$PRODUCTION_APP" rev-parse --short HEAD)"
