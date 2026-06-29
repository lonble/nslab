#!/bin/bash
# ============================================================
#  Lab Day — Backup Server Setup (run on 192.168.0.4 machine)
#  Usage: ./setup-backup-server.sh <lan-interface>
# ============================================================
set -e

LAN_IF="${1:?Usage: $0 <lan-interface>}"

echo "=== Backup Server Setup ==="

# Step 1: Static IP
if ip addr show "$LAN_IF" | grep -q "192.168.0.4"; then
    echo "[1/4] Static IP already configured, skipping."
else
    echo "[1/4] Configuring static IP (192.168.0.4)..."
    echo "inform 192.168.0.4/24" >> /etc/dhcpcd.conf
    dhcpcd -k "$LAN_IF" 2>/dev/null
    dhcpcd "$LAN_IF" 2>/dev/null || { echo "FAIL: Could not configure network."; exit 1; }
    echo "       Done."
fi

# Step 2: Install rest-server
if command -v rest-server &>/dev/null; then
    echo "[2/4] rest-server already installed, skipping."
else
    echo "[2/4] Installing rest-server..."
    ARCH=$(dpkg --print-architecture)
    REST_URL="https://github.com/restic/rest-server/releases/download/v0.13.0/rest-server_0.13.0_linux_${ARCH}.tar.gz"
    wget -q "$REST_URL" -O /tmp/rest-server.tar.gz || { echo "FAIL: Could not download rest-server."; exit 1; }
    tar xzf /tmp/rest-server.tar.gz -C /tmp/
    find /tmp -name 'rest-server' -type f -exec mv {} /usr/local/bin/rest-server \;
    chmod +x /usr/local/bin/rest-server
    echo "       Done."
fi

# Step 3: Create backup directory
echo "[3/4] Setting up backup storage"
mkdir -p /srv/backup
chown -R backup:backup /srv/backup

# Step 4: Install and start systemd service
echo "[4/4] Starting rest-server (append-only mode)..."
cat > /etc/systemd/system/rest-server.service << 'EOF'
[Unit]
Description=Restic REST Server (Append-Only)
After=network.target

[Service]
User=backup
Group=backup
ExecStart=/usr/local/bin/rest-server --path /srv/backup --append-only --no-auth --listen :8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now rest-server.service || { echo "FAIL: Could not start rest-server."; exit 1; }

echo ""
echo "=== Backup Server is READY ==="
echo "    Listening on :8000 (append-only, no-auth)"
echo "    Storage: /srv/backup"
echo ""
echo "    Verify: curl http://192.168.0.4:8000/"
