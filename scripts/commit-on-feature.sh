#!/usr/bin/env bash
# Deprecated: commits are allowed on dev/main directly.
# Forwards to git commit (or use ./scripts/push-dev.sh -m "…").
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
echo "note: commit-on-feature is deprecated — committing on $(git rev-parse --abbrev-ref HEAD)" >&2
exec git commit "$@"
