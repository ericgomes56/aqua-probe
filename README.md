<img src="/misc/aqua_probe_1x1.png" width="300" height="300">


# Aqua Probe: The Aqua Security Runtime Input Validator Tool

## Overview
Aqua Probe is an interactive command-line tool for validating Aqua runtime security controls in Kubernetes and on explicitly selected Linux hosts over SSH. Host tests use Host Runtime Policies and native host processes, not container policies or Kubernetes exec.

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

Main menu option **33** opens the shared Host Runtime controls below. Option **32** remains Terminate Program.

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

**Linux only. Enforce only. Requires container restart.** In the Container Runtime Policy, select **Enable Capabilities Block control**, choose `CHOWN` under **Drop Capabilities**, and save the policy before running this test. The test recreates its owned pod so the new setting applies at startup, and schedules it only on Linux nodes.

The root pod drops all capabilities in its Kubernetes spec, then requests only `CHOWN`. Aqua's selected drop setting should remove that capability. The test displays `/proc/1/status` (CHOWN is bit 0 in `CapEff` and `CapBnd`), creates a disposable file, and separately attempts `chown 12345 /tmp/aqua-chown-test`. File setup failure stops the test. Allow container exec and the test commands; ensure other controls do not reject the root user or added capability before this test can run.

The dropdown options shown in the supplied Aqua UI screenshots are:

```text
ALL
AUDIT_CONTROL, AUDIT_WRITE, BLOCK_SUSPEND, CHOWN
DAC_OVERRIDE, DAC_READ_SEARCH, FOWNER, FSETID
IPC_LOCK, IPC_OWNER, KILL, LEASE, LINUX_IMMUTABLE
MAC_ADMIN, MAC_OVERRIDE, MKNOD
NET_ADMIN, NET_BIND_SERVICE, NET_BROADCAST, NET_RAW
SETGID, SETFCAP, SETPCAP, SETUID
SYS_ADMIN, SYS_BOOT, SYS_CHROOT, SYS_MODULE, SYS_NICE
SYS_PACCT, SYS_PTRACE, SYS_RAWIO, SYS_RESOURCE, SYS_TIME
SYS_TTY_CONFIG, SYSLOG, WAKE_ALARM
```

`ALL` is also available, but `CHOWN` isolates this example. The other options are documented choices, not additional automated tests. A failed command alone is insufficient: inspect the runtime capability masks and effective Aqua policy. Capability removal can produce a kernel permission error without a separate Aqua incident for every denied operation. Kubernetes admission and filesystem errors must be distinguished from this control.

### Executables Allowed

Allow sleep and date, exclude uname, and enable Executables Allowed in Enforce mode. The test first runs the allowed date baseline, then uname -a. The image must contain both binaries; a missing executable is not evidence of enforcement.

### Forensics

Enable process and command-argument collection for the test pod. Separate echo, id and ls executions generate harmless forensic activity with the aqua-probe-forensics-marker argument. Verify collected activity in Aqua; this test does not require a block or security incident.

### Limit New Privileges

Enable Limit New Privileges and inspect PID 1's NoNewPrivs flag in a pod requesting allowPrivilegeEscalation: true. Expect 1 with no-new-privileges enforced. Check admission mutations and effective policy before attributing the setting to Aqua; the flag itself need not produce an incident.

### Registries Allowed

Configure Registries Allowed and choose an accessible image from an excluded registry. The default Docker Hub image is a trigger only when Docker Hub is excluded. Registry authentication and image-pull errors are not proof of an Aqua denial.

## Host Runtime Policies

Use main menu option **33**, or open the Host Runtime menu directly without Kubernetes startup checks:

```bash
./aqua-probe.sh --host-runtime
```

Select an authorized Linux lab host monitored by an Aqua Enforcer. Supply its SSH hostname/IP, port, username, and optional local `.pem`/private key path. The selected connection is reused within the session; option **11** changes it. Commands execute as that user without automatic sudo or package installation. Bash is required on the host. SSH host-key verification remains enabled. Each test requires explicit confirmation, even with `--no-instructions`.

| Host menu | Control | Host validation |
| --- | --- | --- |
| 1 | Block Cryptocurrency Mining | `wget http://crypto-loot.com`, bounded timeout, no redirects, response discarded |
| 2 | Brute Force Login Detection | Existing bounded SSH authentication-failure workflow; separate target/account prompts |
| 3 | DNS/IP Reputation | `curl http://68.183.212.246`, bounded timeout, response discarded |
| 4 | File Block | `cat /etc/passwd`; configure this path as blocked; prints account information if allowed |
| 5 | File Integrity Monitoring | Create, modify, chmod, and delete disposable files under `/tmp/aqua-probe-host-fim-*` |
| 6 | Forensics | `echo aqua-probe-forensics-marker`, `id`, and `ls /tmp`; review host process collection |
| 7 | Package Block | `tar`; its ordinary missing-arguments error is not proof of enforcement |
| 8 | Port Scanning Detection | Bash `/dev/tcp` probes on ports 1-1024 of an explicitly authorized destination; default `10.0.0.1`, maximum 16 concurrent one-second probes |
| 9 | Secure AI - Discovery | One native Python 3 HTTPS request to OpenAI; review host AI Findings |
| 10 | Secure AI - Unauthorized Models | Same host request, with model matching the configured policy, e.g. `OpenAI@gpt-4` |

Scope the corresponding **Host Runtime Policy** to the selected host and verify Enforcer coverage and feature availability. Shared commands can exercise the same signatures, but policy mode, network reputation, scan thresholds, host OS, and tenant support determine results. Failures from SSH, missing tools, network access, or permissions are not evidence of an Aqua block. Verify the matching host, policy, and timestamp in **Security Reports -> Audit**, or the relevant forensic/AI view.

Host FIM deliberately never modifies or deletes the real `/etc/sudoers`. Configure monitoring for the disposable directory pattern and descendants before testing. A remote cleanup trap removes only its two test files and owned directory on normal exit and catchable signals. If enforcement denies cleanup, the process is forcibly killed, or the host disappears, inspect and remove only the printed owned directory manually. No containers, services, or persistent host applications are installed; audit/authentication records remain.

Secure AI requires native Python 3, HTTPS connectivity, model access, and supported host Secure AI coverage. The model is prompted (default `gpt-4` for consistency with the existing example); select an available Chat Completions model and match the policy. A retired/unavailable model or API billing/authentication error is not an Aqua detection. A request can incur provider charges. The key prompt is hidden, shell tracing is disabled for the request, and the key travels only through encrypted SSH stdin to the host process and HTTPS to OpenAI, never in command arguments, files, or environment variables. Each request asks for a fresh key. The API request follows the [OpenAI Chat Completions reference](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create).

Host menu option **0** returns to the main menu, or exits when launched with `--host-runtime`. It does not run unrelated Kubernetes/Docker cleanup. Run `bash tests/test-host-runtime.sh` for offline mocked tests; these do not contact a host or OpenAI.

### Brute Force Login Detection

Brute Force remains directly accessible from main menu option **31** and host menu option **2**. Enable it in the Host Runtime Policy applied to the target. The target SSH service must accept password authentication for the password-based test. Supply its hostname/IP, SSH port, and a dedicated test account. Check account lockout settings, then enter an intentionally incorrect password at each SSH prompt. The script defaults to five attempts and permits up to ten per run; align the count and timing with your policy's detection threshold/window. Passwords are handled interactively by SSH and are not stored by Aqua Probe.

The optional **SSH private key file path** prompt accepts a local key such as `~/.ssh/test.pem` (paths with spaces are supported; enter the path without surrounding quotes). Press Enter to retain password authentication. With a key, SSH uses public-key authentication and prompts for its passphrase if needed; Aqua Probe does not copy the key or store its passphrase. A valid authorized key succeeds and stops the test, so it does not generate brute-force failures. A key-based failure test requires rejected authentication attempts observed by the host and supported by the configured detection policy. A missing, unreadable, or invalid key does not prove detection.

Confirm actual authentication failures in the host logs and review **Security Reports -> Audit** in Aqua. A connection failure, host-key error, or nonzero SSH exit code does not establish an Aqua detection. Unexpected successful authentication stops the test. No Kubernetes, Docker, or host test resources are created; authentication and audit records remain for review. Menu option 32 terminates the program and runs the existing cleanup.

The following host-specific controls remain catalog items without dedicated host test functions in this update:

- Bypass Scope
- OS Users and Groups Allowed
- OS Users and Groups Blocked
- System Integrity Monitoring
- Windows Registry Monitoring
- Windows Registry Protection

## Usage
The banner, control headings, menu, prompts, and status messages share [Aqua's website palette](https://www.aquasec.com/): electric blue and teal on deep navy. Teal highlights prompts and review guidance, yellow marks prerequisites and warnings, and magenta marks errors. Titles are centered, menu entries and prerequisites wrap to the terminal width, and menu groups distinguish workload controls from host controls without changing option numbers. Commands and external tool output remain plain and copyable. True-color terminals use the exact brand colors; other color terminals use standard ANSI equivalents. Set `NO_COLOR=1` for plain-text output; redirected output and `TERM=dumb` also omit color codes.

Run `bash tests/test-terminal-theme.sh` to check the terminal formatting without deploying resources or executing security tests.

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
