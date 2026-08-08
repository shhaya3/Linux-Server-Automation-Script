#!/usr/bin/env bash
set -euo pipefail

echo "==> [06] Installing basic monitoring tools"

apt-get update -y
apt-get install -y htop ncdu logwatch

# Configure logwatch to email a daily summary (requires mail setup to
# actually deliver -- safe to leave as-is for local testing, it will
# just log locally if no MTA is configured)
if [ -f /etc/cron.daily/00logwatch ]; then
    echo "    logwatch daily cron already present"
else
    cat > /etc/cron.daily/00logwatch <<'EOF'
#!/bin/bash
/usr/sbin/logwatch --output stdout --format text --range yesterday > /var/log/logwatch-daily.log
EOF
    chmod +x /etc/cron.daily/00logwatch
    echo "    Installed daily logwatch cron job"
fi

echo "    [06] Basic monitoring tools installed."
