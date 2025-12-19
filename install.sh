#!/usr/bin/env bash
set -e

# -----------------------------
# Constants
# -----------------------------
APP_NAME="filebrowser"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/filebrowser"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
SERVICE_FILE="/etc/systemd/system/filebrowser.service"
PORT=$1
RELEASE_BASE="https://github.com/gtsteffaniak/filebrowser/releases/latest/download"

# -----------------------------
# 0) Ensure working directory exists and writable
# -----------------------------
sudo mkdir -p /etc/filebrowser
sudo chown root:root /etc/filebrowser
sudo chmod 700 /etc/filebrowser

# -----------------------------
# 1) Download binary
# -----------------------------
echo "Downloading FileBrowser..."
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  FILE="linux-amd64-filebrowser"
elif [[ "$ARCH" == "aarch64" ]]; then
  FILE="linux-arm64-filebrowser"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

echo "Downloading ${FILE}..."
curl -L -f "${RELEASE_BASE}/${FILE}" -o "${BIN_DIR}/${APP_NAME}" || { echo "Download failed"; exit 1; }
if ! file "${BIN_DIR}/${APP_NAME}" | grep -q "ELF"; then
    echo "ERROR: Downloaded file is not a valid ELF binary!"
    exit 1
fi
chmod +x "${BIN_DIR}/${APP_NAME}"
echo "Installed binary to ${BIN_DIR}/${APP_NAME} and made it executable"

# -----------------------------
# 2) Create config directory
# -----------------------------
echo "Creating config directory at ${CONFIG_DIR}..."
mkdir -p "${CONFIG_DIR}"

if [[ -z "$PORT" ]]; then
    echo "ERROR: Port not specified!"
    exit 1
fi

# Basic config.yaml
cat > "${CONFIG_FILE}" <<EOF
server:
  bind: ":${PORT}"
  baseURL: "/"
auth:
  adminUsername: "admin"
  adminPassword: "admin"
database: "/etc/filebrowser/database.db"
EOF

echo "Default config written to ${CONFIG_FILE}"

# -----------------------------
# 3) systemd service file
# -----------------------------
echo "Creating systemd service..."
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=FileBrowser (gtsteffaniak/filebrowser)
After=network.target

[Service]
Type=simple
ExecStart=${BIN_DIR}/${APP_NAME} -c ${CONFIG_FILE}
Restart=on-failure
User=root
Group=root
WorkingDirectory=/etc/filebrowser

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable filebrowser.service

# -----------------------------
# 4) Start service
# -----------------------------
systemctl start filebrowser.service

echo "==============================="
echo "FileBrowser installed & started"
echo "Access: http://$(hostname -I | awk '{print $1}'):${PORT}"
echo "Username: admin"
echo "Password: admin"
echo "Config at: ${CONFIG_FILE}"
echo "You can modify config and restart service via:"
echo "  systemctl restart filebrowser"
echo "==============================="
