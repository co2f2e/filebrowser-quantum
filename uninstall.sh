#!/usr/bin/env bash
set -e

APP_NAME="filebrowser"
BIN_PATH="/usr/local/bin/${APP_NAME}"
CONFIG_DIR="/etc/filebrowser"
SERVICE_FILE="/etc/systemd/system/${APP_NAME}.service"
STORAGE_NAME="/filebrowser_quantum_storage"

echo "Stopping FileBrowser service..."
if systemctl is-active --quiet ${APP_NAME}; then
    systemctl stop ${APP_NAME}
fi

echo "Disabling FileBrowser service..."
if systemctl is-enabled --quiet ${APP_NAME}; then
    systemctl disable ${APP_NAME}
fi

echo "Removing systemd service file..."
if [ -f "${SERVICE_FILE}" ]; then
    rm -f "${SERVICE_FILE}"
    systemctl daemon-reload
fi

echo "Removing binary..."
if [ -f "${BIN_PATH}" ]; then
    rm -f "${BIN_PATH}"
fi

echo "Removing configuration directory..."
if [ -d "${CONFIG_DIR}" ]; then
    rm -rf "${CONFIG_DIR}"
fi

if [ -d "${STORAGE_NAME}" ]; then
    read -p "Directory ${STORAGE_NAME} already exists. Do you want to keep existing files? [y/N]: " keep
    case "$keep" in
        [yY]|[yY][eE][sS])
            echo "Keeping existing files."
            ;;
        *)
            echo "Deleting existing directory..."
            rm -rf "${STORAGE_NAME}"
            ;;
    esac
fi

echo "FileBrowser has been completely uninstalled."
