<img src="/misc/aqua_probe_1x1.png" width="300" height="300">


# Aqua Probe: The Aqua Security Runtime Input Validator Tool

## Overview
Aqua Probe is an interactive command-line tool designed to explore runtime security features provided by Aqua Security within Kubernetes environments. It allows users to experience Real-Time Malware Protection, Drift Prevention, and other security controls offered by Aqua.

<img src="/misc/aqua-probe-demo.gif" height="500">

## Features
1. Deploy a test container within a Kubernetes cluster
2. Test Bad DNS/IP Reputation
3. Test Block Container Exec
4. Test Block Cryptocurrency Mining
5. Test Block Fileless Exec
6. Test Block Non-compliant Images
7. Test Block Non-compliant Resources
8. Test Block Non-Kubernetes Containers
9. Test Block Reverse Shell
10. Test Block Unregistered Images
11. Test Drift Prevention
12. Test Executables Blocked
13. Test File Block
14. Test File Integrity Monitoring
15. Test Limit Container Privileges
16. Test Package Block
17. Test Port Block
18. Test Port Scanning Detection
19. Test Real-time Malware Protection with delete action
20. Test Secure AI - Discovery
21. Test Secure AI - Protection
22. Test Secure AI - Unauthorized Models
23. Test System Integrity Monitoring
24. Test Volumes Blocked
25. Test Block Outdated Images
26. Test Capabilities Block
27. Test Executables Allowed
28. Test Forensics
29. Test Limit New Privileges
30. Test Registries Allowed
31. Test Brute Force Login Detection [Host Runtime Policy]

## Limit Container Privileges

Menu option 15 uses a Container Runtime Policy with these options from the Aqua UI:

| Platform | Option | Test coverage |
| --- | --- | --- |
| Linux | Access to host network | `hostNetwork: true` |
| Linux | Adding capabilities with --cap-add | `securityContext.capabilities.add: [NET_ADMIN]` |
| Linux | Configured with 'root' user | `runAsUser: 0` |
| Linux | Privileged containers | `privileged: true` |
| Linux | Use the host IPC namespace | `hostIPC: true` |
| Linux | Use the host PID namespace | `hostPID: true` |
| Linux | Use the host user namespace | `hostUsers: true`; requires API/runtime support |
| Linux | Use the host UTS namespace | Separate Docker `--uts=host` test; not automated here |
| Windows | Port binding lower than 1024 | Compatible Windows image actually binding a low port; not automated here |

The workflow deploys seven Linux pods in `aqua-probe-lab`. Select one restriction at a time to isolate results: root images and shared host namespaces may match multiple restrictions. Confirm Aqua audit evidence before attributing deployment failures to this control.

Kubernetes has no host UTS pod field; `hostNetwork` selects the network namespace only. See the [Kubernetes Pod API](https://kubernetes.io/docs/reference/kubernetes-api/core/pod-v1/) and [Docker UTS documentation](https://docs.docker.com/reference/cli/docker/container/run/#uts). A Docker UTS test needs policy scope covering the Docker container rather than a Kubernetes namespace. The Linux Aqua Probe image cannot validate the Windows-only option, and declaring `containerPort: 80` alone does not create a listener.

## Dedicated Container Controls

These tests prompt for a custom image (default: `ericgomes56/aqua-probe:2.0`) and prerequisites. They create labeled pods in `aqua-probe-lab` with `imagePullPolicy: Always`. Termination removes those pods, including files created inside them. Prerequisite confirmation remains enabled even with `--no-instructions`. Images need `sleep` plus the commands described below.

### Block Outdated Images

Choose an image Aqua classifies as outdated under the configured Container Runtime Policy, then enable Block Outdated Images in Enforce mode. The default image is only a candidate, not a guaranteed trigger. Compare the pod result with the specific Aqua audit event.

### Capabilities Block

Block CHOWN in the Capabilities Block control. The dedicated root pod drops all capabilities and requests only CHOWN, then attempts to change the owner of a disposable file. Kubernetes admission restrictions or ordinary filesystem permissions can also reject this test; correlate with Aqua.

### Executables Allowed

Allow sleep and date, exclude uname, and enable Executables Allowed in Enforce mode. The test first runs the allowed date baseline, then uname -a. The image must contain both binaries; a missing executable is not evidence of enforcement.

### Forensics

Enable process and command-argument collection for the test pod. Separate echo, id and ls executions generate harmless forensic activity with the aqua-probe-forensics-marker argument. Verify collected activity in Aqua; this test does not require a block or security incident.

### Limit New Privileges

Enable Limit New Privileges and inspect PID 1's NoNewPrivs flag in a pod requesting allowPrivilegeEscalation: true. Expect 1 with no-new-privileges enforced. Check admission mutations and effective policy before attributing the setting to Aqua; the flag itself need not produce an incident.

### Registries Allowed

Configure Registries Allowed and choose an accessible image from an excluded registry. The default Docker Hub image is a trigger only when Docker Hub is excluded. Registry authentication and image-pull errors are not proof of an Aqua denial.

## Host Runtime Policies

Brute Force Login Detection uses a **Host Runtime Policy**, with an Aqua Enforcer monitoring the target Linux host. Run it from menu option 31, or run it directly without Kubernetes startup checks:

```bash
./aqua-probe.sh --host-runtime
```

Enable Brute Force Login Detection in the Host Runtime Policy applied to the target. The target SSH service must accept password authentication. Supply its hostname/IP, SSH port, and a dedicated test account. Check account lockout settings, then enter an intentionally incorrect password at each SSH prompt. The script defaults to five attempts and permits up to ten per run; align the count and timing with your policy's detection threshold/window. Passwords are handled interactively by SSH and are not stored by Aqua Probe. SSH host-key verification remains enabled.

The optional **SSH private key file path** prompt accepts a local key such as `~/.ssh/test.pem` (paths with spaces are supported; enter the path without surrounding quotes). Press Enter to retain password authentication. With a key, SSH uses public-key authentication and prompts for its passphrase if needed; Aqua Probe does not copy the key or store its passphrase. A valid authorized key succeeds and stops the test, so it does not generate brute-force failures. A key-based failure test requires rejected authentication attempts observed by the host and supported by the configured detection policy. A missing, unreadable, or invalid key does not prove detection.

Confirm actual authentication failures in the host logs and review **Security Reports -> Audit** in Aqua. A connection failure, host-key error, or nonzero SSH exit code does not establish an Aqua detection. Unexpected successful authentication stops the test. No Kubernetes, Docker, or host test resources are created; authentication and audit records remain for review. Menu option 32 terminates the program and runs the existing cleanup.

Host Runtime controls include the following catalog supplied for this project. Brute Force Login Detection is the host test implemented here; the other entries are not additional host test functions. Shared signatures do not make the existing container tests Host Runtime Policy tests. Availability depends on the target OS and tenant configuration, particularly for Windows registry controls.

- Block Cryptocurrency Mining
- Brute Force Login Detection
- DNS/IP Reputation
- File Block
- File Integrity Monitoring
- Forensics
- OS Users and Groups Allowed
- OS Users and Groups Blocked
- Package Block
- Port Scanning Detection
- Secure AI - Discovery
- Secure AI - Unauthorized Models
- System Integrity Monitoring
- Windows Registry Monitoring
- Windows Registry Protection

## Usage
1. Ensure you have `kubectl` configured to connect to your Kubernetes cluster.
2. Run the script by executing `./aqua-probe.sh`.
3. Follow the on-screen prompts to deploy the test container and perform security tests.
4. Kubernetes test resources are created in the `aqua-probe-lab` namespace.
5. Deployment prompts let you specify a custom image, or press Enter to use `ericgomes56/aqua-probe:2.0`.

## Requirements
- Bash shell
- `kubectl` configured to connect to a Kubernetes cluster
- Aqua Enforcer daemonset deployed in the Kubernetes cluster
- Internet access to a Docker registry or the ability to push the Aqua Probe test image (ericgomes56/aqua-probe:2.0) to a local registry
- Permissions to deploy container in the Kubernetes cluster (ericgomes56/aqua-probe:2.0)

## Installation
1. Clone this repository to your local machine
2. Ensure you have the necessary permissions to execute the script (`chmod +x aqua-probe.sh`)

## Usage Example
```bash
# Default mode - utilizes ericgomes56/aqua-probe:2.0 image
./aqua-probe.sh

# Advanced mode
./aqua-probe.sh --no-instructions --image <image_name>
./aqua-probe.sh -n -i <image_name>
```

<img src="/misc/aqua-probe-advanced-commands.png" height="300">

## Additional commands
Set the custom daemonset name where the Aqua Enforcer is deployed (default: aqua-agent,kube-enforcer-ds)
```bash
./aqua-probe.sh --daemonset <value>, -d <value>
```
Show help menu which contains the list of commands 
```bash
./aqua-probe.sh --help, -h
```
Reference local registry image (default: ericgomes56/aqua-probe:2.0)
```bash
./aqua-probe.sh --image <image_name>, -i <image_name>
```
Skip test prerequisites instructions
```bash
./aqua-probe.sh --no-instructions, -n
```
Show the current Aqua Probe build version
```bash
./aqua-probe.sh --version, -v
```

## Aqua Probe Image
Container image examples use `ericgomes56/aqua-probe:2.0`.

## Credit
Aqua Probe is a maintained fork and evolution of Aqua Warden. The project has been rebranded and is actively developed to support Aqua runtime security testing, PoVs, and technical enablement.
