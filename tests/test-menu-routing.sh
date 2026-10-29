#!/bin/bash
set -e
cd "$(dirname "$0")/.."
eval "$(sed '$d' aqua-probe.sh)"
export NO_COLOR=1
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
kubectl() { fail 'Unexpected cluster access'; }
docker() { fail 'Unexpected Docker access'; }
ssh() { fail 'Unexpected SSH access'; }
check_kubernetes_connection() { :; }
check_aqua_agent_daemonset() { :; }
check_aqua_kube_enforcer_deployment() { :; }
check_container_existence() { return 1; }
sleep() { :; }
print_main_menu() { :; }
expected=(
    deploy_test_container
    select_ssh_host
    test_bad_dns_ip_reputation
    test_block_container_exec
    test_block_cryptocurrency_mining
    test_block_fileless_execution
    test_block_non_compliant_images
    test_block_non_compliant_resources
    test_block_non_kubernetes_containers
    test_block_outdated_images
    test_reverse_shell
    test_block_unregistered_images
    test_capabilities_block
    test_drift_prevention
    test_executables_allowed
    test_executables_blocked
    test_file_block
    test_file_integrity_monitoring
    test_forensics
    test_limit_container_privileges
    test_limit_new_privileges
    test_package_block
    test_port_block
    test_port_scanning_detection
    test_realtime_malware_protection
    test_registries_allowed
    test_secure_ai_discovery
    test_secure_ai_protection
    test_secure_ai_unauthorized_models
    test_system_integrity_monitoring
    test_volumes_blocked
    test_host_cryptocurrency_mining
    test_brute_force_login_detection
    test_host_dns_ip_reputation
    test_host_file_block
    test_host_file_integrity_monitoring
    test_host_forensics
    test_host_os_users_groups_allowed
    test_host_os_users_groups_blocked
    test_host_package_block
    test_host_port_scanning_detection
    test_host_secure_ai_discovery
    test_host_secure_ai_unauthorized_models
    test_host_windows_registry_monitoring
    test_host_windows_registry_protection
    cleanup_windows_registry_test
    terminate_program
)
# Replace actions only, preserving the real main-menu dispatch logic.
for fn in "${expected[@]}"; do
    eval "$fn() { printf 'ACTION $fn\\n'; }"
done
input=$(printf '%s\n' {1..47})
output=$(main <<< "$input")
actual=$(printf '%s\n' "$output" | sed -n 's/^ACTION //p')
wanted=$(printf '%s\n' "${expected[@]}")
[[ "$actual" == "$wanted" ]] || fail 'Number-to-function mapping changed'
[[ "${expected[46]}" == terminate_program ]] || fail 'Terminate must be last'
printf 'PASS: all 47 menu actions route to their intended functions in order\n'
