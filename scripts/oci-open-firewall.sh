#!/usr/bin/env bash
# Open HTTP/HTTPS on Oracle Cloud Ubuntu images.
# OCI injects iptables rules that block inbound 80/443 even when Security Lists allow them.
#
# Run on the instance:
#   sudo bash scripts/oci-open-firewall.sh
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "Run as root: sudo bash $0"
  exit 1
fi

open_port() {
  local port="$1"
  if iptables -C INPUT -m state --state NEW -p tcp --dport "$port" -j ACCEPT 2>/dev/null; then
    echo "[OCI] Port $port already open in iptables."
    return
  fi
  iptables -I INPUT 6 -m state --state NEW -p tcp --dport "$port" -j ACCEPT
  echo "[OCI] Opened TCP $port in iptables."
}

open_port 80
open_port 443

DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent netfilter-persistent
netfilter-persistent save

echo "[OCI] Firewall rules saved. Verify with: sudo iptables -L INPUT -n --line-numbers"
