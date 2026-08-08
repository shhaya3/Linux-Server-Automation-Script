#!/usr/bin/env bash
set -euo pipefail

echo "==> [05] Configuring automatic security updates"

apt-get update -y
apt-get install -y unattended-upgrades apt-listchanges

# Enable unattended-upgrades non-interactively
cat > /etc/apt/apt.conf.d/20auto-upgrades <<EOF
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

systemctl enable unattended-upgrades
systemctl restart unattended-upgrades

echo "    [05] Automatic security updates enabled."
