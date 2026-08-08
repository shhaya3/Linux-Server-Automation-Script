#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config/vars.conf"

echo "==> [04] Installing and configuring Fail2Ban"

apt-get update -y
apt-get install -y fail2ban

JAIL_LOCAL="/etc/fail2ban/jail.local"

cat > "$JAIL_LOCAL" <<EOF
[DEFAULT]
bantime  = ${F2B_BANTIME}
findtime = ${F2B_FINDTIME}
maxretry = ${F2B_MAXRETRY}

[sshd]
enabled  = true
port     = ${SSH_PORT}
filter   = sshd
logpath  = /var/log/auth.log
maxretry = ${F2B_MAXRETRY}
EOF

echo "    Wrote $JAIL_LOCAL"

systemctl enable fail2ban
systemctl restart fail2ban

sleep 2
echo "    Fail2Ban status:"
fail2ban-client status || true
fail2ban-client status sshd || true

echo "    [04] Fail2Ban setup complete."
