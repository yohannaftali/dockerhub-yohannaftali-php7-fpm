#!/usr/bin/env bash
# Wrapper: ./scripts/dockerhub-update.sh [sync|status|tags|delete-tag <tag>]
set -euo pipefail
exec uv run "$(dirname "$0")/dockerhub_update.py" "$@"
