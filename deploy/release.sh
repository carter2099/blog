#!/usr/bin/env bash
# Canonical entrypoint retained for the historical release.sh name.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly SCRIPT_DIR
exec "$SCRIPT_DIR/deploy.sh" "$@"
