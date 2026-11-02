#!/bin/bash
set -e
cd "$(dirname "$0")/.."
eval "$(sed '$d' aqua-probe.sh)"
export NO_COLOR=1
fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
sample=$'  1. Enable the control and verify the correct workload or host is in policy scope.\n  12. Keep independent recovery access available during authentication tests.\n\n  Unnumbered guidance must remain readable when the terminal is narrow.'
for width in 30 40 60 80 100; do
    export COLUMNS=$width
    output=$(
        print_instructions "$sample"
        print_instructions 'Wait for policy synchronization before continuing.' 'POLICY SETUP' blue
        print_step 'Preparing the disposable test resource before command execution.'
        print_audit_review
        print_help
        print_host_os_requirements
    )
    [[ "$output" != *$'\033'* ]] || fail 'Plain output contains ANSI escapes'
    printf '%s\n' "$output" | awk -v w="$width" 'length > w {exit 1}' || fail "Overflow at $width columns"
    [[ "$output" == *'   1. Enable'* && "$output" == *'  12. Keep'* && "$output" == *'  - Unnumbered'* ]] || fail 'Step prefixes'
    [[ "$output" == *'BEFORE YOU BEGIN'* && "$output" == *'POLICY SETUP'* && "$output" == *'REVIEW IN AQUA'* ]] || fail 'Missing section labels'
done
COLUMNS=30
numbered=$(print_instructions '1. A long instruction that wraps onto several continuation lines for alignment testing.')
printf '%s\n' "$numbered" | awk '/^   1[.] / {body=1; next} body && NF && !/^      / {exit 1}' || fail 'Numbered continuation indentation'
bulleted=$(print_instructions 'An unnumbered instruction that wraps onto several continuation lines for alignment testing.')
printf '%s\n' "$bulleted" | awk '/^  - / {body=1; next} body && NF && !/^    / {exit 1}' || fail 'Bullet continuation indentation'
host_ssh() { return 0; }
review_host_control() { :; }
command='printf "%s" "literal $HOME and spaces stay unchanged"'
output=$(run_host_command "$command")
[[ "$output" == *"$command"* ]] || fail 'Displayed command was altered or wrapped'
printf 'PASS: instruction sections, hanging indents, support/help layout, plain output and copyable commands\n'
