#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config/vars.conf"

echo "==> [03] Configuring UFW firewall"

# Install ufw if missing
if ! command -v ufw &>/dev/null; then
    apt-get update -y
    apt-get install -y ufw
fi

# Set safe defaults
ufw default deny incoming
ufw default allow outgoing

# Allow the (possibly custom) SSH port -- do this BEFORE enabling,
# otherwise you can lock yourself out the moment ufw turns on.
ufw allow "${SSH_PORT}/tcp" comment "SSH"

# Allow any extra ports from config (e.g. 80, 443)
for port in $EXTRA_ALLOWED_PORTS; do
    ufw allow "${port}/tcp" comment "app port $port"
    echo "    Allowed port $port"
done

# Enable non-interactively
ufw --force enable

echo "    UFW status:"
ufw status verbose

echo "    [03] Firewall configuration complete."
