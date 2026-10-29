#!/bin/bash
set -e
cd "$(dirname "$0")/.."
eval "$(sed '$d' aqua-probe.sh)"
export NO_COLOR=1
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
ssh() { fail 'Selector tests must not contact a host'; }
configure_host_runtime() {
    AQUA_PROBE_HOST=linux-lab AQUA_PROBE_HOST_USER=linux-admin AQUA_PROBE_HOST_PORT=2222
    AQUA_PROBE_HOST_READY=1
}
configure_windows_registry_host() {
    AQUA_PROBE_WINDOWS_HOST=windows-lab AQUA_PROBE_WINDOWS_USER=windows-admin AQUA_PROBE_WINDOWS_PORT=2223
    AQUA_PROBE_WINDOWS_SID=S-1-5-21-1-2-3-1001 AQUA_PROBE_WINDOWS_READY=1
}
select_ssh_host <<< linux >/dev/null
[[ "$AQUA_PROBE_SELECTED_HOST_OS" == linux && "$AQUA_PROBE_HOST_READY" == 1 ]] || fail 'Linux selection'
select_ssh_host <<< windows >/dev/null
[[ "$AQUA_PROBE_SELECTED_HOST_OS" == windows && "$AQUA_PROBE_WINDOWS_READY" == 1 && "$AQUA_PROBE_HOST" == linux-lab ]] || fail 'Separate OS connections'
if select_ssh_host <<< invalid >/dev/null; then fail 'Invalid OS accepted'; fi
[[ "$AQUA_PROBE_SELECTED_HOST_OS" == windows ]] || fail 'Invalid choice replaced selection'
configure_host_runtime() { fail 'Linux cache was not reused'; }
configure_windows_registry_host() { fail 'Windows cache was not reused'; }
confirm_host_control 'File Block' 'Offline test' <<< yes >/dev/null || fail 'Linux control reuse'
test_host_windows_registry_monitoring <<< no >/dev/null || fail 'Windows control reuse'
result=$(test_host_os_users_groups_allowed <<< $'\n\nprobe\n\n\nuser\nallow\nno')
[[ "$result" == *'probe@windows-lab:2223 | windows'* ]] || fail 'Windows authentication target defaults'
result=$(test_host_os_users_groups_blocked <<< $'linux\n\nprobe\n\n\nuser\ndeny\nno')
[[ "$result" == *'probe@linux-lab:2222 | linux'* ]] || fail 'Linux authentication target defaults'
if test_host_os_users_groups_allowed <<< $'\n\n\n' >/dev/null; then fail 'Admin account silently reused'; fi
configure_host_runtime() { return 1; }
if select_ssh_host <<< linux >/dev/null; then fail 'Failed configuration accepted'; fi
[[ "$AQUA_PROBE_SELECTED_HOST_OS" == windows ]] || fail 'Failed configuration changed selection'
printf 'PASS: shared selector, separate OS caches, control reuse and dedicated authentication accounts\n'
