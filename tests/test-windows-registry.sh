#!/bin/bash
set -e
cd "$(dirname "$0")/.."
eval "$(sed '$d' aqua-probe.sh)"
export NO_COLOR=1 COLUMNS=80
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
kubectl() { fail 'Unexpected Kubernetes access'; }
docker() { fail 'Unexpected Docker access'; }
host_ssh() { fail 'Windows test used Linux Bash transport'; }
ssh() {
    local launcher="${!#}" encoded payload
    [[ "$launcher" == 'powershell.exe -NoLogo -NoProfile -NonInteractive -EncodedCommand '* ]] || return 1
    [[ "$*" != *StrictHostKeyChecking=no* && "$*" != *ExecutionPolicy* ]] || return 1
    encoded=${launcher##* }
    printf '%s' "$encoded" | python3 -c 'import sys,base64; s=base64.b64decode(sys.stdin.read()).decode("utf-16le"); assert "ReadToEnd" in s and "exit 1" in s' || return 1
    payload=$(cat)
    [[ "$payload" == *'WindowsIdentity'* ]] || return 1
    printf 'S-1-5-21-1-2-3-1001\r\n'
}
configure_windows_registry_host <<< $'winlab\nDOMAIN\\tester\n22\n' >/dev/null || fail 'Domain username / Windows transport'
[[ "$AQUA_PROBE_WINDOWS_SID" == S-1-5-21-1-2-3-1001 ]] || fail 'SID parsing'
if configure_windows_registry_host <<< 'host;id' >/dev/null; then fail 'Host injection accepted'; fi
if configure_windows_registry_host <<< $'winlab\ntester\n0' >/dev/null; then fail 'Invalid port accepted'; fi
saved_configure=$(declare -f configure_windows_registry_host)
if command -v pwsh >/dev/null; then
    # Run the actual launcher locally with harmless input, not registry operations.
    saved_ssh=$(declare -f ssh)
    ssh() {
        local launcher="${!#}"
        command pwsh -NoLogo -NoProfile -NonInteractive -EncodedCommand "${launcher##* }"
    }
    [[ "$(windows_powershell 'Write-Output "BOOTSTRAP_OK"')" == BOOTSTRAP_OK ]] || fail 'PowerShell stdin launcher'
    if windows_powershell 'throw "expected offline failure"' >/dev/null 2>&1; then fail 'PowerShell error propagation'; fi
    eval "$saved_ssh"
fi
AQUA_PROBE_WINDOWS_RUN_ID=0123456789abcdef0123456789abcdef

for phase in prepare create read modify attributes delete cleanup; do
    script=$(windows_registry_script "$phase") || fail 'Payload generation'
    [[ "$script" == *'HKCU:\Software\AquaProbeLab-'* && "$script" == *'Ownership marker mismatch'* && "$script" == *'SSH account SID changed'* ]] || fail 'Missing ownership guard'
    [[ "$script" != *'HKLM:'* && "$script" != *ExecutionPolicy* ]] || fail 'Unsafe target or bypass'
    if command -v pwsh >/dev/null; then
        printf '%s' "$script" | pwsh -NoLogo -NoProfile -NonInteractive -Command '$src=[Console]::In.ReadToEnd(); $t=$null; $e=$null; [System.Management.Automation.Language.Parser]::ParseInput($src,[ref]$t,[ref]$e) | Out-Null; if ($e.Count) { $e | Out-String | Write-Error; exit 1 }' || fail 'PowerShell parse'
    fi
done
if windows_registry_script 'cleanup;id' >/dev/null; then fail 'Invalid phase accepted'; fi
AQUA_PROBE_WINDOWS_RUN_ID='bad-token'
if windows_registry_script cleanup >/dev/null; then fail 'Invalid ownership token accepted'; fi
unset AQUA_PROBE_WINDOWS_RUN_ID

# Exercise complete workflows with mocked PowerShell, never a remote registry.
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
configure_windows_registry_host() {
    AQUA_PROBE_WINDOWS_SID=S-1-5-21-1-2-3-1001
    AQUA_PROBE_WINDOWS_HOST=winlab
}
windows_powershell() {
    local first="${1%%$'\n'*}"
    printf '%s\n' "$first" >> "$work/operations"
    if [[ "$first" == "\$phase = 'cleanup'" && "${DENY_CLEANUP:-0}" == 1 ]]; then return 1; fi
    return 0
}
test_host_windows_registry_monitoring <<< $'yes\nyes' > "$work/output"
[[ -z "${AQUA_PROBE_WINDOWS_RUN_ID:-}" ]] || fail 'Monitoring left pending state'
expected=$(printf "\$phase = '%s'\n" prepare create read modify attributes delete cleanup)
[[ "$(cat "$work/operations")" == "$expected" ]] || fail 'Monitoring operation sequence'
grep -F 'HKEY_USERS\S-1-5-21-1-2-3-1001\Software\AquaProbeLab-' "$work/output" >/dev/null || fail 'Policy path interpolation'

: > "$work/operations"
if test_host_windows_registry_protection <<< $'yes\nyes\nno' > "$work/output"; then fail 'Cleanup deferral ignored'; fi
[[ -n "${AQUA_PROBE_WINDOWS_RUN_ID:-}" ]] || fail 'Pending state lost'
expected=$(printf "\$phase = '%s'\n" prepare create modify delete)
[[ "$(cat "$work/operations")" == "$expected" ]] || fail 'Protection operation sequence'
eval "$saved_configure"
if configure_windows_registry_host <<< 'other-host' >/dev/null; then fail 'Changed target with pending cleanup'; fi
DENY_CLEANUP=1
if cleanup_windows_registry_test >/dev/null; then fail 'Denied cleanup reported success'; fi
[[ -n "$AQUA_PROBE_WINDOWS_RUN_ID" ]] || fail 'Failed cleanup lost ownership'
cleanup_aqua_probe_artifacts() { fail 'Termination continued with pending Windows artifacts'; }
if terminate_program <<< y >/dev/null; then fail 'Termination ignored pending cleanup'; fi
DENY_CLEANUP=0
cleanup_windows_registry_test >/dev/null
[[ -z "${AQUA_PROBE_WINDOWS_RUN_ID:-}" ]] || fail 'Cleanup retry did not clear state'
if ! command -v pwsh >/dev/null; then printf 'SKIP: PowerShell parser unavailable\n'; fi
printf 'PASS: Windows transport, identity validation, payloads, monitoring/protection workflows, ownership and cleanup retry\n'
