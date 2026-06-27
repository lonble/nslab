# Automated Encrypted Backup (Restic)

Automatic encrypted backup for the web server using **restic** and **rest-server** in **append-only** mode.

## Architecture

```
Web Server (192.168.0.3)          Backup Server (192.168.0.4)
┌──────────────────────┐          ┌───────────────────────┐
│  restic client       │──REST──▶ │  rest-server          │
│  + cron (5 min)      │  :8000   │  --append-only        │
│  + RESTIC_PASSWORD   │          │  /srv/backup (encrypted)│
│  Backup: /srv/http   │          │  Cannot decrypt     │
└──────────────────────┘          └───────────────────────┘
```

**Security properties:**

- **Encrypted**: restic encrypts all data (AES-256) before sending; Backup Server stores only ciphertext
- **Append-only**: rest-server rejects delete/modify requests; ransomware on Web Server cannot destroy backups
- **Separation of concerns**: encryption key exists only on Web Server



## Lab Day Deployment

### On Backup Server machine (192.168.0.4)

```bash
# Copy backup/ directory to USB drive, then on the lab machine:
chmod +x lab/setup-backup-server.sh
./lab/setup-backup-server.sh <lan-interface>
```

### On Web Server machine (192.168.0.3)

```bash
# After Caddy is already running:
chmod +x lab/setup-web-client.sh
./lab/setup-web-client.sh
```

## File Overview

| File | Used On | Purpose |
|------|---------|---------|
| `rest-server.service` | Backup Server | systemd service for rest-server |
| `lab/setup-backup-server.sh` | Backup Server | One-shot lab setup |
| `lab/setup-web-client.sh` | Web Server | One-shot lab setup |
