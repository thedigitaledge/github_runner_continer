# GitHub Self-Hosted Runner Containers & Quadlet Service Templates

This repository provides container definitions and Podman Quadlet systemd unit templates for running GitHub Actions self-hosted runners using Podman or Docker.

## Overview

The setup consists of two container images:
1. **Base GitHub Runner Container** (`Containerfile.base` / `Dockerfile.base`):
   - Based on `ghcr.io/actions/actions-runner:latest`.
   - Includes `/entrypoint.sh` (`github-runner-entrypoint.sh`) to automatically register or restore runner registration with GitHub.
   - Runs securely as the non-root `runner` user (UID 1001).

2. **Extended GitHub Runner Container with Docker CLI** (`Containerfile.docker` / `Dockerfile.docker`):
   - Extends the base runner image.
   - Installs `docker-ce-cli` to enable container workflows and interaction with host container engines (Podman / Docker socket).
   - Runs securely as the non-root `runner` user.

Additionally, systemd Quadlet unit templates (`.container`) are provided for user-level service management under Podman.

---

## File Structure

- `github-runner-entrypoint.sh`: Entrypoint script responsible for registering the runner with GitHub and managing persistent configuration backup.
- `Containerfile.base` / `Dockerfile.base`: Container definition for the base runner image.
- `Containerfile.docker` / `Dockerfile.docker`: Container definition for the extended runner image with `docker-ce-cli`.
- `github-runner-base.container`: Podman Quadlet systemd unit template for the base runner.
- `github-runner-docker.container`: Podman Quadlet systemd unit template for the extended runner with Docker CLI.

---

## How to Build the Containers

### Using Podman
```bash
# Build base runner image
podman build -f Containerfile.base -t github-runner-base:latest .

# Build extended runner image with Docker CLI
podman build -f Containerfile.docker -t github-runner-docker:latest .
```

### Using Docker
```bash
# Build base runner image
docker build -f Dockerfile.base -t github-runner-base:latest .

# Build extended runner image with Docker CLI
docker build -f Dockerfile.docker -t github-runner-docker:latest .
```

---

## Running Locally Without Attaching to GitHub

You can run the `github-runner-docker` container locally for testing, debugging, or interactive container workflows without attaching or registering the runner with GitHub.

When no GitHub registration credentials (`GITHUB_REPOSITORY` or `RUNNER_TOKEN`) are supplied, the entrypoint script automatically runs in local mode and drops into an interactive shell.

### Interactive Shell with Host Podman Socket

Mount your host Podman socket into the container so the installed `docker` CLI can communicate with your host container engine:

```bash
podman run --rm -it \
  -v "${XDG_RUNTIME_DIR}/podman/podman.sock:/var/run/docker.sock:z" \
  github-runner-docker:latest
```

> **Note on Podman Socket:**
> Ensure the Podman socket service is enabled and active on your host system:
> ```bash
> systemctl --user enable --now podman.socket
> ```

### Running One-off Commands

You can also execute individual commands directly inside the runner:

```bash
# Check Docker CLI version connected to host Podman socket
podman run --rm \
  -v "${XDG_RUNTIME_DIR}/podman/podman.sock:/var/run/docker.sock:z" \
  github-runner-docker:latest docker version
```

---

## Quadlet Unit Deployment & Customization

Podman Quadlet systemd service files allow rootless user-level execution of containers managed directly by `systemd`.

### Customization Highlights

Before deploying, update the following placeholders in your chosen `.container` file:

- **`{container_image_url}`**: Image tag or registry path (e.g. `github-runner-base:latest` or `github-runner-docker:latest`).
- **`{owner}`**: GitHub organization or user account name.
- **`{repo_name}`**: GitHub repository name.
- **`{runner_labels}`**: Comma-separated list of runner labels (e.g. `self-hosted,linux,x64,podman`).
- **`{host_work_dir}`**: Host directory for workspace persistence (e.g. `/var/srv/github-runner-work` or `~/.github-runner/_work`).
- **`{host_docker_socket}`**: Host Docker/Podman socket path (e.g. `/run/user/1000/podman/podman.sock` or `/var/run/docker.sock`).

To inject the runner registration token securely without hardcoding:
```bash
podman secret create github_runner_token_{repo_name} -
# Enter token and press Ctrl+D
```

### Installation Steps

1. Copy the customized `.container` file to your user Quadlet directory:
   ```bash
   mkdir -p ~/.config/containers/systemd/
   cp github-runner-docker.container ~/.config/containers/systemd/github-runner-myrepo.container
   ```

2. Reload systemd and start the service:
   ```bash
   systemctl --user daemon-reload
   systemctl --user enable --now github-runner-myrepo.service
   ```

3. Check service status:
   ```bash
   systemctl --user status github-runner-myrepo.service
   journalctl --user -u github-runner-myrepo.service -f
   ```
