#!/usr/bin/env bash
set -e

# Grant write access to the mounted socket if it exists
if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock 2>/dev/null || true
fi

# If command arguments are provided, execute them directly
if [ "$#" -gt 0 ]; then
    if command -v gosu >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
        exec gosu runner "$@"
    else
        exec "$@"
    fi
fi

# If GitHub credentials are not provided, run local mode (interactive shell or keep-alive loop for background containers)
if [ -z "${GITHUB_REPOSITORY}" ] || [ -z "${RUNNER_TOKEN}" ]; then
    echo "No GitHub repository or token supplied. Running in local mode..."
    RUNNER_CMD="bash"
    if [ ! -t 0 ]; then
        # Non-interactive shell (e.g. docker run -d background container)
        RUNNER_CMD="tail -f /dev/null"
    fi

    if command -v gosu >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
        exec gosu runner ${RUNNER_CMD}
    else
        exec ${RUNNER_CMD}
    fi
fi

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
