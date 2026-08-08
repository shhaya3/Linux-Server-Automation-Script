#!/usr/bin/env bash
set -euo pipefail

# Load config (this script may be run standalone or via harden.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/config/vars.conf"

echo "==> [01] Setting up non-root sudo user: $NEW_USER"

# Idempotent: only create if not already present
if id -u "$NEW_USER" &>/dev/null; then
    echo "    User $NEW_USER already exists, skipping creation."
else
    useradd -m -s /bin/bash "$NEW_USER"
    echo "    Created user $NEW_USER"
fi

# Ensure user is in sudo group
usermod -aG sudo "$NEW_USER"
echo "    Added $NEW_USER to sudo group"

# Set up .ssh directory
USER_SSH_DIR="/home/$NEW_USER/.ssh"
mkdir -p "$USER_SSH_DIR"

# Copy authorized_keys from current admin (root or whoever ran this)
CURRENT_ADMIN_HOME="$(eval echo ~${SUDO_USER:-root})"
SOURCE_KEYS="$CURRENT_ADMIN_HOME/.ssh/authorized_keys"

if [ -f "$SOURCE_KEYS" ]; then
    cp "$SOURCE_KEYS" "$USER_SSH_DIR/authorized_keys"
    echo "    Copied authorized_keys from $SOURCE_KEYS"
else
    echo "    WARNING: No authorized_keys found at $SOURCE_KEYS"
    echo "    You must manually add a public key to $USER_SSH_DIR/authorized_keys"
    echo "    before SSH hardening disables password auth, or you will be locked out."
fi

chown -R "$NEW_USER:$NEW_USER" "$USER_SSH_DIR"
chmod 700 "$USER_SSH_DIR"
[ -f "$USER_SSH_DIR/authorized_keys" ] && chmod 600 "$USER_SSH_DIR/authorized_keys"

echo "    [01] User setup complete."
