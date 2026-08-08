# Linux Server Hardening & Security Automation

A modular Bash toolkit that transforms a fresh Ubuntu VPS into a hardened, production-ready server in under 10 minutes — replacing what is normally ~2 hours of manual, error-prone configuration.

## The Problem

Every new cloud server (DigitalOcean, AWS, etc.) starts wide open: root login enabled, password authentication on, no firewall, no intrusion prevention, and no automatic patching. Manually locking this down means repeating the same ~20 commands across SSH config, UFW, Fail2Ban, and cron every single time a new box is spun up — and it's easy to fat-finger a step (like enabling the firewall before allowing the SSH port) and lock yourself out entirely.

This project automates that entire process into a single, safe, repeatable script.

## What It Does

- **Non-root sudo user** — creates a least-privilege user and provisions it with the same SSH key as the admin account, instead of operating as root
- **SSH hardening** — moves SSH off the default port, disables root login, disables password authentication (key-only), and caps auth retries
- **UFW firewall** — default-deny on incoming traffic, with only the necessary ports explicitly opened, applied in an order that can't lock out the current session
- **Fail2Ban** — bans IPs that repeatedly fail SSH login, configurable ban time / retry threshold / lookback window
- **Automatic security updates** — `unattended-upgrades` configured to apply patches without manual intervention
- **Basic monitoring** — `htop`, `ncdu`, and a daily `logwatch` summary of auth activity, errors, and system changes


## Design Decisions & Safety Features

- **Config validation before restart** — `sshd -t` is run before every `sshd` restart; if the config is invalid, the script restores the backup and aborts rather than restarting into a broken state.
- **Ordering matters, and the script enforces it** — the SSH port is allowed through UFW *before* UFW is enabled, and a working SSH key is verified *before* password authentication is disabled. Both are the most common ways people accidentally lock themselves out, and both are structurally prevented here rather than left as a "remember to..." note.
- **Idempotency** — modules check current state before acting (e.g. skip user creation if the user already exists), so the script can be safely re-run without duplicating work or erroring out.
- **Config backups** — `sshd_config` is backed up with a timestamp before any modification.
- **Fail-fast execution** — every script runs under `set -euo pipefail`, so a failed step stops the run instead of silently continuing into an inconsistent state.
- **Explicit manual verification step** — after hardening, the script prints a reminder to verify the new SSH configuration in a *second*, separate terminal session before closing the original one — since a mistake here is the difference between "minor bug" and "permanently locked out of the server."

## Usage

```bash
git clone https://github.com/<your-username>/server-hardening.git
cd server-hardening

cp config/vars.conf.example config/vars.conf
nano config/vars.conf   # set your username, SSH port, etc.

chmod +x harden.sh modules/*.sh
sudo ./harden.sh
```

**Before closing your session**, open a new terminal and confirm the new configuration works:

```bash
ssh -p <your-configured-port> <your-configured-user>@<server-ip>
```

Only close the original session after this succeeds.

## Verification

After running, confirm each layer is active:

```bash
sudo ufw status verbose                # firewall rules
sudo fail2ban-client status sshd       # intrusion prevention
sudo systemctl status unattended-upgrades
grep -E "^Port|^PermitRootLogin|^PasswordAuthentication" /etc/ssh/sshd_config
```

## Tech Used

Bash · systemd · OpenSSH · UFW (iptables) · Fail2Ban · unattended-upgrades · cron

## Tested On

Ubuntu Server 24.04 / 26.04 LTS (validated locally via VirtualBox before deployment to a live VPS)

