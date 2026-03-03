#!/bin/bash
#
# Twitch Stream Recorder - Control Script
#
# Version: 04.03.2026-0030
# Developed by: DravenTec
#
# Manages tsr.py systemd services via whiptail TUI
# Requires: whiptail, systemctl, journalctl, less
# Run as: root (systemctl write access required)

set -euo pipefail

# ─── Constants ────────────────────────────────────────────────────────────────

readonly CONF_FILE="$HOME/.tsrconf"
readonly SCRIPT_VERSION="04.03.2026-0030"
readonly TSR_SCRIPT="tsr.py"
readonly WT_MIN_HEIGHT=20
readonly WT_MIN_WIDTH=60

# Mutable globals — updated by wt_size() before every dialog
WT_HEIGHT=22
WT_WIDTH=70
WT_MENU_HEIGHT=14

# Global backtitle string — updated by build_backtitle()
WT_BACKTITLE="TSR Control"

# Global menu item array — filled by fill_menu_items()
_menu_items=()

# ─── Logging ──────────────────────────────────────────────────────────────────

log_info()  { echo "[INFO]  $*"; }
log_error() { echo "[ERROR] $*" >&2; }

# ─── Terminal size ─────────────────────────────────────────────────────────────
# Call before every whiptail dialog so the box fits the current window.

wt_size() {
    local lines cols
    lines=$(tput lines 2>/dev/null || echo 24)
    cols=$(tput cols  2>/dev/null || echo 80)

    WT_HEIGHT=$(( lines - 4 ))
    WT_WIDTH=$(( cols  - 6 ))
    WT_MENU_HEIGHT=$(( WT_HEIGHT - 8 ))

    # Use [[ ]] for comparisons — (( expr )) returning 0 exits with code 1,
    # which kills the script under set -e
    [[ $WT_HEIGHT      -lt $WT_MIN_HEIGHT ]] && WT_HEIGHT=$WT_MIN_HEIGHT
    [[ $WT_WIDTH       -lt $WT_MIN_WIDTH  ]] && WT_WIDTH=$WT_MIN_WIDTH
    [[ $WT_MENU_HEIGHT -lt 4              ]] && WT_MENU_HEIGHT=4
    return 0
}

# ─── Config ───────────────────────────────────────────────────────────────────

load_config() {
    if [[ -f "$CONF_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$CONF_FILE"
    else
        wt_size
        local input_username
        input_username=$(whiptail \
            --title "TSR Control – First Run" \
            --inputbox "Specify the non-root user that runs tsr.py:" \
            10 60 3>&1 1>&2 2>&3) || { log_error "Setup cancelled."; exit 1; }

        [[ -z "$input_username" ]] && { log_error "Username cannot be empty."; exit 1; }

        write_config "$input_username" ""
        # shellcheck source=/dev/null
        source "$CONF_FILE"
    fi

    user="${user:-}"
    streams="${streams:-}"
}

write_config() {
    # Atomic write — temp file + mv avoids corrupt config on write error
    local tmp
    tmp=$(mktemp "${CONF_FILE}.XXXXXX")
    printf 'user="%s"\nstreams="%s"\n' "$1" "$2" > "$tmp"
    mv "$tmp" "$CONF_FILE"
}

save_streams() {
    local updated=""
    if [[ ${#streams_array[@]} -gt 0 ]]; then
        updated="$(printf "%s " "${streams_array[@]}")"
        updated="${updated% }"
    fi
    write_config "$user" "$updated"
    streams="$updated"
}

# ─── Service helpers ──────────────────────────────────────────────────────────

service_is_active() {
    systemctl is-active --quiet "$1" 2>/dev/null || return 1
}

service_exists() {
    [[ -f "/etc/systemd/system/$1.service" ]]
}

service_status_label() {
    if ! service_exists "$1"; then
        echo "NO UNIT"
    elif service_is_active "$1"; then
        echo "RUNNING"
    else
        echo "STOPPED"
    fi
}

# ─── Backtitle ────────────────────────────────────────────────────────────────
# Builds a recorder status overview shown at the top of every whiptail dialog.
# whiptail renders --backtitle as a line above the box across the full terminal.
#
# Example (short):  "Recorders:  streamer1[RUNNING]  streamer2[STOPPED]"
# Example (long):   "TSR Control  |  5 recorders configured  (3 running)"

build_backtitle() {
    WT_BACKTITLE="TSR Control v${SCRIPT_VERSION}"
    return 0
}

# Builds a multi-line recorder list for the main menu prompt.
# Line 1: summary count.  Line 2+: names packed greedily to fit box width.
# Result stored in global _menu_prompt.
_menu_prompt=""
build_menu_prompt() {
    if [[ ${#streams_array[@]} -eq 0 ]]; then
        _menu_prompt="No recorders configured yet. Use 'Create Service' to add one."
        return 0
    fi

    local running=0 s
    for s in "${streams_array[@]}"; do
        service_is_active "$s" && running=$(( running + 1 )) || true
    done

    # Line 1: summary
    _menu_prompt="$(printf '%d recorders configured, %d running:' \
        "${#streams_array[@]}" "$running")"$'\n'

    # Available width inside the whiptail box (border + padding ~ 4 chars each side)
    local inner_width=$(( WT_WIDTH - 8 ))
    [[ $inner_width -lt 20 ]] && inner_width=20

    # Separator between names on the same row
    local sep="  "
    local sep_len=${#sep}

    # Greedy pack: add names to the current row until the next name would overflow,
    # then start a new row. Works correctly for any mix of name lengths.
    local row=""
    local row_len=0

    for s in "${streams_array[@]}"; do
        local name_len=${#s}

        if [[ -z "$row" ]]; then
            # First name on this row — always fits
            row="$s"
            row_len=$name_len
        elif [[ $(( row_len + sep_len + name_len )) -le $inner_width ]]; then
            # Fits on the current row
            row+="${sep}${s}"
            row_len=$(( row_len + sep_len + name_len ))
        else
            # Doesn't fit — flush current row and start a new one
            _menu_prompt+="${row}"$'\n'
            row="$s"
            row_len=$name_len
        fi
    done

    # Flush the last row
    [[ -n "$row" ]] && _menu_prompt+="${row}"$'\n'

    return 0
}

# ─── Menu item builder ────────────────────────────────────────────────────────

fill_menu_items() {
    local include_all="${1:-false}"
    _menu_items=()

    if [[ ${#streams_array[@]} -eq 0 ]]; then
        wt_size
        whiptail \
            --backtitle "$WT_BACKTITLE" \
            --title "TSR Control" \
            --msgbox "No recorders configured yet.\nUse 'Create Service' to add one." \
            10 50
        return 1
    fi

    local s lbl
    for s in "${streams_array[@]}"; do
        lbl=$(service_status_label "$s")
        _menu_items+=("$s" "[$lbl]")
    done

    [[ "$include_all" == "true" ]] && _menu_items+=("__ALL__" "[All recorders]")
    _menu_items+=("__BACK__" "[Back]")
    return 0
}

# ─── Service actions ──────────────────────────────────────────────────────────

run_action() {
    local subcmd="$1" target="$2"
    local results="" s
    local targets=()

    if [[ "$target" == "__ALL__" ]]; then
        targets=("${streams_array[@]}")
    else
        targets=("$target")
    fi

    for s in "${targets[@]}"; do
        if systemctl "$subcmd" "$s" 2>/dev/null; then
            results+="OK  $s\n"
        else
            results+="!!  $s (failed)\n"
        fi
    done

    wt_size
    whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "Result: $subcmd" \
        --msgbox "$(printf '%b' "$results")" \
        12 "$WT_WIDTH"
}

# ─── Menus ────────────────────────────────────────────────────────────────────

menu_action() {
    local title="$1" subcmd="$2" include_all="${3:-true}"
    wt_size; build_backtitle
    fill_menu_items "$include_all" || return 0

    local choice
    choice=$(whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "TSR Control – $title" \
        --menu "Select a recorder:" \
        "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
        "${_menu_items[@]}" 3>&1 1>&2 2>&3) || return 0

    [[ "$choice" == "__BACK__" ]] && return 0
    run_action "$subcmd" "$choice"
}

menu_status() {
    wt_size; build_backtitle
    fill_menu_items "false" || return 0

    local choice
    choice=$(whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "TSR Control – Status" \
        --menu "Select a recorder:" \
        "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
        "${_menu_items[@]}" 3>&1 1>&2 2>&3) || return 0

    [[ "$choice" == "__BACK__" ]] && return 0

    clear
    systemctl status "$choice" --no-pager -l 2>&1 | \
        less -RS --prompt="  Status: $choice  |  q=quit  arrows=scroll"
}

menu_logs() {
    wt_size; build_backtitle
    fill_menu_items "false" || return 0

    local choice
    choice=$(whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "TSR Control – Logs" \
        --menu "Select a recorder:" \
        "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
        "${_menu_items[@]}" 3>&1 1>&2 2>&3) || return 0

    [[ "$choice" == "__BACK__" ]] && return 0

    wt_size
    local line_count
    line_count=$(whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "Logs: $choice" \
        --inputbox "How many log lines to show?" \
        10 50 "100" 3>&1 1>&2 2>&3) || return 0

    [[ -z "$line_count" || ! "$line_count" =~ ^[0-9]+$ ]] && line_count=100

    clear
    journalctl -u "$choice" -n "$line_count" --no-pager 2>&1 | \
        less -RS +G --prompt="  Logs: $choice  (${line_count} lines)  |  q=quit  PgUp/PgDn=scroll"
}

menu_active_recorders() {
    wt_size; build_backtitle

    local body="" s lbl
    if [[ ${#streams_array[@]} -eq 0 ]]; then
        body="  No recorders configured."
    else
        for s in "${streams_array[@]}"; do
            lbl=$(service_status_label "$s")
            body+="  [${lbl}]  ${s}\n"
        done
    fi

    local pgrep_out
    pgrep_out=$(pgrep -af "$TSR_SCRIPT" 2>/dev/null || echo "  (none running)")

    whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "TSR Control – Active Recorders" \
        --scrolltext \
        --msgbox "$(printf 'Configured recorders:\n%b\nRunning processes:\n%s' "$body" "$pgrep_out")" \
        "$WT_HEIGHT" "$WT_WIDTH"
}

menu_create_service() {
    wt_size; build_backtitle

    local streamer
    streamer=$(whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "TSR Control – Create Service" \
        --inputbox "Enter the streamer's name (lowercase, no spaces):" \
        10 60 3>&1 1>&2 2>&3) || return 0

    [[ -z "$streamer" ]] && {
        whiptail --backtitle "$WT_BACKTITLE" --title "Error" \
            --msgbox "Streamer name cannot be empty." 8 40
        return 0
    }

    if [[ ! "$streamer" =~ ^[a-z0-9_]+$ ]]; then
        whiptail --backtitle "$WT_BACKTITLE" --title "Error" \
            --msgbox "Invalid name: '$streamer'\nOnly lowercase letters, numbers and underscores allowed." \
            10 55
        return 0
    fi

    local existing
    for existing in "${streams_array[@]}"; do
        if [[ "$existing" == "$streamer" ]]; then
            whiptail --backtitle "$WT_BACKTITLE" --title "Error" \
                --msgbox "Recorder for '$streamer' already exists." 8 50
            return 0
        fi
    done

    local quality
    quality=$(whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "TSR Control – Quality" \
        --menu "Select recording quality for $streamer:" \
        16 60 8 \
        "best"       "Highest available quality" \
        "high"       "High quality" \
        "medium"     "Medium quality" \
        "low"        "Low quality" \
        "mobile"     "Mobile quality" \
        "audio_only" "Audio only" \
        3>&1 1>&2 2>&3) || return 0

    whiptail --backtitle "$WT_BACKTITLE" --title "Confirm" \
        --yesno "Create recorder for '$streamer' with quality '$quality'?" \
        10 55 || return 0

    cat > "/etc/systemd/system/${streamer}.service" <<-EOSVC
	[Unit]
	Description=$streamer Twitch Stream Recorder
	After=network-online.target
	Wants=network-online.target

	[Service]
	Environment=PYTHONUNBUFFERED=1
	Type=simple
	User=$user
	Group=$user
	WorkingDirectory=/home/$user
	ExecStart=/usr/bin/python3 $TSR_SCRIPT -u $streamer -q $quality
	SyslogIdentifier=$streamer
	StandardOutput=journal
	StandardError=journal
	Restart=always
	RestartSec=5

	[Install]
	WantedBy=multi-user.target
	EOSVC

    streams_array+=("$streamer")
    save_streams
    systemctl daemon-reload

    local result=""
    if systemctl enable "$streamer" 2>/dev/null; then result+="OK  Enabled\n"
    else                                               result+="!!  Enable failed\n"; fi
    if systemctl start  "$streamer" 2>/dev/null; then result+="OK  Started\n"
    else                                               result+="!!  Start failed\n";  fi

    wt_size
    whiptail --backtitle "$WT_BACKTITLE" --title "Service Created" \
        --msgbox "$(printf 'Recorder for %s created.\n\n%b' "$streamer" "$result")" \
        12 "$WT_WIDTH"
}

menu_delete_service() {
    wt_size; build_backtitle
    fill_menu_items "false" || return 0

    local choice
    choice=$(whiptail \
        --backtitle "$WT_BACKTITLE" \
        --title "TSR Control – Delete Service" \
        --menu "Select a recorder to delete:" \
        "$WT_HEIGHT" "$WT_WIDTH" "$WT_MENU_HEIGHT" \
        "${_menu_items[@]}" 3>&1 1>&2 2>&3) || return 0

    [[ "$choice" == "__BACK__" ]] && return 0

    whiptail --backtitle "$WT_BACKTITLE" --title "Confirm Delete" \
        --yesno "Permanently delete recorder '$choice'?\nThis stops, disables and removes the service file." \
        10 60 || return 0

    local result=""
    systemctl stop    "$choice" 2>/dev/null && result+="OK  Stopped\n"  || result+="!!  Stop failed\n"
    systemctl disable "$choice" 2>/dev/null && result+="OK  Disabled\n" || result+="!!  Disable failed\n"

    if [[ -f "/etc/systemd/system/${choice}.service" ]]; then
        rm "/etc/systemd/system/${choice}.service"
        result+="OK  Service file removed\n"
    else
        result+="!!  Service file not found\n"
    fi

    systemctl daemon-reload

    local updated=() s
    for s in "${streams_array[@]}"; do
        [[ "$s" != "$choice" ]] && updated+=("$s")
    done
    streams_array=("${updated[@]}")
    save_streams

    wt_size
    whiptail --backtitle "$WT_BACKTITLE" --title "Deleted" \
        --msgbox "$(printf 'Recorder for %s deleted.\n\n%b' "$choice" "$result")" \
        12 "$WT_WIDTH"
}

# ─── Dependency check ─────────────────────────────────────────────────────────

check_dependencies() {
    local missing=() cmd
    for cmd in whiptail systemctl journalctl pgrep less; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required tools: ${missing[*]}"
        log_error "Install with: sudo apt-get install ${missing[*]}"
        exit 1
    fi
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
    check_dependencies
    load_config

    # 'read' returns exit 1 on empty input — || true prevents set -e from
    # killing the script when streams is empty (no recorders configured yet)
    read -r -a streams_array <<< "$streams" || true

    while true; do
        wt_size
        build_backtitle
        build_menu_prompt

        # Count prompt lines to shrink the menu list height accordingly
        local prompt_lines
        prompt_lines=$(printf '%b' "$_menu_prompt" | wc -l)
        local adj_menu_height=$(( WT_MENU_HEIGHT - prompt_lines ))
        [[ $adj_menu_height -lt 4 ]] && adj_menu_height=4

        local choice
        choice=$(whiptail \
            --backtitle "$WT_BACKTITLE" \
            --title "TSR Control  v${SCRIPT_VERSION}" \
            --menu "$(printf '%b' "$_menu_prompt")" \
            "$WT_HEIGHT" "$WT_WIDTH" "$adj_menu_height" \
            "1"  "Start recorder" \
            "2"  "Stop recorder" \
            "3"  "Restart recorder" \
            "4"  "Enable recorder (autostart)" \
            "5"  "Disable recorder (autostart)" \
            "6"  "Status" \
            "7"  "Logs" \
            "8"  "Active recorders overview" \
            "9"  "Create service" \
            "10" "Delete service" \
            "11" "Quit" \
            3>&1 1>&2 2>&3) || break

        case "$choice" in
            1)  menu_action "Start"   "start"   "true" ;;
            2)  menu_action "Stop"    "stop"    "true" ;;
            3)  menu_action "Restart" "restart" "true" ;;
            4)  menu_action "Enable"  "enable"  "true" ;;
            5)  menu_action "Disable" "disable" "true" ;;
            6)  menu_status ;;
            7)  menu_logs ;;
            8)  menu_active_recorders ;;
            9)  menu_create_service ;;
            10) menu_delete_service ;;
            11) break ;;
        esac
    done

    clear
    log_info "TSR Control closed."
}

main "$@"
