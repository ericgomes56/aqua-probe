<img src="/misc/aqua_probe_1x1.png" width="300" height="300">


# Aqua Probe: The Aqua Security Runtime Input Validator Tool

## Overview
Aqua Probe is an interactive command-line tool for validating Aqua runtime security controls in Kubernetes and on explicitly selected Linux or Windows hosts over SSH. Host tests use Host Runtime Policies and native host processes, not container policies or Kubernetes exec. Windows registry tests require Windows Aqua Enforcer.

<img src="/misc/aqua-probe-demo.gif" height="500">

## Features

### Setup
1. Deploy/Redeploy test container
2. Select/change Linux SSH host

### Container & Workload Controls
3. Bad DNS/IP Reputation
4. Block Container Exec
5. Block Cryptocurrency Mining
6. Block Fileless Execution
7. Block Non-compliant Images
8. Block Non-compliant Resources
9. Block Non-Kubernetes Containers
10. Block Outdated Images
11. Block Reverse Shell
12. Block Unregistered Images
13. Capabilities Block
14. Drift Prevention
15. Executables Allowed
16. Executables Blocked
17. File Block
18. File Integrity Monitoring
19. Forensics
20. Limit Container Privileges
21. Limit New Privileges
22. Package Block
23. Port Block
24. Port Scanning Detection
25. Real-time Malware Protection [Delete action]
26. Registries Allowed
27. Secure AI - Discovery
28. Secure AI - Protection
29. Secure AI - Unauthorized Models
30. System Integrity Monitoring
31. Volumes Blocked

### Host Runtime Controls
32. Block Cryptocurrency Mining
33. Brute Force Login Detection
34. DNS/IP Reputation
35. File Block
36. File Integrity Monitoring
37. Forensics
38. OS Users and Groups Allowed
39. OS Users and Groups Blocked
40. Package Block
41. Port Scanning Detection
42. Secure AI - Discovery
43. Secure AI - Unauthorized Models
44. Windows Registry Monitoring [Windows only]
45. Windows Registry Protection [Windows only]

### Session
46. Clean up Windows registry test
47. Terminate Program

Controls are alphabetized within each scope. These numbers match the main menu; the `--host-runtime` interface retains its separate host-only numbering.

## Limit Container Privileges

Menu option 20 uses a Container Runtime Policy with these options from the Aqua UI:

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

Choose a test directly under **HOST RUNTIME CONTROLS** in the main menu, or launch the host-only interface without Kubernetes startup checks:

```bash
./aqua-probe.sh --host-runtime
```

For the shared Linux controls, select an authorized Linux lab host monitored by an Aqua Enforcer. Supply its SSH hostname/IP, port, username, and optional local `.pem`/private key path. The selected connection is reused within the session; main option **2** (host-only option **13**) changes it. Commands execute as that user without automatic sudo or package installation. Bash is required for these Linux controls. Authentication-policy and Windows registry tests prompt for their own target independently. SSH host-key verification remains enabled. Each test requires explicit confirmation, even with `--no-instructions`.

| Main menu | Host-only menu | Control | Host validation |
| --- | --- | --- | --- |
| 32 | 1 | Block Cryptocurrency Mining | `wget http://crypto-loot.com`, bounded timeout, no redirects, response discarded |
| 33 | 2 | Brute Force Login Detection | Existing bounded SSH authentication-failure workflow; separate target/account prompts |
| 34 | 3 | DNS/IP Reputation | `curl http://68.183.212.246`, bounded timeout, response discarded |
| 35 | 4 | File Block | `cat /etc/passwd`; configure this path as blocked; prints account information if allowed |
| 36 | 5 | File Integrity Monitoring | Create, modify, chmod, and delete disposable files under `/tmp/aqua-probe-host-fim-*` |
| 37 | 6 | Forensics | `echo aqua-probe-forensics-marker`, `id`, and `ls /tmp`; review host process collection |
| 38 | 7 | OS Users and Groups Allowed | Valid baseline login, then test user/group allowlist matching over a new SSH connection |
| 39 | 8 | OS Users and Groups Blocked | Valid baseline login, then test user/group blocklist matching over a new SSH connection |
| 40 | 9 | Package Block | `tar`; its ordinary missing-arguments error is not proof of enforcement |
| 41 | 10 | Port Scanning Detection | Bash `/dev/tcp` probes on ports 1-1024 of an explicitly authorized destination; default `10.0.0.1`, maximum 16 concurrent one-second probes |
| 42 | 11 | Secure AI - Discovery | One native Python 3 HTTPS request to OpenAI; review host AI Findings |
| 43 | 12 | Secure AI - Unauthorized Models | Same host request, with model matching the configured policy, e.g. `OpenAI@gpt-4` |
| 44 | 14 | Windows Registry Monitoring [Windows only] | PowerShell registry create, read, modify, delete, and ACL attribute activity; audit only; Windows Aqua Enforcer required |
| 45 | 15 | Windows Registry Protection [Windows only] | PowerShell create, modify, and delete attempts under a disposable protected path; Windows Aqua Enforcer required |

Scope the corresponding **Host Runtime Policy** to the selected host and verify Enforcer coverage and feature availability. Shared commands can exercise the same signatures, but policy mode, network reputation, scan thresholds, host OS, and tenant support determine results. Failures from SSH, missing tools, network access, or permissions are not evidence of an Aqua block. Verify the matching host, policy, and timestamp in **Security Reports -> Audit**, or the relevant forensic/AI view.

Host FIM deliberately never modifies or deletes the real `/etc/sudoers`. Configure monitoring for the disposable directory pattern and descendants before testing. A remote cleanup trap removes only its two test files and owned directory on normal exit and catchable signals. If enforcement denies cleanup, the process is forcibly killed, or the host disappears, inspect and remove only the printed owned directory manually. No containers, services, or persistent host applications are installed; audit/authentication records remain.

Secure AI requires native Python 3, HTTPS connectivity, model access, and supported host Secure AI coverage. The model is prompted (default `gpt-4` for consistency with the existing example); select an available Chat Completions model and match the policy. A retired/unavailable model or API billing/authentication error is not an Aqua detection. A request can incur provider charges. The key prompt is hidden, shell tracing is disabled for the request, and the key travels only through encrypted SSH stdin to the host process and HTTPS to OpenAI, never in command arguments, files, or environment variables. Each request asks for a fresh key. The API request follows the [OpenAI Chat Completions reference](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create).

In `--host-runtime` mode, option **0** exits without running unrelated Kubernetes/Docker cleanup, but retries any pending Windows registry cleanup. Main option **46** (host-only option **16**) retries Windows registry cleanup explicitly. The regular main menu runs host tests directly without a submenu. Run `bash tests/test-host-runtime.sh` for offline mocked tests; these do not contact a host or OpenAI.

### Brute Force Login Detection

Brute Force remains directly accessible from main menu option **33** and host menu option **2**. Enable it in the Host Runtime Policy applied to the target. The target SSH service must accept password authentication for the password-based test. Supply its hostname/IP, SSH port, and a dedicated test account. Check account lockout settings, then enter an intentionally incorrect password at each SSH prompt. The script defaults to five attempts and permits up to ten per run; align the count and timing with your policy's detection threshold/window. Passwords are handled interactively by SSH and are not stored by Aqua Probe.

The optional **SSH private key file path** prompt accepts a local key such as `~/.ssh/test.pem` (paths with spaces are supported; enter the path without surrounding quotes). Press Enter to retain password authentication. With a key, SSH uses public-key authentication and prompts for its passphrase if needed; Aqua Probe does not copy the key or store its passphrase. A valid authorized key succeeds and stops the test, so it does not generate brute-force failures. A key-based failure test requires rejected authentication attempts observed by the host and supported by the configured detection policy. A missing, unreadable, or invalid key does not prove detection.

Confirm actual authentication failures in the host logs and review **Security Reports -> Audit** in Aqua. A connection failure, host-key error, or nonzero SSH exit code does not establish an Aqua detection. Unexpected successful authentication stops the test. No Kubernetes, Docker, or host test resources are created by brute-force testing; authentication and audit records remain for review. Menu option 47 terminates the program and runs cleanup, including pending Windows registry tests.

### OS Users and Groups Allowed / Blocked

Main options **38** and **39** (host-only **7** and **8**) validate authentication controls on **Linux or Windows**, using the matching Aqua Enforcer and a Host Runtime Policy. Choose the host OS, SSH destination, existing test account, optional local key file, a user or group rule, and the expected **allow** or **deny** outcome. For Windows, use Windows OpenSSH and Windows Aqua Enforcer; groups may be Windows AD groups. This workflow tests SSH authentication, not RDP or console sign-in.

Use **valid credentials**, not deliberate password failures. A successful baseline login must complete before the script asks you to apply the test policy. Linux runs `id`; Windows runs `whoami.exe /all` to show account identity and group membership. For a group test, verify that the account really belongs to the named Linux/AD group. The script neither creates accounts nor changes memberships.

| Control | Expected allow | Expected deny |
| --- | --- | --- |
| OS Users and Groups Allowed | List the user in Users Allowed or a matching group in Groups Allowed. For a group test, omit a direct user entry that could mask the group rule. | Exclude the user and **all** its memberships from the allowed lists. |
| OS Users and Groups Blocked | Exclude the user and **all** its memberships from the blocked lists. | List the user in Users Blocked or its matching group in Groups Blocked. Isolate user and group rules to avoid masking the result. |

**Lockout precaution:** use a disposable lab host and a dedicated account. Keep an independent administrator recovery session **and out-of-band console access**. Preserve recovery users/groups explicitly when applying an allowlist, and never block them. Check account lockout thresholds. Do not use these experiments to change production access. The script does not automatically modify or restore Aqua policy.

After checking baseline identity, save/sync the policy and confirm before one fresh SSH validation login. SSH connection multiplexing is disabled so an existing authenticated session cannot bypass the new authentication decision. There are no automated retries, and each connection permits one password prompt. With a key file, public-key authentication is selected; otherwise SSH uses its configured authentication methods. SSH handles valid passwords/passphrases interactively; Aqua Probe does not collect or store them.

Run positive and negative cases separately with suitable accounts to compare allowed and denied access. SSH/identity-command failure alone is not proof of an Aqua denial: confirm host authentication logs and a matching host, identity, policy, and timestamp in **Security Reports -> Audit**. A successful allowed login might not produce an incident. Restore the original policy entries through recovery access afterward, including after cancellation. No accounts, groups, or other test artifacts are created; authentication/audit records remain.

Run `bash tests/test-host-os-users-groups.sh` for offline Linux/Windows, user/group, baseline-failure, cancellation, and input-validation checks. Live enforcement must still be validated on a monitored lab host.

### Windows Registry Monitoring and Protection

**Windows only. Both controls require Windows Aqua Enforcer and a Host Runtime Policy covering the Windows host. Linux Aqua Enforcer cannot validate these signatures.** Windows targets have separate SSH settings from the Linux controls; each Windows test prompts for its hostname/IP, port, Windows username, and optional local private key (`.pem` paths supported). A Windows identity preflight verifies the OS/account SID, not Aqua installation or policy health. Confirm connected Windows Aqua Enforcer coverage in Aqua before running.

Use an authorized Windows lab host with Windows PowerShell 5.1+ available as `powershell.exe`. Local Aqua Probe requires `ssh` and `python3`. An administrator must install/enable Windows OpenSSH Server and restrict SSH access to the authorized client, following [Microsoft's Windows OpenSSH setup guide](https://learn.microsoft.com/en-us/windows-server/administration/openssh/openssh_install_firstuse). A typical elevated PowerShell setup is:

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service -Name sshd -StartupType Automatic
```

Configure the host firewall and SSH account/key permissions according to that guide. Verify `ssh -l 'DOMAIN\user' windows-host` works before testing. Aqua Probe does not install SSH, change the firewall, elevate privileges, disable host-key verification, or change execution policy. PowerShell scripts travel through encrypted SSH stdin; a short [EncodedCommand launcher](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_powershell_exe?view=powershell-5.1) avoids shell quoting and Windows command-line length problems. It does not conceal the scripts from host auditing.

The workflow creates a unique, marked baseline at `HKCU:\Software\AquaProbeLab-<random-id>`, then prints the full policy path `HKEY_USERS\<SSH-account-SID>\Software\AquaProbeLab-<random-id>\Operations`. If your tenant expects a native registry path, its equivalent is `\REGISTRY\USER\<SID>\Software\AquaProbeLab-<random-id>\Operations`. Use your tenant's supported path/descendant matching format. The test never touches existing application or operating-system keys and never accepts an arbitrary registry path.

For **Monitoring (44)**, enable **Create, Read, Modify, Delete, Attributes** under Windows Registry Monitoring, add the printed path and descendants to **Monitored Paths**, and save/sync the Host Runtime Policy. This control is **Audit only**; keep Protection off for the test path. Each operation runs separately over SSH: create a child key/value, read the baseline value, modify it, change ACL inheritance while preserving existing permissions, and delete a disposable baseline child key. The ACL change is an attributes candidate; verify its classification in Aqua rather than assuming all versions report the same signature. These operations use the [PowerShell Registry provider](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_registry_provider?view=powershell-7.6).

For **Protection (45)**, create the baseline first while it is unprotected, then add the printed path and descendants to **Protected registry paths** in an enforcing Host Runtime Policy. Confirm policy sync before the create/modify/delete attempts. Review **Security Reports -> Audit**, filtered by Windows host, test time, policy, and registry path. An ACL denial, SSH failure, missing key, or successful PowerShell command alone does not prove Aqua behavior.

After Protection testing, remove **only this test path** from protection and wait for policy sync before confirming cleanup. Cleanup verifies the current account SID, exact random key path, and ownership marker before removing that key. If blocked or unreachable, state is retained in the current session for retry with main option **46** / host-only **16**; new Windows tests and termination are refused until cleanup succeeds. After forced process termination or loss of session state, use the printed path to inspect and remove only the owned lab key manually, after removing its protection. Audit records remain for review. Aqua policies are never modified automatically.

Run `bash tests/test-windows-registry.sh` for offline mocked workflow, transport, cleanup, and PowerShell syntax checks. Live Windows Aqua enforcement still requires validation on your Windows lab host.

The following host-specific controls remain catalog items without dedicated host test functions in this update:

- Bypass Scope
- System Integrity Monitoring

## Usage
The banner, control headings, menu, prompts, and status messages share [Aqua's website palette](https://www.aquasec.com/): electric blue and teal on deep navy. Teal highlights prompts and review guidance, yellow marks prerequisites and warnings, and magenta marks errors. Titles are centered, menu entries and prerequisites wrap to the terminal width, and menu groups distinguish workload controls from host controls with sequential main-menu numbering. Commands and external tool output remain plain and copyable. True-color terminals use the exact brand colors; other color terminals use standard ANSI equivalents. Set `NO_COLOR=1` for plain-text output; redirected output and `TERM=dumb` also omit color codes.

Run `bash tests/test-terminal-theme.sh` to check the terminal formatting without deploying resources or executing security tests.

Startup uses a themed **Environment Checks** section with numbered `CHECK`, `PASS`, and `FAIL` states. A pass is printed only after the relevant Kubernetes command succeeds; DaemonSet/deployment checks confirm resource existence, not workload readiness. Run `bash tests/test-startup-checks.sh` to validate these checks offline.

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
