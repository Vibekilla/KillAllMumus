#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/deploy/nginx/killallmumus.com"
sudo cp "$SRC" /etc/nginx/sites-available/killallmumus.com
sudo ln -sfn /etc/nginx/sites-available/killallmumus.com /etc/nginx/sites-enabled/killallmumus.com
sudo rm -f /etc/nginx/sites-enabled/default
sudo mkdir -p /var/www/certbot
sudo nginx -t
sudo systemctl reload nginx
echo "✓ nginx now proxies killallmumus.com → 127.0.0.1:3000"
curl -sS -H "Host: killallmumus.com" http://127.0.0.1/api/health || true
echo
