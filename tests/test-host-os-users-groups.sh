#!/bin/bash
set -e
cd "$(dirname "$0")/.."
eval "$(sed '$d' aqua-probe.sh)"
export NO_COLOR=1
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
kubectl() { fail 'Unexpected cluster access'; }
docker() { fail 'Unexpected Docker access'; }
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
ssh() {
    [[ "$*" == *ControlMaster=no* && "$*" == *ControlPath=none* ]] || fail 'Connection reuse allowed'
    [[ "$*" == *NumberOfPasswordPrompts=1* && "$*" == *ConnectionAttempts=1* ]] || fail 'Unbounded authentication'
    [[ "$*" != *StrictHostKeyChecking=no* ]] || fail 'Host-key validation bypassed'
    [[ "${!#}" == id || "${!#}" == 'whoami.exe /all' ]] || fail 'Unexpected identity command'
    printf '%s\n' "${!#}" >> "$work/calls"
    if [[ "${FAIL_BASELINE:-0}" == 1 ]]; then return 255; fi
    if [[ "${DENY_SECOND:-0}" == 1 && "$(wc -l < "$work/calls" | tr -d ' ')" == 2 ]]; then return 255; fi
    printf 'MOCK_IDENTITY_AND_GROUPS\n'
}
for mode in allowed blocked; do
    : > "$work/calls"
    DENY_SECOND=1
    "test_host_os_users_groups_$mode" <<< $'linux\nlab\ntester\n22\n\nuser\ndeny\nyes\nyes' > "$work/output"
    [[ "$(wc -l < "$work/calls" | tr -d ' ')" == 2 ]] || fail 'Expected baseline and validation only'
    grep -F 'Expected: deny | SSH/identity command exit status: 255' "$work/output" >/dev/null || fail 'Denial status not reported'
    grep -F 'Restore the original policy entries' "$work/output" >/dev/null || fail 'Missing rollback instruction'
    : > "$work/calls"
    DENY_SECOND=0
    "test_host_os_users_groups_$mode" <<< $'windows\nwinlab\nDOMAIN\\tester\n22\n\ngroup\nDOMAIN\\Test Users\nallow\nyes\nyes' > "$work/output"
    [[ "$(grep -c 'whoami.exe /all' "$work/calls")" == 2 ]] || fail 'Windows identity probe'
    grep -F 'Expected: allow | SSH/identity command exit status: 0' "$work/output" >/dev/null || fail 'Allowed status not reported'
done
: > "$work/calls"
FAIL_BASELINE=1
if test_host_os_users_groups_allowed <<< $'linux\nlab\ntester\n22\n\nuser\ndeny\nyes\nyes' > "$work/output"; then fail 'Failed baseline continued'; fi
[[ "$(wc -l < "$work/calls" | tr -d ' ')" == 1 ]] || fail 'Probe after failed baseline'
! grep -F 'VALIDATION |' "$work/output" >/dev/null || fail 'Validation after failed baseline'
FAIL_BASELINE=0
: > "$work/calls"
AQUA_PROBE_SKIP_INSTRUCTIONS=1
test_host_os_users_groups_allowed <<< $'linux\nlab\ntester\n22\n\nuser\ndeny\nno' >/dev/null
[[ ! -s "$work/calls" ]] || fail 'Confirmation bypassed'
test_host_os_users_groups_blocked <<< $'linux\nlab\ntester\n22\n\nuser\ndeny\nyes\nno' > "$work/output"
[[ "$(wc -l < "$work/calls" | tr -d ' ')" == 1 ]] || fail 'Cancelled policy probe ran'
grep -F 'Restore the original policy entries' "$work/output" >/dev/null || fail 'Cancelled run lacks rollback reminder'
: > "$work/calls"
for input in $'linux\nhost;id' $'linux\nlab\nbad;user' $'windows\nlab\ntester\n65536' $'linux\nlab\ntester\n22\n/nonexistent/aqua-key.pem'; do
    if test_host_os_users_groups_allowed <<< "$input" >/dev/null; then fail 'Invalid input accepted'; fi
done
[[ ! -s "$work/calls" ]] || fail 'Invalid input reached SSH'
# Key paths with spaces remain a single argument, and never become remote shell input.
ssh() {
    local arg previous=''
    for arg in "$@"; do
        if [[ "$previous" == -i ]]; then [[ "$arg" == '/tmp/key with spaces.pem' ]] || return 1; fi
        previous=$arg
    done
    [[ "$*" == *PreferredAuthentications=publickey* && "${!#}" == id ]]
}
host_os_identity_probe linux lab tester 22 '/tmp/key with spaces.pem' || fail 'Key argument handling'
printf 'PASS: Linux/Windows user/group logins, baseline gating, valid-credential probes, confirmation, validation and key handling\n'
