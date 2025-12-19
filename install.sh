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
PORT=8080
RELEASE_BASE="https://github.com/gtsteffaniak/filebrowser/releases/latest/download"

# -----------------------------
# 1) Download binary
# -----------------------------
echo "Downloading FileBrowser..."
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  FILE="${APP_NAME}_linux_amd64"
elif [[ "$ARCH" == "aarch64" ]]; then
  FILE="${APP_NAME}_linux_arm64"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

curl -L "${RELEASE_BASE}/${FILE}" -o "${BIN_DIR}/${APP_NAME}"
chmod +x "${BIN_DIR}/${APP_NAME}"
echo "Installed binary to ${BIN_DIR}/${APP_NAME}"

# -----------------------------
# 2) Create config directory
# -----------------------------
echo "Creating config directory at ${CONFIG_DIR}..."
mkdir -p "${CONFIG_DIR}"

# Basic config.yaml
cat > "${CONFIG_FILE}" <<EOF
server:
  bind: ":${PORT}"
  baseURL: "/"
auth:
  adminUsername: "admin"
  adminPassword: "admin"
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
WorkingDirectory=/

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
