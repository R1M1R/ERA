#!/usr/bin/env bash
# Nginx for IP-only HTTP access (no domain, no TLS).
# Serves frontend on / and proxies API paths to FastAPI.
#
# Usage:
#   sudo bash scripts/setup-nginx-ip.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

apt-get update
apt-get install -y nginx

mkdir -p /var/www/era-frontend

cp "$REPO_ROOT/deploy/nginx/era-ip-only.conf" /etc/nginx/sites-available/era-ip-only.conf
ln -sf /etc/nginx/sites-available/era-ip-only.conf /etc/nginx/sites-enabled/era-ip-only.conf
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable nginx
systemctl reload nginx

PUBLIC_IP="$(curl -fsS ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo "[ERA] IP-only Nginx ready:"
echo "  Frontend: http://${PUBLIC_IP}/"
echo "  API:      http://${PUBLIC_IP}/health"
echo "  Build frontend with: VITE_API_URL=http://${PUBLIC_IP}"
