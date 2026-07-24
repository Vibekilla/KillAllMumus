#!/usr/bin/env bash
# Install nginx site for dev.killallmumus.com → 127.0.0.1:3001
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/deploy/nginx/dev.killallmumus.com"
sudo cp "$SRC" /etc/nginx/sites-available/dev.killallmumus.com
sudo ln -sfn /etc/nginx/sites-available/dev.killallmumus.com /etc/nginx/sites-enabled/dev.killallmumus.com
sudo nginx -t
sudo systemctl reload nginx
echo "✓ nginx now proxies dev.killallmumus.com → 127.0.0.1:3001"
echo "  DNS: add A record dev.killallmumus.com → $(curl -fsS -4 ifconfig.me 2>/dev/null || echo 'this host IP')"
echo "  Then: sudo certbot --nginx -d dev.killallmumus.com"
curl -sS -H "Host: dev.killallmumus.com" http://127.0.0.1/api/health || true
echo
