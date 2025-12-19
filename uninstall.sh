#!/usr/bin/env bash
set -e

APP_NAME="filebrowser"
BIN_PATH="/usr/local/bin/filebrowser"
CONFIG_DIR="/etc/filebrowser"
SERVICE_FILE="/etc/systemd/system/filebrowser.service"

echo "Stopping filebrowser service (if running)..."
if systemctl list-units --full -all | grep -q "${APP_NAME}.service"; then
    systemctl stop ${APP_NAME}.service || true
    systemctl disable ${APP_NAME}.service || true
fi

echo "Removing systemd service file..."
if [ -f "${SERVICE_FILE}" ]; then
    rm -f "${SERVICE_FILE}"
fi

echo "Reloading systemd daemon..."
systemctl daemon-reload
systemctl reset-failed || true

echo "Removing binary..."
if [ -f "${BIN_PATH}" ]; then
    rm -f "${BIN_PATH}"
fi

echo "Removing config directory..."
if [ -d "${CONFIG_DIR}" ]; then
    rm -rf "${CONFIG_DIR}"
fi

echo "==============================="
echo "FileBrowser has been completely removed."
echo "Binary: ${BIN_PATH}"
echo "Config: ${CONFIG_DIR}"
echo "Service: ${SERVICE_FILE}"
echo "==============================="
