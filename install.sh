#!/usr/bin/env bash
set -e

cd /root || exit 1
APP_NAME="filebrowser"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/filebrowser"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
SERVICE_FILE="/etc/systemd/system/filebrowser.service"
RELEASE_BASE="https://github.com/gtsteffaniak/filebrowser/releases/latest/download"
STORAGE_NAME="/filebrowser_quantum_storage"

PORT=$1
USERNAME=$2

if [[ -z "$PORT" || -z "$USERNAME" ]]; then
    echo "Usage: $0 <port> <username>"
    exit 1
fi

sudo mkdir -p /etc/filebrowser
sudo chown -R root:root /etc/filebrowser
sudo chmod -R 700 /etc/filebrowser

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

if systemctl list-units --all | grep -q filebrowser.service; then
    sudo systemctl stop filebrowser
fi

if [ -f "${BIN_DIR}/${APP_NAME}" ]; then
    sudo rm -f "${BIN_DIR}/${APP_NAME}"
fi

echo "Downloading ${FILE}..."
curl -L -f "${RELEASE_BASE}/${FILE}" -o "${BIN_DIR}/${APP_NAME}" || { 
    echo "Download failed"; 
    [ -f "${BIN_DIR}/${APP_NAME}" ] && sudo rm -f "${BIN_DIR}/${APP_NAME}" 
    exit 1
}

if ! file "${BIN_DIR}/${APP_NAME}" | grep -q "ELF"; then
    echo "ERROR: Downloaded file is not a valid ELF binary!"
    exit 1
fi

sudo chmod +x "${BIN_DIR}/${APP_NAME}"
echo "Installed binary to ${BIN_DIR}/${APP_NAME} and made it executable"

cat > "${CONFIG_FILE}" <<EOF
server:
  port: ${PORT}
  baseURL: "/"                
  database: "/etc/filebrowser/database.db"
  sources:
    - path: "${STORAGE_NAME}"
      name: "My Files"
      config:
        private: true

auth:
  adminUsername: "${USERNAME}"
  adminPassword: "admin123456"
  methods:
    password:
      enabled: true
      minLength: 10
EOF

if [[ ! -d "${STORAGE_NAME}" ]]; then
    sudo mkdir -p "${STORAGE_NAME}"
    sudo chown -R root:root "${STORAGE_NAME}"
    sudo chmod 700 "${STORAGE_NAME}"  
fi

echo "Default config written to ${CONFIG_FILE}"

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
systemctl start filebrowser.service

echo "==============================="
echo "FileBrowser installed & started"
echo "Access: http://$(hostname -I | awk '{print $1}'):${PORT}"
echo "Username: ${USERNAME}"
echo "Password: admin123456"
echo "Config at: ${CONFIG_FILE}"
echo "You can modify config and restart service via:"
echo "  systemctl restart filebrowser"
echo "==============================="
