#!/usr/bin/env bash
# Deprecated: PR ship-feature flow removed (it dropped work via force-refresh).
#
# New workflow:
#   commit + push on dev
#   ./scripts/promote-to-live.sh   # merge dev → main
set -euo pipefail

cat <<'EOF'
ship-feature.sh is retired.

Use:
  cd /var/www/dev
  git add -A && git commit -m "feat: …"
  git push origin dev
  # when ready for production:
  ./scripts/promote-to-live.sh

If you are already on a feature/* branch with commits:
  git checkout dev
  git merge feature/your-branch
  git push origin dev
  ./scripts/promote-to-live.sh
EOF
exit 1
