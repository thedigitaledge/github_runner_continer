#!/usr/bin/env bash
set -e

cd "${HOME:-/home/runner}"

CONFIG_DIR="${HOME}/config"

# Strip all trailing newlines, carriage returns, and spaces from token
CLEAN_TOKEN=$(echo -n "${RUNNER_TOKEN}" | tr -d '\r\n ')

if [ -f "${CONFIG_DIR}/.runner" ]; then
    echo "Existing configuration found. Restoring..."
    cp -f "${CONFIG_DIR}/.runner" "${CONFIG_DIR}"/.credentials* ./ 2>/dev/null || true
else
    echo "No configuration found. Registering runner with GitHub..."
    ./config.sh --url "${GITHUB_REPOSITORY}" \
                --token "${CLEAN_TOKEN}" \
                --name "${RUNNER_NAME}" \
                --labels "${RUNNER_LABELS}" \
                --unattended \
                --replace

    echo "Backing up configuration to persistent volume..."
    mkdir -p "${CONFIG_DIR}"
    cp -f .runner .credentials* "${CONFIG_DIR}/" 2>/dev/null || true
fi

echo "Starting runner..."
exec ./run.sh
