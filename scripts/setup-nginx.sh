#!/usr/bin/env bash
# Configure Nginx reverse proxy + optional Let's Encrypt TLS on Ubuntu.
#
# Usage:
#   sudo bash scripts/setup-nginx.sh \
#     --api-domain api.example.com \
#     --frontend-domain example.com \
#     --email admin@example.com
set -euo pipefail

API_DOMAIN=""
FRONTEND_DOMAIN=""
EMAIL=""
INSTALL_CERT=true
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

while [ $# -gt 0 ]; do
  case "$1" in
    --api-domain) API_DOMAIN="$2"; shift 2 ;;
    --frontend-domain) FRONTEND_DOMAIN="$2"; shift 2 ;;
    --email) EMAIL="$2"; shift 2 ;;
    --no-cert) INSTALL_CERT=false; shift ;;
    -h|--help)
      echo "Usage: sudo $0 --api-domain api.example.com --frontend-domain example.com --email you@example.com"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo $0 ..."
  exit 1
fi

if [ -z "$API_DOMAIN" ] || [ -z "$FRONTEND_DOMAIN" ]; then
  echo "--api-domain and --frontend-domain are required."
  exit 1
fi

apt-get update
apt-get install -y nginx certbot python3-certbot-nginx

mkdir -p /var/www/era-frontend

sed "s/api.your-domain.com/${API_DOMAIN}/g" "$REPO_ROOT/deploy/nginx/era-api.conf" \
  > /etc/nginx/sites-available/era-api.conf

sed -e "s/your-domain.com/${FRONTEND_DOMAIN}/g" \
    -e "s/www.your-domain.com/www.${FRONTEND_DOMAIN}/g" \
  "$REPO_ROOT/deploy/nginx/era-frontend.conf" \
  > /etc/nginx/sites-available/era-frontend.conf

ln -sf /etc/nginx/sites-available/era-api.conf /etc/nginx/sites-enabled/era-api.conf
ln -sf /etc/nginx/sites-available/era-frontend.conf /etc/nginx/sites-enabled/era-frontend.conf
rm -f /etc/nginx/sites-enabled/default

nginx -t
systemctl enable nginx
systemctl reload nginx

echo "[ERA] Nginx HTTP configs installed."

if [ "$INSTALL_CERT" = true ]; then
  if [ -z "$EMAIL" ]; then
    echo "[ERA] Skipping certbot (--email not set). Run manually:"
    echo "  certbot --nginx -d ${API_DOMAIN} -d ${FRONTEND_DOMAIN} -d www.${FRONTEND_DOMAIN}"
    exit 0
  fi

  certbot --nginx \
    --non-interactive \
    --agree-tos \
    -m "$EMAIL" \
    -d "$API_DOMAIN" \
    -d "$FRONTEND_DOMAIN" \
    -d "www.${FRONTEND_DOMAIN}"

  systemctl reload nginx
  echo "[ERA] TLS certificates installed."
fi

echo "[ERA] Nginx ready:"
echo "  API:      https://${API_DOMAIN}"
echo "  Frontend: https://${FRONTEND_DOMAIN}"
