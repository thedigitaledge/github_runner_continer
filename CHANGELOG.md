# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.0.1] - 2026-09-26

### Added
- Base GitHub Self-Hosted Runner container definition (`Containerfile.base`).
- Extended GitHub Runner container with Docker CLI (`Containerfile.docker`).
- Podman Quadlet service unit templates (`github-runner-base.container`, `github-runner-docker.container`).
- GitHub Actions workflow for building and publishing container images (`.github/workflows/container-publish.yml`).
- OCI container image annotations/labels support.
