#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DETECTOR="$SCRIPT_DIR/npm-supply-chain-detector.sh"

usage() {
    cat <<'EOF'
Usage:
  ./nsc-scan.sh [detector options] <directory>
  ./nsc-scan.sh --menu
  ./nsc-scan.sh --help

Behavior:
  - With no arguments in an interactive terminal, opens a guided scan menu
  - With arguments, passes them through to the detector engine unchanged

Guided presets:
  1. Quick triage           -> core scan
  2. Deep audit             -> --paranoid
  3. Semver exposure        -> --check-semver-ranges
  4. Incident response      -> --paranoid --check-semver-ranges --save-log
  5. Custom guided scan     -> prompts for options
EOF
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local answer=""

    if [[ "$default" == "y" ]]; then
        read -r -p "$prompt [Y/n]: " answer
        answer="${answer:-y}"
    else
        read -r -p "$prompt [y/N]: " answer
        answer="${answer:-n}"
    fi

    [[ "$answer" =~ ^[Yy]([Ee][Ss])?$ ]]
}

prompt_target_dir() {
    local target=""

    while true; do
        read -r -p "Target directory [.]: " target
        target="${target:-.}"

        if [[ -d "$target" ]]; then
            printf '%s\n' "$target"
            return 0
        fi

        echo "Directory not found: $target"
    done
}

prompt_log_path() {
    local suggested="./nsc-scan-$(date +%Y%m%d-%H%M%S).log"
    local log_path=""

    read -r -p "Log file path [$suggested]: " log_path
    printf '%s\n' "${log_path:-$suggested}"
}

prompt_grep_tool() {
    local choice=""

    echo
    echo "Grep engine:"
    echo "  1) auto"
    echo "  2) git grep"
    echo "  3) ripgrep"
    echo "  4) grep"

    while true; do
        read -r -p "Choose grep engine [1]: " choice
        choice="${choice:-1}"

        case "$choice" in
            1) printf '%s\n' "auto"; return 0 ;;
            2) printf '%s\n' "git"; return 0 ;;
            3) printf '%s\n' "rg"; return 0 ;;
            4) printf '%s\n' "grep"; return 0 ;;
            *) echo "Invalid option: $choice" ;;
        esac
    done
}

run_guided_scan() {
    local preset="$1"
    local target=""
    local log_path=""
    local grep_tool=""
    local -a args=()
    local paranoid="n"
    local semver="n"
    local save_log="n"

    echo
    case "$preset" in
        quick)
            echo "Preset: Quick triage"
            ;;
        deep)
            echo "Preset: Deep audit"
            paranoid="y"
            ;;
        semver)
            echo "Preset: Semver exposure"
            semver="y"
            ;;
        incident)
            echo "Preset: Incident response"
            paranoid="y"
            semver="y"
            save_log="y"
            ;;
        custom)
            echo "Preset: Custom guided scan"
            if prompt_yes_no "Enable paranoid mode?" "n"; then
                paranoid="y"
            fi
            if prompt_yes_no "Check semver ranges?" "n"; then
                semver="y"
            fi
            if prompt_yes_no "Save findings to a log file?" "n"; then
                save_log="y"
            fi
            ;;
        *)
            echo "Unknown preset: $preset" >&2
            exit 1
            ;;
    esac

    target="$(prompt_target_dir)"
    grep_tool="$(prompt_grep_tool)"

    if [[ "$paranoid" == "y" ]]; then
        args+=(--paranoid)
    fi

    if [[ "$semver" == "y" ]]; then
        args+=(--check-semver-ranges)
    fi

    if [[ "$save_log" == "y" ]]; then
        log_path="$(prompt_log_path)"
        args+=(--save-log "$log_path")
    fi

    case "$grep_tool" in
        git) args+=(--use-git-grep) ;;
        rg) args+=(--use-ripgrep) ;;
        grep) args+=(--use-grep) ;;
    esac

    args+=("$target")

    echo
    echo "Running: $DETECTOR ${args[*]}"
    echo
    exec "$DETECTOR" "${args[@]}"
}

run_menu() {
    local choice=""

    echo "npm Supply Chain Detector"
    echo
    echo "  1) Quick triage"
    echo "  2) Deep audit"
    echo "  3) Semver exposure"
    echo "  4) Incident response bundle"
    echo "  5) Custom guided scan"
    echo "  q) Quit"

    while true; do
        read -r -p "Select a scan profile [1]: " choice
        choice="${choice:-1}"

        case "$choice" in
            1) run_guided_scan "quick" ;;
            2) run_guided_scan "deep" ;;
            3) run_guided_scan "semver" ;;
            4) run_guided_scan "incident" ;;
            5) run_guided_scan "custom" ;;
            q|Q) exit 0 ;;
            *) echo "Invalid option: $choice" ;;
        esac
    done
}

if [[ ! -x "$DETECTOR" ]]; then
    echo "Detector entrypoint not found or not executable: $DETECTOR" >&2
    exit 1
fi

case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
    --menu)
        run_menu
        ;;
esac

if [[ $# -eq 0 && -t 0 && -t 1 ]]; then
    run_menu
fi

exec "$DETECTOR" "$@"
