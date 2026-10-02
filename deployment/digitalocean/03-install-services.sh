#!/bin/bash
# Clone and start all allyabase microservices via PM2.
# Federated Wiki runs as a systemd service (separate from PM2) so the
# wiki-plugin-allyabase cleanup cycle can't accidentally kill it.
#
# Services land in /var/lib/allyabase/ by default.
# Wiki state lives in ~/.wiki/ (standard Fedwiki convention).

set -e

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

SERVICES_DIR="${1:-/var/lib/allyabase}"
WIKI_BIN="$(which wiki)"
NODE_BIN="$(which node)"

echo "Installing allyabase microservices to $SERVICES_DIR..."
# --dir, not a positional: SERVICES_DIR already ends in 'allyabase', and the
# positional form appends '/allyabase' again — this was installing everything
# into /var/lib/allyabase/allyabase.
#
# Pass ALLYABASE_SERVICES=a,b,c to install a subset; bdo, continuebee, and
# fount always come along. `allyabase-setup --list` shows what's available.
allyabase-setup --dir="$SERVICES_DIR" ${ALLYABASE_SERVICES:+--services="$ALLYABASE_SERVICES"}

# ── Federated Wiki as a systemd service ───────────────────────────────────────
# wiki-plugin-allyabase calls "pm2 stop all" on startup to reset services.
# Running wiki under systemd keeps it out of PM2's reach entirely.

WIKI_SERVICE="/etc/systemd/system/wiki.service"

echo "Creating wiki systemd service..."
cat > "$WIKI_SERVICE" <<EOF
[Unit]
Description=Federated Wiki
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/root
ExecStart=$NODE_BIN $WIKI_BIN --port 3333 --security_type=sessionless --id /root/.wiki/status/owner.json --security=sessionless
Restart=always
RestartSec=5
Environment=NODE_ENV=production
Environment=HOME=/root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable wiki
systemctl restart wiki

echo "Wiki systemd service started on port 3000."
echo "  Status: systemctl status wiki"
echo "  Logs:   journalctl -u wiki -f"
echo ""
echo "Allyabase services running under PM2."
echo "  Status: pm2 status"
