#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/var/log/harden-$(date +%F-%H%M%S).log"

# Must be root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use: sudo ./harden.sh)"
    exit 1
fi

echo "=========================================="
echo " Server Hardening Automation"
echo " Log file: $LOG_FILE"
echo "=========================================="

# Run each module in order, log everything, but still show it live
{
    bash "$SCRIPT_DIR/modules/01-user-setup.sh"
    bash "$SCRIPT_DIR/modules/02-ssh-hardening.sh"
    bash "$SCRIPT_DIR/modules/03-firewall.sh"
    bash "$SCRIPT_DIR/modules/04-fail2ban.sh"
    bash "$SCRIPT_DIR/modules/05-auto-updates.sh"
    bash "$SCRIPT_DIR/modules/06-monitoring.sh"
} 2>&1 | tee "$LOG_FILE"

source "$SCRIPT_DIR/config/vars.conf"

echo "=========================================="
echo " Hardening complete."
echo " New SSH user: $NEW_USER"
echo " New SSH port: $SSH_PORT"
echo ""
echo " !!! DO NOT close this session yet !!!"
echo " Open a NEW terminal and confirm you can log in:"
echo "     ssh -p $SSH_PORT $NEW_USER@<server-ip>"
echo " Only close this session after that succeeds."
echo "=========================================="
