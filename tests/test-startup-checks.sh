#!/bin/bash
set -e
cd "$(dirname "$0")/.."
eval "$(sed '$d' aqua-probe.sh)"
export NO_COLOR=1 COLUMNS=80
AQUA_PROBE_NAMESPACE=aqua
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
sleep() { fail 'Startup checks must not insert artificial delays'; }
kubectl() {
    case "$1" in
        cluster-info) [[ "$MODE" == cluster ]] ;;
        get)
            [[ "$3" == -n && "$4" == aqua ]] || return 1
            case "$2" in
                daemonset) [[ "$MODE" == daemonset && "${5:-}" == "$FOUND_NAME" ]] ;;
                deployment) [[ "$MODE" == deployment && "${5:-}" == aqua-kube-enforcer ]] ;;
                *) return 1 ;;
            esac ;;
        *) return 1 ;;
    esac
}
MODE=cluster
result=$(check_kubernetes_connection)
[[ "$result" == *'[CHECK] 01 / 03'* && "$result" == *'[PASS]  01 / 03'* ]] || fail 'Cluster success'
MODE=daemonset
AQUA_PROBE_DAEMONSET=custom-enforcer
for FOUND_NAME in aqua-agent aqua-enforcer-ds kube-enforcer-ds custom-enforcer; do
    result=$(check_aqua_agent_daemonset)
    [[ "$result" == *'[PASS]  02 / 03'* && "$result" == *"Found DaemonSet: $FOUND_NAME"* ]] || fail 'DaemonSet fallback'
done
MODE=deployment
result=$(check_aqua_kube_enforcer_deployment)
[[ "$result" == *'[PASS]  03 / 03'* ]] || fail 'Deployment success'
MODE=missing
unset AQUA_PROBE_DAEMONSET
for check in check_kubernetes_connection check_aqua_agent_daemonset check_aqua_kube_enforcer_deployment; do
    if result=$($check); then fail 'Missing resource passed'; fi
    [[ "$result" == *'[FAIL]'* && "$result" != *'[PASS]'* && "$result" != *$'\033'* ]] || fail 'Misleading failure output'
done
printf 'PASS: startup success/failure states, DaemonSet fallbacks, no fake success or delays\n'
