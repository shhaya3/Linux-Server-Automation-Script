#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config/vars.conf"

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="/etc/ssh/sshd_config.bak.$(date +%s)"

echo "==> [02] Hardening SSH configuration"

# Safety check: make sure the new user actually has a key before we
# disable password auth, otherwise this would lock everyone out.
USER_KEYS="/home/$NEW_USER/.ssh/authorized_keys"
if [ ! -s "$USER_KEYS" ]; then
    echo "    ERROR: $USER_KEYS is missing or empty."
    echo "    Refusing to disable password authentication without a working key."
    echo "    Fix this (add a public key for $NEW_USER) and re-run."
    exit 1
fi

# Backup original config before touching anything
cp "$SSHD_CONFIG" "$BACKUP"
echo "    Backed up original config to $BACKUP"

# Helper: set a directive, uncommenting or replacing as needed
set_directive() {
    local key="$1"
    local value="$2"
    if grep -qE "^\s*#?\s*${key}\b" "$SSHD_CONFIG"; then
        sed -i -E "s|^\s*#?\s*${key}\b.*|${key} ${value}|" "$SSHD_CONFIG"
    else
        echo "${key} ${value}" >> "$SSHD_CONFIG"
    fi
}

set_directive "Port" "$SSH_PORT"
set_directive "PermitRootLogin" "no"
set_directive "PasswordAuthentication" "no"
set_directive "PubkeyAuthentication" "yes"
set_directive "ChallengeResponseAuthentication" "no"
set_directive "X11Forwarding" "no"
set_directive "MaxAuthTries" "3"
set_directive "ClientAliveInterval" "300"
set_directive "ClientAliveCountMax" "2"

echo "    Applied directives: Port=$SSH_PORT, PermitRootLogin=no, PasswordAuthentication=no"

# CRITICAL: validate config syntax before restarting the service.
# If this fails, we do NOT want to restart sshd with a broken config.
if ! sshd -t 2>/tmp/sshd_test_err; then
    echo "    ERROR: sshd config test failed. Restoring backup and aborting."
    cat /tmp/sshd_test_err
    cp "$BACKUP" "$SSHD_CONFIG"
    exit 1
fi

echo "    Config syntax OK. Restarting sshd..."
systemctl restart ssh || systemctl restart sshd

echo "    [02] SSH hardening complete."
echo "    !!! IMPORTANT: Before closing this session, open a NEW terminal and verify:"
echo "        ssh -p $SSH_PORT $NEW_USER@<server-ip>"
