#!/bin/bash
# ============================================================
#  Lab Day — Web Server Backup Client (run on 192.168.0.3)
#  Prerequisites: Caddy must already be running with /srv/http
# ============================================================
set -e

BACKUP_PASSWORD="${1:-lab-backup-2026}"
BACKUP_SERVER="192.168.0.4"

echo "=== Web Server Backup Client Setup ==="

# Step 1: Install restic
if command -v restic &>/dev/null; then
    echo "[1/4] restic already installed, skipping."
else
    echo "[1/4] Installing restic..."
    apt update -qq || { echo "FAIL: apt update failed."; exit 1; }
    apt install -y restic || { echo "FAIL: Could not install restic."; exit 1; }
    echo "       Done."
fi

# Step 2: Configure environment
echo "[2/4] Configuring restic environment..."
# NOTE: Plaintext password in config files is acceptable for a lab environment.
#       In production, use a secrets manager or restricted file permissions.
cat > /etc/profile.d/restic.sh << EOF
export RESTIC_PASSWORD="${BACKUP_PASSWORD}"
export RESTIC_REPOSITORY="rest:http://${BACKUP_SERVER}:8000/"
EOF
source /etc/profile.d/restic.sh
# restic uses $HOME/.cache as the cache directory
chown -R backup:backup /var/backups

# Step 3: Initialize repository
echo "[3/4] Initializing restic repository..."
if restic snapshots &>/dev/null; then
    echo "       Repository already initialized, skipping."
else
    echo "       Initializing new repository..."
    restic init || { echo "FAIL: Could not initialize repository."; exit 1; }
    echo "       Done."
fi

# Step 4: First backup + systemd timer
echo "[4/4] Running first backup and setting up systemd timer..."
restic backup /srv/http || { echo "FAIL: Initial backup failed."; exit 1; }

# Create systemd service for one-shot backup
# NOTE: 5-minute interval is chosen for lab demo purposes.
#       In production, evaluate based on data size and network bandwidth.
cat > /etc/systemd/system/restic-backup.service << EOF
[Unit]
Description=Restic Backup

[Service]
Type=oneshot
User=backup
Group=backup
Environment="RESTIC_PASSWORD=${BACKUP_PASSWORD}"
Environment="RESTIC_REPOSITORY=rest:http://${BACKUP_SERVER}:8000/"
ExecStart=/usr/bin/restic backup /srv/http --quiet
EOF

# Create systemd timer (every 5 minutes)
cat > /etc/systemd/system/restic-backup.timer << 'EOF'
[Unit]
Description=Restic Backup Timer (every 5 minutes)

[Timer]
OnBootSec=1min
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now restic-backup.timer || { echo "FAIL: Could not start backup timer."; exit 1; }

echo ""
echo "=== Backup Client is READY ==="
echo "    Repository : rest:http://${BACKUP_SERVER}:8000/"
echo "    Source     : /srv/http"
echo "    Interval   : every 5 minutes (systemd timer)"
echo ""
echo "    Verify: restic snapshots"
echo "    Check timer: systemctl list-timers restic-backup.timer"
echo "    Test append-only: restic forget --prune  (should FAIL)"
