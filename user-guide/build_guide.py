"""Rebuild the user guide: python3 user-guide/build_guide.py (requires reportlab)."""

from pathlib import Path
from xml.sax.saxutils import escape

from reportlab.lib.colors import HexColor, white
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.utils import ImageReader
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph, Table, TableStyle


ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "user-guide/Aqua-Probe_Userguide.pdf"
ASSETS = ROOT / "user-guide/assets"
REPO = "https://github.com/ericgomes56/aqua-probe"
NAVY = HexColor("#002B49")
BLUE = HexColor("#0075FF")
TEAL = HexColor("#00BFAE")
INK = HexColor("#17354B")
MUTED = HexColor("#526979")
PALE = HexColor("#EFF7FA")
W, H = 612, 792
M = 48
WIDTH = W - 2 * M
C = canvas.Canvas(str(OUT), pagesize=(W, H), pageCompression=1)
C.setTitle("Aqua Probe | Runtime Security Validation User Guide")
C.setAuthor("Eric Gomes")
C.setSubject("Kubernetes and host runtime security validation in authorized labs")
PAGE = 0
Y = 0


def image(path, x, top, width):
    img = ImageReader(str(path))
    iw, ih = img.getSize()
    height = width * ih / iw
    C.drawImage(img, x, top - height, width, height, mask="auto")
    return height


def text(value, size=11, color=INK, width=WIDTH, x=M, gap=12, bold=False):
    global Y
    style = ParagraphStyle("body", fontName="Helvetica-Bold" if bold else "Helvetica",
                           fontSize=size, leading=size * 1.43, textColor=color)
    p = Paragraph(value, style)
    _, height = p.wrap(width, H)
    if Y - height < 58:
        raise ValueError(f"Page {PAGE} overflow: {value[:70]}")
    p.drawOn(C, x, Y - height)
    Y -= height + gap


def heading(value):
    text(value, 14, NAVY, gap=8, bold=True)


def note(title, body):
    heading(title)
    text(body, color=MUTED)


def code(value):
    global Y
    lines = value.splitlines()
    for line in lines:
        if C.stringWidth(line, "Courier", 9) > WIDTH - 24:
            raise ValueError(f"Code too wide: {line}")
    height = len(lines) * 14 + 24
    if Y - height < 58:
        raise ValueError(f"Code overflow on page {PAGE}")
    C.setFillColor(NAVY)
    C.rect(M, Y - height, WIDTH, height, fill=1, stroke=0)
    C.setFillColor(white)
    C.setFont("Courier", 9)
    for i, line in enumerate(lines):
        C.drawString(M + 12, Y - 20 - i * 14, line)
    Y -= height + 16


def table(headers, rows, widths):
    global Y
    style = ParagraphStyle("cell", fontName="Helvetica", fontSize=10,
                           leading=14, textColor=INK)
    hs = ParagraphStyle("header", parent=style, fontName="Helvetica-Bold", textColor=white)
    values = [[Paragraph(escape(v), hs) for v in headers]]
    values += [[Paragraph(v, style) for v in row] for row in rows]
    t = Table(values, colWidths=widths)
    t.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), NAVY),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [white, PALE]),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 10),
        ("RIGHTPADDING", (0, 0), (-1, -1), 10),
        ("TOPPADDING", (0, 0), (-1, -1), 8),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 8),
    ]))
    _, height = t.wrap(WIDTH, H)
    if Y - height < 58:
        raise ValueError(f"Table overflow on page {PAGE}: {height}")
    t.drawOn(C, M, Y - height)
    Y -= height + 16


def page(title, section):
    global PAGE, Y
    if PAGE:
        C.showPage()
    PAGE += 1
    C.bookmarkPage(f"page{PAGE}")
    C.addOutlineEntry(title, f"page{PAGE}", level=0)
    image(ASSETS / "Aquasec-logo-dark.png", M, 755, 104)
    C.setFont("Helvetica", 9)
    C.setFillColor(MUTED)
    C.drawRightString(W - M, 738, "AQUA PROBE / USER GUIDE")
    C.setStrokeColor(TEAL)
    C.setLineWidth(2)
    C.line(M, 721, W - M, 721)
    C.setFillColor(BLUE)
    C.setFont("Helvetica-Bold", 9)
    C.drawString(M, 694, section.upper())
    Y = 678
    text(title, 25, NAVY, gap=20, bold=True)
    C.setStrokeColor(HexColor("#DCE6EC"))
    C.setLineWidth(0.6)
    C.line(M, 42, W - M, 42)
    C.setFont("Helvetica", 8)
    C.setFillColor(MUTED)
    C.drawString(M, 27, "Aqua Probe  /  November 2, 2026")
    C.drawRightString(W - M, 27, f"{PAGE:02d}")


page("Aqua Probe", "Runtime security validation")
C.setFillColor(NAVY)
C.rect(0, 0, W, H, fill=1, stroke=0)
image(ASSETS / "Aquasec-logo-white.png", M, 735, 190)
C.setFillColor(TEAL)
C.setFont("Helvetica-Bold", 11)
C.drawString(M, 635, "RUNTIME SECURITY VALIDATION")
Y = 596
text("Aqua Probe", 48, white, bold=True, gap=15)
text("User Guide", 28, white, gap=25)
text("The Aqua Security Runtime Input Validator Tool", 17, white, width=440)
text("Kubernetes workloads and Linux or Windows hosts.<br/>Guided testing for workshops, Compass classes, demos, and proofs of value.", 13,
     HexColor("#B6CEDD"), width=440)
image(ROOT / "misc/aqua_probe_1x1.png", 382, 292, 182)
Y = 202
text("Eric Gomes", 14, white, width=310, bold=True, gap=5)
text("Senior DevSecOps Architect @ Aqua Security", 10, white, width=310)
text("Updated November 2, 2026", 10, HexColor("#B6CEDD"), width=310)
C.setFillColor(TEAL)
C.rect(M, 69, 70, 3, fill=1, stroke=0)
C.setFillColor(white)
C.setFont("Helvetica", 8)
C.drawString(M, 45, "Maintained fork. Use only in authorized, disposable lab environments.")

page("A guide to repeatable validation", "01 / Orientation")
text("Aqua Probe connects policy setup, runtime activity, and evidence review. Use the interactive CLI to select a control, prepare its policy, exercise a signature, and inspect the result in Aqua.")
text("The operator configures policies. The script does not automatically create or restore Aqua policies, and this repository does not establish official Aqua product support.")
table(["In this guide", "Page"], [
    [f'<link href="#page{n}" color="#0075FF">{label}</link>', str(n)]
    for label, n in [("Safety and scope", 3), ("Installation and first run", 4),
                     ("Current terminal menu", 5), ("Container and workload controls", 6),
                     ("Test activity and evidence", 7), ("SSH host setup", 8),
                     ("Host controls and authentication", 9), ("Windows registry workflows", 10),
                     ("Secure AI", 11), ("CLI and image configuration", 12),
                     ("Cleanup and troubleshooting", 13), ("References and maintenance", 14)]
], [454, 62])

page("Safety and scope", "02 / Before you begin")
heading("A disposable lab is required")
text("Tests execute real commands and create real resources. They can deploy privileged pods, create cluster-scoped RBAC, contact external destinations, scan ports, and generate failed logins. These actions may trigger detections or affect the environment.")
heading("Reserve aqua-probe-lab exclusively")
text("Kubernetes test workloads use <b>aqua-probe-lab</b>. The namespace does not isolate cluster-scoped tests. Main-menu termination deletes the entire namespace and named cluster roles/bindings. Do not share those names with unrelated resources.")
heading("Treat high-impact tests separately")
text("Container File Integrity Monitoring changes permissions and deletes <b>/etc/sudoers</b> inside the disposable test container. System Integrity Monitoring attempts to set the clock to 10:00:00. With sufficient privileges, a clock change can affect the host. Never use production targets.")
heading("Keep recovery access")
text("For authentication-policy tests, retain an independent administrator session and out-of-band console access. Use a dedicated account and check lockout thresholds. Restore policy changes manually after testing or cancellation.")
heading("Distinguish policy scopes")
text("Container controls apply to workloads. Host Runtime Policies apply to native host activity. Windows registry tests require Windows Aqua Enforcer. Shared commands can exercise similar signatures, but they do not make these scopes interchangeable.")
note("Evidence, not assumptions", "A command failure alone does not prove an Aqua block. Check target, policy, time, and event details. Audit records remain after cleanup.")

page("Installation and first run", "03 / Quick start")
heading("Local requirements")
text("Use Bash and Git. Kubernetes workflows also need a configured kubectl context, registry access, and permissions for the selected tests and cleanup. Confirm the Aqua Enforcer DaemonSet and aqua-kube-enforcer deployment are present.")
code("git clone https://github.com/ericgomes56/aqua-probe.git\ncd aqua-probe\nchmod +x aqua-probe.sh\n./aqua-probe.sh --help")
heading("Kubernetes workflow")
code("kubectl config current-context\n./aqua-probe.sh")
text("Confirm the context points to your lab. Startup checks Kubernetes connectivity and resource existence, not Enforcer readiness or policy health. Choose <b>1. Deploy/Redeploy test container</b>, then a control.")
heading("Host-only workflow")
code("./aqua-probe.sh --host-runtime")
text("This mode skips Kubernetes startup checks. Select/change SSH host, choose the OS, and provide the connection details. Each host test still requires confirmation.")
note("Default test image", "ericgomes56/aqua-probe:2.0. Custom images must provide the tools required by the control. Read prerequisites before running a test.")

page("Security controls menu", "04 / Interface")
# Preserve the full screenshot and its aspect ratio, including all 47 options.
image(ROOT / "misc/aqua-probe-advanced-commands.png", 146, Y, 320)
C.setFont("Helvetica", 8)
C.setFillColor(MUTED)
C.drawString(M, 62, "Captured November 2, 2026. Main-menu numbering differs from host-only mode.")

page("Container and workload controls", "05 / Coverage")
text("The main menu groups workload tests separately from host controls. Prepare the specific Runtime or Assurance Policy requested by each test.", gap=14)
table(["Main menu", "Controls"], [
    ["3-9", "Bad DNS/IP Reputation; Block Container Exec; Block Cryptocurrency Mining; Block Fileless Execution; Block Non-compliant Images; Block Non-compliant Resources; Block Non-Kubernetes Containers"],
    ["10-16", "Block Outdated Images; Block Reverse Shell; Block Unregistered Images; Capabilities Block; Drift Prevention; Executables Allowed; Executables Blocked"],
    ["17-24", "File Block; File Integrity Monitoring; Forensics; Limit Container Privileges; Limit New Privileges; Package Block; Port Block; Port Scanning Detection"],
    ["25-31", "Real-time Malware Protection; Registries Allowed; Secure AI - Discovery; Secure AI - Protection; Secure AI - Unauthorized Models; System Integrity Monitoring; Volumes Blocked"],
], [92, 424])
note("Admission and assurance tests", "For non-compliant images, configure malware checks in the Assurance Policy. For unregistered images, block unregistered images and disable automatic registration of running containers/discovered pod images as applicable. Follow the script's exact prompts.")
note("Coverage boundaries", "Limit Container Privileges automates seven Linux pod cases. Host UTS and Windows low-port cases remain manual. Capabilities Block uses CHOWN as its focused test. A default image is not guaranteed to trigger outdated-image or registry restrictions.")
text(f'<link href="{REPO}/blob/main/docs/control-reference.md" color="#0075FF">Full control reference and policy instructions</link>', 10)

page("Test activity and evidence", "06 / Validation")
text("The script displays test activity and executes it against the selected workload. Use the menu so namespace and container targeting follow the current implementation.")
table(["Control", "Activity", "What to verify"], [
    ["Drift Prevention", "Copy /bin/wget to /tmp/wget_copy, then run the copy against google.com.", "New executable activity and matching Aqua evidence."],
    ["Cryptocurrency Mining", "wget http://crypto-loot.com", "Reputation/signature event for the expected target."],
    ["DNS/IP Reputation", "curl http://68.183.212.246", "Network event matched to policy and time."],
    ["File Block", "cat /etc/passwd", "A denial attributable to the configured file rule."],
    ["Package Block", "tar", "Aqua evidence, not tar's ordinary missing-arguments error."],
    ["Forensics", "Separate echo, id, and ls operations.", "Collected process/argument activity. A block is not required."],
], [108, 218, 190])
heading("Review in Aqua")
text("Open <b>Security Reports -&gt; Audit</b> and match the target, policy, timestamp, and command/resource. Use the relevant forensic or AI view for collection/discovery tests. Save sanitized output and the corresponding event for the workshop record.")
note("Do not misclassify infrastructure errors", "Missing binaries, container-not-found errors, image-pull failures, Kubernetes admission denials, and SSH failures are not proof of Aqua enforcement.")

page("SSH host setup", "07 / Host runtime")
heading("Select the target OS")
text("Main option <b>2</b> or host-only option <b>13</b> selects/changes the SSH host. Enter Linux or Windows, hostname/IP, username, port, and an optional local private-key path such as ~/.ssh/test.pem. Enter paths without surrounding quotes.")
text("Linux and Windows connections are retained separately for the current session. Controls reuse the required OS connection or prompt for one. SSH host-key verification remains enabled. The script does not automatically install packages, elevate privileges, or enable SSH.")
table(["Target", "Requirements"], [
    ["Linux", "Linux Aqua Enforcer, Bash, SSH, and utilities used by the chosen test. Host Secure AI also requires native Python 3 and outbound HTTPS."],
    ["Windows", "Windows Aqua Enforcer, Windows OpenSSH Server, and Windows PowerShell 5.1+ available as powershell.exe. Registry tests also require local ssh and python3."],
], [100, 416])
heading("Platform support")
text("The host selector lists Windows Server 2019, Server 2022, and Server 2025. Consult official Aqua system requirements documentation for the updated Windows support list and supported Linux distributions/versions. This prompt is informational, not an OS-version compatibility check.")
heading("Policy and credentials")
text("Scope the Host Runtime Policy to the selected host and confirm connected Enforcer coverage in Aqua. Authentication tests require dedicated test-account credentials rather than silently reusing the administrator identity.")
note("Exit behavior", "Host-only option 0 exits without unrelated Kubernetes/Docker cleanup, but retries pending Windows registry cleanup. Main-menu option 47 performs broader cleanup.")

page("Host controls and authentication", "08 / Host runtime")
table(["Main menu", "Controls"], [
    ["32-37", "Cryptocurrency Mining; Brute Force Login Detection; DNS/IP Reputation; File Block; File Integrity Monitoring; Forensics"],
    ["38-43", "OS Users and Groups Allowed; OS Users and Groups Blocked; Package Block; Port Scanning Detection; Secure AI - Discovery; Secure AI - Unauthorized Models"],
    ["44-45", "Windows Registry Monitoring; Windows Registry Protection"],
], [92, 424])
heading("Brute Force Login Detection")
text("Use a disposable account and a Host Runtime Policy. The default is five attempts, with a maximum of ten. For password tests, intentionally enter an incorrect password through SSH. An optional key selects public-key authentication. A valid authorized key succeeds and stops the test, so it does not generate failures.")
heading("OS Users and Groups Allowed / Blocked")
text("Use valid credentials. First establish a successful baseline login and verify identity/group membership. Then apply the allow/block policy and confirm one fresh SSH login. The workflow supports Linux or Windows with the matching Enforcer. It does not create users/groups or test RDP/console sign-in.")
heading("Disposable host activity")
text("Host FIM creates, modifies, changes permissions on, and deletes files under an owned /tmp/aqua-probe-host-fim-* directory. It never edits real /etc/sudoers. Port scanning targets an explicitly authorized destination, with at most 16 concurrent one-second probes across ports 1-1024.")
note("Evidence and recovery", "Confirm host authentication logs and matching Aqua events. Keep recovery access, restore policy entries manually, and inspect printed owned paths if cleanup is interrupted. Bypass Scope and host System Integrity Monitoring have no dedicated host test functions.")

page("Windows registry workflows", "09 / Windows only")
text("Both tests require <b>Windows Aqua Enforcer</b> and a Host Runtime Policy. Linux Enforcer cannot validate these signatures. The SSH preflight confirms OS/account identity, not Aqua installation or policy health.")
heading("1. Establish the disposable baseline")
text("The workflow creates a unique, marked key at HKCU:\\Software\\AquaProbeLab-&lt;random-id&gt;. It prints the full policy path under HKEY_USERS\\&lt;SSH-account-SID&gt; and its Operations subkey. Use the printed path and your tenant's descendant-matching syntax, not an existing OS/application registry path.")
heading("2. Monitoring: main menu 44")
text("Enable <b>Create, Read, Modify, Delete, Attributes</b>, add the printed path and descendants to Monitored Paths, and sync the policy. Monitoring is audit only. Keep Protection off for the test path. Operations run separately over SSH. The ACL change is an attributes candidate whose event classification must be checked in Aqua.")
heading("3. Protection: main menu 45")
text("Create the baseline while unprotected. Add the printed path and descendants to Protected registry paths in an enforcing policy, then sync before the create/modify/delete attempts. Review Aqua evidence. An ACL error or successful command alone does not prove protection behavior.")
heading("4. Remove protection and clean up")
text("Remove only the test path from protection, wait for policy sync, then confirm cleanup. The script checks the account SID, random path, and ownership marker before deletion. Failed cleanup retains session state and blocks new Windows tests and termination until resolved.")
note("Explicit cleanup", "Use main option 46 or host-only option 16 to retry. After forced termination or lost state, inspect and remove only the printed owned key manually after removing protection. Audit records remain.")

page("Secure AI workflows", "10 / AI validation")
heading("Container application: main menu 27-29")
text("The sample application uses <b>ericgomes56/ai-app:1.0</b>. Supply your own OpenAI API key at the hidden prompt. The deployment receives it through a Kubernetes Secret. Restrict access to the Secret and LoadBalancer endpoint, and never commit keys.")
text("Open the exact URL printed from the created Service using <b>HTTP on port 8501</b>. If the LoadBalancer is pending, inspect mars-banking-app-lb in aqua-probe-lab and use its assigned hostname/IP. Subsequent Unauthorized Models and Protection tests can reuse the existing app until cleanup.")
table(["Test", "Policy and application steps"], [
    ["Discovery", "Enable discovery for the environment. In the app, open Request Simulator at the bottom right, choose OpenAI, and send a request. Review AI Findings and relevant audit events."],
    ["Unauthorized Models", "Select OpenAI as Service and gpt-4 as Model Name (OpenAI@gpt-4). In Request Simulator, choose OpenAI and model override gpt-4, then send a request."],
    ["Protection", "Aqua SaaS tenants only, not on-prem. Enable Prompt Protection Settings under Administration &gt; Integrations &gt; Secure AI. Open Attack Library and choose an example."],
], [124, 392])
heading("Host AI: main menu 42-43")
text("Host tests send one native Python 3 HTTPS request over SSH, without deploying the sample container app. Enter a fresh key for each request. Match the selected available model to the policy. Confirm tenant/Enforcer feature coverage and model access.")
note("Result interpretation", "Requests may incur provider charges. API authentication, billing, connectivity, and unavailable-model errors do not establish an Aqua finding or denial.")

page("CLI and image configuration", "11 / Reference")
table(["Option", "Behavior"], [
    ["--help / -h", "Print help and exit before Kubernetes checks."],
    ["--host-runtime", "Use the host-only interface without Kubernetes startup checks."],
    ["--image / -i", "Default test image: ericgomes56/aqua-probe:2.0. Use a pullable custom reference where supported."],
    ["--namespace / -ns", "Aqua Enforcer namespace, default aqua. This does not change the test namespace aqua-probe-lab."],
    ["--daemonset / -ds", "Custom Enforcer DaemonSet name. Built-in names are checked first."],
    ["--no-instructions / -n", "Skip supported container prerequisites only. Host and other guarded workflows still require confirmation."],
    ["--version / -v", "Print the embedded build date, then continue startup. This is not an exit-only command."],
    ["NO_COLOR=1", "Disable colors. Redirected output and TERM=dumb also omit color codes."],
], [156, 360])
heading("Image exceptions and architecture")
text("The non-compliant-image test uses <b>jerbi/eicar:latest</b>. Secure AI uses <b>ericgomes56/ai-app:1.0</b>. Other deployment prompts can use custom images. Generated workloads specify imagePullPolicy: Always.")
text("Build images for the Kubernetes worker architecture, not merely the operator's Mac or Linux workstation. Read Dockerfile/README.md for AMD64/ARM64 paths and security caveats. The current build uses legacy CentOS/Go and disables some certificate checks.")

page("Cleanup and troubleshooting", "12 / Session close")
heading("Main menu: 47. Terminate Program")
text("Termination retries pending Windows registry cleanup, then removes known Kubernetes test artifacts, named cluster roles/bindings, and the entire aqua-probe-lab namespace. It also removes the local Docker test container when Docker is available. Some deletion is asynchronous, so verify completion.")
text("Run Docker-only tests on the intended worker with access to its Docker runtime. A container started elsewhere needs cleanup on that runtime. Neither Kubernetes access nor the namespace contains all host-level effects.")
table(["Symptom", "Check before attributing it to Aqua"], [
    ["Container not found", "Current pod and container names, namespace, rollout status, and container state."],
    ["Image will not start", "Registry credentials, pullability, image architecture, admission decisions, and required commands."],
    ["No expected incident", "Correct policy scope/mode, sync, feature coverage, trigger conditions, and event time filters."],
    ["SSH failure", "Host key, route, port, credentials, OpenSSH configuration, and account lockout."],
    ["Cleanup blocked", "Remove protection from only the owned test path, restore access, and retry. Inspect leftovers after interruption."],
], [150, 366])
heading("Close the workshop")
text("Restore policy changes manually. Confirm lab resources and owned host/registry files are gone. Keep sanitized evidence and audit records. Do not assume every successful command produces an incident or that every failure is enforcement.")

page("References and maintenance", "13 / Resources")
heading("Current project documentation")
for label, suffix in [
    ("Repository and quick start", ""),
    ("Control reference and detailed host instructions", "/blob/main/docs/control-reference.md"),
    ("Image build and architecture guide", "/blob/main/Dockerfile/README.md"),
    ("Current terminal walkthrough", "#see-aqua-probe-in-action"),
    ("Source script", "/blob/main/aqua-probe.sh"),
    ("Offline test suites", "/tree/main/tests"),
]:
    text(f'<link href="{REPO}{suffix}" color="#0075FF">{label}</link>', gap=12)
heading("Validation and support")
text("Offline tests use mocks and do not establish live Aqua enforcement. Validate the selected control in a monitored, authorized lab. Report issues with the control name, platform, policy mode, expected outcome, and sanitized output. Use your organization's normal Aqua support channel for platform issues.")
heading("Guide maintenance")
text("This guide reflects the repository reviewed on November 2, 2026. Menu numbers and platform coverage may change. Follow current script prompts and official Aqua system requirements for your deployment. The reproducible PDF source and supplied logo assets live in user-guide/.")
heading("Project attribution")
text("Aqua Probe is a maintained fork and evolution of Aqua Warden. The project has been rebranded and is actively developed to support Aqua runtime security testing, PoVs, and technical enablement.")
text("Tool developed by Eric Gomes, Senior DevSecOps Architect @ Aqua Security. No repository license file is currently included. Clarify licensing with the maintainer before reuse or redistribution.", 10, MUTED)
C.save()
print(f"Built {OUT} ({PAGE} pages)")
