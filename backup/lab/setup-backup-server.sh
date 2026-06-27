#!/bin/bash
# ============================================================
#  Lab Day — Backup Server Setup (run on 192.168.0.4 machine)
# ============================================================
set -e

echo "=== Backup Server Setup ==="

# Step 1: Static IP
echo "[1/5] Configuring static IP (192.168.0.4)..."
cat >> /etc/dhcpcd.conf << 'EOF'
inform 192.168.0.4/24
EOF

LAN_IF="${1:?Usage: $0 <lan-interface>}"
dhcpcd -k "$LAN_IF" 2>/dev/null || true
dhcpcd "$LAN_IF"
echo "       IP configured."

# Step 2: Install restic (optional, for local management)
echo "[2/5] Updating packages..."
apt update -qq

# Step 3: Download rest-server
echo "[3/5] Installing rest-server..."
ARCH=$(dpkg --print-architecture)
# Try to download latest rest-server
REST_URL="https://github.com/restic/rest-server/releases/download/v0.13.0/rest-server_0.13.0_linux_${ARCH}.tar.gz"
if command -v wget &> /dev/null; then
    wget -q "$REST_URL" -O /tmp/rest-server.tar.gz
else
    curl -sL "$REST_URL" -o /tmp/rest-server.tar.gz
fi
tar xzf /tmp/rest-server.tar.gz -C /tmp/
find /tmp -name 'rest-server' -type f -exec mv {} /usr/local/bin/rest-server \;
chmod +x /usr/local/bin/rest-server
echo "       rest-server installed."

# Step 4: Create backup directory
echo "[4/5] Creating backup storage directory..."
mkdir -p /srv/backup

# Step 5: Install and start systemd service
echo "[5/5] Starting rest-server (append-only mode)..."
cat > /etc/systemd/system/rest-server.service << 'EOF'
[Unit]
Description=Restic REST Server (Append-Only)
After=network.target

[Service]
ExecStart=/usr/local/bin/rest-server --path /srv/backup --append-only --no-auth --listen :8000
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now rest-server.service

echo ""
echo "=== Backup Server is READY ==="
echo "    Listening on :8000 (append-only, no-auth)"
echo "    Storage: /srv/backup"
echo ""
echo "    Verify: curl http://192.168.0.4:8000/"
