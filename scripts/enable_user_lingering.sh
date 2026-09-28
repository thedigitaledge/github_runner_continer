#!/usr/bin/env bash
# Enable systemd user lingering so non-root Quadlet container services
# start automatically at boot and remain active without an interactive SSH session.

set -e

TARGET_USER="${1:-$USER}"

echo "Enabling systemd user lingering for user: ${TARGET_USER}..."
if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "${TARGET_USER}"
    echo "Successfully enabled user lingering for ${TARGET_USER}."
    loginctl show-user "${TARGET_USER}" | grep Linger
else
    echo "Error: loginctl command not found. Please ensure systemd is installed."
    exit 1
fi
