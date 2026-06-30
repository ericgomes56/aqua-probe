# Aqua Probe Docker Image

This folder contains the Docker build context for the Aqua Probe test image.

## What changed

- `Dockerfile` now handles both `aarch64` and `amd64` CentOS 7 repo paths.
- `repo.txt` uses working HTTPS CentOS vault URLs.
- Go is downloaded with `wget --no-check-certificate` to handle self-signed corporate TLS inspection paths.
- The `memrun` repository is cloned with `git -c http.sslVerify=false`.
- The `/tmp/memrun` build step was fixed so the compiled binary is not deleted during cleanup.

## Architecture notes

Apple Silicon Macs build ARM images by default (`linux/arm64` / `aarch64`). Most Kubernetes worker nodes are Linux `amd64`, especially in common cloud-managed clusters. If you build the Aqua Probe image on a Mac and then run it in Kubernetes, make sure you build and push the architecture that matches your Kubernetes nodes.

For a local Apple Silicon Mac test build:

```bash
docker build --no-cache -t aqua-probe-build-test:local .
```

For a Linux `amd64` Kubernetes node image:

```bash
docker build --platform linux/amd64 -t ericgomes56/aqua-probe:2.0 .
```

For an ARM Kubernetes node image:

```bash
docker build --platform linux/arm64 -t ericgomes56/aqua-probe:2.0 .
```

If your Kubernetes cluster has mixed node architectures, publish a multi-architecture image manifest instead of a single-architecture image.

## Validation performed

The following builds were validated from this `Dockerfile/` folder:

```bash
docker build --no-cache -t aqua-probe-build-test:local .
docker build --platform linux/amd64 -t aqua-probe-build-test:amd64 .
```

Smoke tests confirmed the image includes:

- `/tmp/memrun`
- `/tmp/target`
- `wget`
- `ncat`
- Go `1.21.4`
