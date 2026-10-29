#!/bin/bash
# Load display functions without invoking the application's main entry point.
set -e
cd "$(dirname "$0")/.."
eval "$(sed '$d' aqua-probe.sh)"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }
kubectl() { fail 'Formatting must not invoke kubectl'; }
docker() { fail 'Formatting must not invoke docker'; }
ssh() { fail 'Formatting must not invoke ssh'; }

export NO_COLOR=1
for width in 30 40 60 79 80 100; do
    export COLUMNS=$width
    output=$(
        print_logo
        print_welcome_message
        print_main_menu
        print_test_header 'Brute Force Login Detection' 'Host Runtime Policy'
        print_instructions '  Enable the appropriate policy and confirm its scope before running this test.'
    )
    [[ "$output" != *$'\033'* ]] || fail 'Unexpected ANSI escape'
    printf '%s\n' "$output" | awk -v w="$width" 'length > w {exit 1}' || fail "Overflow at $width columns"
    for number in {1..32}; do
        count=$(printf '%s\n' "$output" | grep -cE "^ +${number}\\. ")
        [[ "$count" == 1 ]] || fail "Menu option $number missing or duplicated"
    done
done
[[ "$(format_prompt 'Ready? ')" == '> Ready? ' ]] || fail 'Prompt text changed'
[[ "$(print_colored_message red 'Failure details')" == 'Failure details' ]] || fail 'Redirected message changed'
unset NO_COLOR
TERM=dumb
[[ "$(format_prompt 'Ready? ')" != *$'\033'* ]] || fail 'Dumb terminal has color'
TERM=xterm-256color
COLORTERM=truecolor
[[ "$(theme_code blue)" == '1;38;2;72;145;249;48;2;1;15;31' ]] || fail 'Blue palette mismatch'
[[ "$(theme_code green)" == "$(theme_code teal)" ]] || fail 'Success palette mismatch'
[[ "$(theme_code red)" == '1;38;2;255;0;73;48;2;1;15;31' ]] || fail 'Error palette mismatch'
[[ "$(print_colored_message teal 'Redirected')" == 'Redirected' ]] || fail 'Redirected output has color'
COLORTERM=
[[ "$(theme_code yellow)" == '1;33;40' ]] || fail 'ANSI fallback mismatch'
printf 'PASS: responsive layout, all 32 options, plain output, prompts, and palette fallbacks\n'
