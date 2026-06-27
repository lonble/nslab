#!/bin/bash
# ============================================================
#  Lab Day — Web Server Backup Client (run on 192.168.0.3)
#  Prerequisites: Caddy must already be running
# ============================================================
set -e

BACKUP_PASSWORD="${1:-lab-backup-2026}"

echo "=== Web Server Backup Client Setup ==="

# Step 1: Install restic
echo "[1/4] Installing restic..."
apt update -qq
apt install -y restic
echo "       restic installed."

# Step 2: Configure environment
echo "[2/4] Configuring restic environment..."
cat > /etc/profile.d/restic.sh << EOF
export RESTIC_PASSWORD="${BACKUP_PASSWORD}"
export RESTIC_REPOSITORY="rest:http://192.168.0.4:8000/"
EOF
source /etc/profile.d/restic.sh

# Step 3: Initialize repository
echo "[3/4] Initializing restic repository..."
export RESTIC_PASSWORD="${BACKUP_PASSWORD}"
export RESTIC_REPOSITORY="rest:http://192.168.0.4:8000/"
restic init
echo "       Repository initialized."

# Step 4: First backup + cron
echo "[4/4] Running first backup and setting up cron..."
restic backup /srv/http

# Setup cron (every 5 minutes, simple inline command)
cat > /etc/cron.d/restic-backup << EOF
*/5 * * * * root RESTIC_PASSWORD="${BACKUP_PASSWORD}" RESTIC_REPOSITORY="rest:http://192.168.0.4:8000/" /usr/bin/restic backup /srv/http --quiet
EOF
chmod 644 /etc/cron.d/restic-backup

echo ""
echo "=== Backup Client is READY ==="
echo "    Repository : rest:http://192.168.0.4:8000/"
echo "    Source     : /srv/http"
echo "    Interval   : every 5 minutes"
echo ""
echo "    Verify: restic snapshots"
echo "    Test append-only: restic forget --prune  (should FAIL)"
