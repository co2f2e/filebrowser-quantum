#!/usr/bin/env bash
set -e

APP_NAME="filebrowser"
BIN_PATH="/usr/local/bin/${APP_NAME}"
CONFIG_DIR="/etc/filebrowser"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"

echo "Stopping FileBrowser service..."
if systemctl is-active --quiet ${APP_NAME}; then
    sudo systemctl stop ${APP_NAME}
fi

echo "Disabling FileBrowser service..."
if systemctl is-enabled --quiet ${APP_NAME}; then
    sudo systemctl disable ${APP_NAME}
fi

echo "Removing systemd service file..."
if [ -f "${SERVICE_FILE}" ]; then
    sudo rm -f "${SERVICE_FILE}"
    sudo systemctl daemon-reload
fi

echo "Removing binary..."
if [ -f "${BIN_PATH}" ]; then
    sudo rm -f "${BIN_PATH}"
fi

echo "Removing configuration directory..."
if [ -d "${CONFIG_DIR}" ]; then
    sudo rm -rf "${CONFIG_DIR}"
fi

echo "FileBrowser has been completely uninstalled."
