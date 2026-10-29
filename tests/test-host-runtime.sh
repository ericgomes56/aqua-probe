#!/bin/bash
set -e
cd "$(dirname "$0")/.."
eval "$(sed '$d' aqua-probe.sh)"
export NO_COLOR=1 COLUMNS=80
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
kubectl() { fail 'Unexpected Kubernetes access'; }
docker() { fail 'Unexpected Docker access'; }

# Exercise real SSH argument quoting without opening a connection.
ssh() { printf '%s' "${!#}"; }
AQUA_PROBE_HOST=lab.example AQUA_PROBE_HOST_USER=tester AQUA_PROBE_HOST_PORT=22
AQUA_PROBE_HOST_AUTH=(-i '/tmp/key path.pem')
remote=$(host_ssh "printf '%s' \"literal ' quote and space\"")
[[ "$(bash -c "$remote")" == "literal ' quote and space" ]] || fail 'SSH quoting'

# Invalid targets and ports must never reach SSH. Valid preflight requires Linux.
ssh() { fail 'Invalid configuration reached SSH'; }
if configure_host_runtime <<< 'lab;id' >/dev/null; then fail 'Accepted injected host'; fi
if configure_host_runtime <<< $'lab\ntester\n0' >/dev/null; then fail 'Accepted invalid port'; fi
ssh() { printf 'Darwin\n'; }
if configure_host_runtime <<< $'lab\ntester\n22\n' >/dev/null; then fail 'Accepted non-Linux host'; fi
ssh() { printf 'Linux\n'; }
configure_host_runtime <<< $'lab\ntester\n22\n' >/dev/null || fail 'Linux preflight'
[[ "$AQUA_PROBE_HOST_READY" == 1 ]] || fail 'Host not retained'
AQUA_PROBE_SKIP_INSTRUCTIONS=1
if confirm_host_control 'File Block' 'Test' <<< no >/dev/null; then fail 'Skipped host confirmation'; fi
confirm_host_control 'File Block' 'Test' <<< yes >/dev/null || fail 'Confirmation'

# Capture scripts, never execute network or security-control commands.
confirm_host_control() { return 0; }
run_host_command() { PLAN=$1; bash -n <<< "$PLAN"; }
test_host_cryptocurrency_mining
[[ "$PLAN" == *'wget '* && "$PLAN" == *'http://crypto-loot.com'* && "$PLAN" == *'-O /dev/null'* ]] || fail 'Crypto signature'
test_host_dns_ip_reputation
[[ "$PLAN" == *'curl '* && "$PLAN" == *'http://68.183.212.246'* ]] || fail 'Reputation signature'
test_host_file_block
[[ "$PLAN" == 'cat /etc/passwd' ]] || fail 'File signature'
test_host_package_block
[[ "$PLAN" == tar ]] || fail 'Package signature'
test_host_forensics
[[ "$PLAN" == *'aqua-probe-forensics-marker'* && "$PLAN" == *'id; ls /tmp'* ]] || fail 'Forensics signature'
test_host_port_scanning_detection <<< '10.0.0.1' >/dev/null
[[ "$PLAN" == *'{1..1024}'* && "$PLAN" == *'p % 16'* && "$PLAN" == *'/dev/tcp/'* ]] || fail 'Bounded port scan'
if test_host_port_scanning_detection <<< 'host;id' >/dev/null; then fail 'Accepted injected scan target'; fi

# FIM executes only against its own new temporary files, including error cleanup.
test_host_file_integrity_monitoring
[[ "$PLAN" != *'/etc/sudoers'* && "$PLAN" == *'trap cleanup EXIT'* ]] || fail 'Unsafe FIM path/cleanup'
result=$(bash -c "$PLAN")
directory=${result#Owned FIM test directory: }
[[ "$directory" == /tmp/aqua-probe-host-fim-* && ! -e "$directory" ]] || fail 'FIM cleanup'
chmod() { return 1; }
export -f chmod
if result=$(bash -c "$PLAN"); then fail 'Expected simulated chmod failure'; fi
directory=${result#Owned FIM test directory: }
[[ ! -e "$directory" ]] || fail 'FIM error cleanup'
unset -f chmod

# Fake Python validates the transmitted program and secret transport, not HTTP.
python3() {
    [[ "$1" == -c && "$3" == gpt-4 ]] || return 1
    [[ "$2" != *'dummy-private-key'* ]] || return 1
    command python3 -c 'import ast, sys; ast.parse(sys.argv[1])' "$2" || return 1
    local secret
    IFS= read -r secret
    [[ "$secret" == dummy-private-key ]] || return 1
    printf 'MOCK_AI_OK\n'
}
export -f python3
host_ssh() { bash -c "$1"; }
for control in test_host_secure_ai_discovery test_host_secure_ai_unauthorized_models; do
    result=$($control <<< $'gpt-4\ndummy-private-key') || fail 'AI transport'
    [[ "$result" == *MOCK_AI_OK* && "$result" != *dummy-private-key* ]] || fail 'AI key exposure'
done
unset -f python3

# Every host option dispatches, and standalone mode avoids cluster startup/cleanup.
controls=(test_host_cryptocurrency_mining test_brute_force_login_detection test_host_dns_ip_reputation test_host_file_block test_host_file_integrity_monitoring test_host_forensics test_host_os_users_groups_allowed test_host_os_users_groups_blocked test_host_package_block test_host_port_scanning_detection test_host_secure_ai_discovery test_host_secure_ai_unauthorized_models)
for control in "${controls[@]}"; do
    eval "$control() { printf 'DISPATCH $control\\n'; }"
done
result=$(host_runtime_menu <<< $'1\n2\n3\n4\n5\n6\n7\n8\n9\n10\n11\n12\n0')
for control in "${controls[@]}"; do
    [[ "$result" == *"DISPATCH $control"* ]] || fail "Missing $control dispatch"
done
check_kubernetes_connection() { fail 'Host mode checked Kubernetes'; }
cleanup_aqua_probe_artifacts() { fail 'Host exit ran unrelated cleanup'; }
main --host-runtime <<< 0 >/dev/null

# Main menu dispatches host controls directly, without entering a submenu.
check_kubernetes_connection() { :; }
check_aqua_agent_daemonset() { :; }
check_aqua_kube_enforcer_deployment() { :; }
check_container_existence() { return 1; }
sleep() { :; }
configure_host_runtime() { printf 'DISPATCH configure_host_runtime\n'; }
host_runtime_menu() { fail 'Main menu entered the old host submenu'; }
result=$(main <<< $'2\n32\n33\n34\n35\n36\n37\n38\n39\n40\n41\n42\n43')
for control in "${controls[@]}" configure_host_runtime; do
    [[ "$result" == *"DISPATCH $control"* ]] || fail "Missing direct $control dispatch"
done
printf 'PASS: SSH quoting, validation, confirmation, nine shared controls, FIM cleanup, secret transport, direct menu and standalone mode\n'
