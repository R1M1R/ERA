#!/usr/bin/env bash
# Bootstrap ERA on a fresh Oracle Cloud Always Free Ubuntu instance.
#
# Prerequisites (OCI Console):
#   - VM.Standard.A1.Flex (recommended: 2 OCPU, 8–12 GB RAM)
#   - Ubuntu 22.04 aarch64
#   - Public IPv4
#   - Security List: TCP 22, 80, 443 from 0.0.0.0/0
#   - ~/.env on server OR run generate-prod-env locally and scp first
#
# Usage:
#   bash scripts/oracle-cloud-bootstrap.sh
#   bash scripts/oracle-cloud-bootstrap.sh --with-nginx \
#     --api-domain api.example.com --frontend-domain example.com --email you@example.com
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WITH_NGINX=false
IP_ONLY_NGINX=false
API_DOMAIN=""
FRONTEND_DOMAIN=""
EMAIL=""
SWAP_GB=2

while [ $# -gt 0 ]; do
  case "$1" in
    --with-nginx) WITH_NGINX=true; shift ;;
    --ip-only-nginx) IP_ONLY_NGINX=true; shift ;;
    --api-domain) API_DOMAIN="$2"; shift 2 ;;
    --frontend-domain) FRONTEND_DOMAIN="$2"; shift 2 ;;
    --email) EMAIL="$2"; shift 2 ;;
    --swap-gb) SWAP_GB="$2"; shift 2 ;;
    -h|--help)
      echo "Usage: bash $0 [--ip-only-nginx | --with-nginx --api-domain ... --frontend-domain ...] [--swap-gb 2]"
      exit 0
      ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo "[ERA/OCI] Architecture: $(uname -m)"
if [ "$(uname -m)" != "aarch64" ] && [ "$(uname -m)" != "arm64" ]; then
  echo "[ERA/OCI] Warning: not ARM64. AMD E2.1.Micro (1 GB) is too small for the full ERA stack."
  echo "[ERA/OCI] Use VM.Standard.A1.Flex on Oracle Always Free."
fi

echo "[ERA/OCI] Opening instance firewall (iptables)..."
sudo bash "$ROOT/scripts/oci-open-firewall.sh"

if ! swapon --show | grep -q '/swapfile'; then
  echo "[ERA/OCI] Adding ${SWAP_GB}G swap (recommended on free tier)..."
  sudo fallocate -l "${SWAP_GB}G" /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=$((SWAP_GB * 1024))
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
  sudo swapon /swapfile
  if ! grep -q '/swapfile' /etc/fstab; then
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
  fi
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERA/OCI] Installing Docker..."
  curl -fsSL https://get.docker.com | sudo sh
  sudo usermod -aG docker "$USER"
  echo "[ERA/OCI] Docker installed. Log out and back in, then re-run:"
  echo "  bash scripts/oracle-cloud-bootstrap.sh $*"
  exit 0
fi

if ! groups | grep -q docker; then
  echo "[ERA/OCI] Add user to docker group, then re-login:"
  echo "  sudo usermod -aG docker $USER"
  exit 1
fi

bash "$ROOT/scripts/server-first-deploy.sh" --oci

if [ "$IP_ONLY_NGINX" = true ]; then
  sudo bash "$ROOT/scripts/setup-nginx-ip.sh"
elif [ "$WITH_NGINX" = true ]; then
  if [ -z "$API_DOMAIN" ] || [ -z "$FRONTEND_DOMAIN" ]; then
    echo "[ERA/OCI] --api-domain and --frontend-domain required with --with-nginx"
    exit 1
  fi
  sudo bash "$ROOT/scripts/setup-nginx.sh" \
    --api-domain "$API_DOMAIN" \
    --frontend-domain "$FRONTEND_DOMAIN" \
    ${EMAIL:+--email "$EMAIL"}
fi

PUBLIC_IP="$(curl -fsS ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
echo ""
echo "[ERA/OCI] Bootstrap complete."
echo "  Public IP:  ${PUBLIC_IP}"
echo "  Health:     curl http://127.0.0.1:8000/health"
if [ "$IP_ONLY_NGINX" = true ]; then
  echo "  Site:       http://${PUBLIC_IP}/"
  echo "  API:        http://${PUBLIC_IP}/health"
  echo "  Frontend:   .\\scripts\\upload-frontend-to-oci.ps1 -ServerIp ${PUBLIC_IP} -ApiUrl http://${PUBLIC_IP}"
elif [ "$WITH_NGINX" = true ]; then
  echo "  API:        https://${API_DOMAIN}"
  echo "  Frontend:   https://${FRONTEND_DOMAIN}"
else
  echo "  Next: sudo bash scripts/setup-nginx-ip.sh  (IP-only)"
  echo "    or: sudo bash scripts/setup-nginx.sh --api-domain api.YOUR_DOMAIN ..."
fi
