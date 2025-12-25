#!/usr/bin/env bash
set -e

cd /root || exit 1
APP_NAME="filebrowser"
BIN_DIR="/usr/local/bin"
CONFIG_DIR="/etc/filebrowser_quantum"
CONFIG_FILE="${CONFIG_DIR}/config.yaml"
SERVICE_FILE="/etc/systemd/system/filebrowser_quantum.service"
RELEASE_BASE="https://github.com/gtsteffaniak/filebrowser/releases/latest/download"
ADMIN_STORAGE="/filebrowser_quantum_storage/admin"
SHARED_STORAGE="/filebrowser_quantum_storage/share"
USER_STORAGE="/filebrowser_quantum_storage/users"

PORT=$1
USERNAME=$2

if [[ -z "$PORT" || -z "$USERNAME" ]]; then
    echo "Usage: $0 <port> <username>"
    exit 1
fi

sudo mkdir -p "${CONFIG_DIR}"
sudo chown -R root:root "${CONFIG_DIR}"
sudo chmod -R 700 "${CONFIG_DIR}"

echo "Downloading FileBrowser Quantum..."
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
  FILE="linux-amd64-filebrowser"
elif [[ "$ARCH" == "aarch64" ]]; then
  FILE="linux-arm64-filebrowser"
else
  echo "Unsupported architecture: $ARCH"
  exit 1
fi

if systemctl list-units --all | grep -q filebrowserquantum.service; then
    sudo systemctl stop filebrowserquantum
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
  database: "/etc/filebrowser_quantum/database.db"
  sources:
    - path: "${ADMIN_STORAGE}"
      name: "Admin Files"
      config:
        private: true
    - path: "${USER_STORAGE}"
      name: "User Files"
      config:
         defaultEnabled: true
         createUserDir: true
    - path: "${SHARED_STORAGE}"
      name: "Shared Files"
      config:
        defaultEnabled: true
auth:
  adminUsername: "${USERNAME}"
  adminPassword: "admin123456"
  methods:
    password:
      enabled: true
      minLength: 10
logging:
  - output: "/var/log/filebrowser_quantum.log"
    levels: "error"
    noColors: false
EOF

if [[ ! -d "${ADMIN_STORAGE}" ]]; then
    sudo mkdir -p "${ADMIN_STORAGE}"
    sudo chown -R root:root "${ADMIN_STORAGE}"
    sudo chmod 700 "${ADMIN_STORAGE}"  
fi
if [[ ! -d "${USER_STORAGE}" ]]; then
    sudo mkdir -p "${USER_STORAGE}"
    sudo chown -R root:root "${USER_STORAGE}"
    sudo chmod 700 "${USER_STORAGE}"  
fi
if [[ ! -d "${SHARED_STORAGE}" ]]; then
    sudo mkdir -p "${SHARED_STORAGE}"
    sudo chown -R root:www-data "${SHARED_STORAGE}"
    sudo chmod -R 755 "${SHARED_STORAGE}"
fi

echo "Default config written to ${CONFIG_FILE}"

echo "Creating systemd service..."
cat > "${SERVICE_FILE}" <<EOF
[Unit]
Description=FileBrowserQuantum
After=network.target

[Service]
Type=simple
ExecStart=${BIN_DIR}/${APP_NAME} -c ${CONFIG_FILE}
Restart=on-failure
User=root
Group=root
WorkingDirectory=${CONFIG_DIR}

StandardOutput=journal
StandardError=journal

LogLevelMax=err

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable filebrowserquantum.service
systemctl start filebrowserquantum.service

echo "==============================="
echo "FileBrowserQuantum installed & started"
echo "Access: http://$(hostname -I | awk '{print $1}'):${PORT}"
echo "Username: ${USERNAME}"
echo "Password: admin123456"
echo "Config at: ${CONFIG_FILE}"
echo "You can modify config and restart service via:"
echo "  systemctl restart filebrowserquantum"
echo "==============================="
