#!/bin/bash
# Read-only system health check: what loads the system right now and which
# errors the kernel/systemd reported. No sudo needed. Problems are collected
# and printed again as a summary at the end.

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
NC='\033[0m'

PROBLEMS=()

header() { echo -e "\n${BLUE}=== $1 ===${NC}"; }
ok() { echo -e "${GREEN}OK${NC} $1"; }
warn() {
    echo -e "${YELLOW}WARN${NC} $1"
    PROBLEMS+=("$1")
}

check_load() {
    header "Load"
    local cores load
    cores=$(nproc)
    uptime
    load=$(cut -d' ' -f1 /proc/loadavg)
    if awk -v l="$load" -v c="$cores" 'BEGIN { exit !(l > c) }'; then
        warn "load average $load > $cores cores"
    else
        ok "load $load on $cores cores"
    fi
}

check_memory() {
    header "Memory"
    free -h
    local avail_pct swap_used
    avail_pct=$(awk '/MemTotal/ {t=$2} /MemAvailable/ {a=$2} END {printf "%d", a*100/t}' /proc/meminfo)
    swap_used=$(free -m | awk '/Swap/ {print $3}')
    if [ "$avail_pct" -lt 10 ]; then
        warn "only ${avail_pct}% memory available"
    else
        ok "${avail_pct}% memory available"
    fi
    [ "$swap_used" -gt 1024 ] && warn "swap in use: ${swap_used} MB"
}

# Processes summed by command name, so 30 chrome processes show as one line.
check_processes() {
    header "Top CPU now (3 s sample)"
    local sample
    sample=$(top -bn2 -d3 -o %CPU | awk '/^top -/ {n++} n==2')
    echo "$sample" | sed -n '7,17p'

    header "Memory by application"
    ps -eo rss=,comm= | awk '{m[$2]+=$1; c[$2]++} END {for (p in m) printf "%8.0f MB  %3d  %s\n", m[p]/1024, c[p], p}' |
        sort -rn | head -10

    local busy
    busy=$(echo "$sample" | awk '$1 ~ /^[0-9]+$/ && $9+0 >= 90 {print $12 " (PID " $1 ", " $9 "%)"}')
    [ -n "$busy" ] && while read -r p; do warn "process at full core: $p"; done <<<"$busy"

    local zombies
    zombies=$(ps -eo stat= | grep -c '^Z')
    [ "$zombies" -gt 0 ] && warn "$zombies zombie process(es)"
}

check_io() {
    header "Disk I/O (vmstat 1 s x 5)"
    local stat wa
    stat=$(vmstat 1 5)
    echo "$stat"
    # first line is the average since boot, skip it
    wa=$(echo "$stat" | tail -4 | awk '{s+=$16} END {printf "%d", s/NR}')
    if [ "$wa" -gt 10 ]; then
        warn "high I/O wait: ${wa}%"
    else
        ok "I/O wait ${wa}%"
    fi
    local blocked
    blocked=$(ps -eo pid=,stat=,comm= | awk '$2 ~ /^D/ {print $3 " (PID " $1 ")"}')
    [ -n "$blocked" ] && warn "processes stuck on I/O: $(echo "$blocked" | tr '\n' ' ')"
}

check_disks() {
    header "Disk space"
    df -h -x tmpfs -x devtmpfs -x efivarfs -x overlay
    while read -r use mnt; do
        warn "disk $mnt is ${use}% full"
    done < <(df --output=pcent,target -x tmpfs -x devtmpfs -x efivarfs -x overlay | tail -n +2 |
        tr -d '%' | awk '$1 >= 90')

    header "Filesystem / disk errors (this boot)"
    local errs
    errs=$(journalctl -k -b --no-pager -o cat 2>/dev/null |
        grep -iE 'fs with errors|error count since|I/O error|EXT4-fs error|blk_update_request|usb .*(reset|disconnect)' |
        sort | uniq -c | sort -rn | head -10)
    if [ -n "$errs" ]; then
        echo "$errs"
        warn "kernel reported disk/filesystem errors (see above; run e2fsck on the unmounted partition)"
    else
        ok "no disk errors"
    fi
}

check_services() {
    header "Failed services"
    local failed
    failed=$(
        systemctl --failed --no-legend --plain | awk '{print "system: " $1}'
        systemctl --user --failed --no-legend --plain | awk '{print "user: " $1}'
    )
    if [ -n "$failed" ]; then
        echo "$failed"
        while read -r u; do warn "failed unit $u"; done <<<"$failed"
    else
        ok "no failed units"
    fi

    header "Restart loops"
    local units loops
    units=$(systemctl list-units --type=service --all --no-legend --plain | awk '{print $1}')
    loops=$(systemctl show $units -p Id -p NRestarts 2>/dev/null |
        awk -F= '/^Id=/ {id=$2} /^NRestarts=/ {n=$2} /^$/ {if (n > 5) print id " (" n " restarts)"; id=""; n=0}
            END {if (n > 5) print id " (" n " restarts)"}')
    if [ -n "$loops" ]; then
        echo "$loops"
        while read -r u; do warn "restart loop: $u"; done <<<"$loops"
    else
        ok "no restart loops"
    fi
}

check_journal() {
    header "Most frequent errors this boot"
    journalctl -b -p err --no-pager -o cat 2>/dev/null | grep -v '^\s*$' | sort | uniq -c | sort -rn | head -10

    header "Crashed programs (today)"
    local crashes
    crashes=$(coredumpctl list --since today --no-legend --no-pager 2>/dev/null | awk '{print $2, $3, $8, $(NF-1)}')
    if [ -n "$crashes" ]; then
        echo "$crashes"
        while read -r c; do warn "crash (core dump): $c"; done < <(echo "$crashes" | awk '{print $4}' | sort | uniq -c | awk '{print $2 " x" $1}')
    else
        ok "no crashes"
    fi

    header "OOM kills / hangs (this boot)"
    local oom
    oom=$(journalctl -b --no-pager 2>/dev/null | grep -iE 'out of memory|oom-kill|killed process|blocked for more than|soft lockup|hard lockup' | tail -10)
    if [ -n "$oom" ]; then
        echo "$oom"
        warn "OOM kills or kernel hangs this boot"
    else
        ok "none"
    fi

    header "Previous shutdown"
    if journalctl -b --no-pager -o cat 2>/dev/null | grep -q 'uncleanly shut down'; then
        warn "previous boot ended without clean shutdown (hard freeze/power off?) — see: journalctl -b -1 -p warning | tail -50"
    else
        ok "clean shutdown"
    fi
}

# Driver updated without reboot: alacritty/OpenGL apps fail with BadValue.
check_nvidia() {
    [ -r /proc/driver/nvidia/version ] || return
    header "NVIDIA driver"
    local kernel_ver user_pkg user_ver
    kernel_ver=$(grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' /proc/driver/nvidia/version | head -1)
    user_pkg=$(pacman -Qq 2>/dev/null | grep -E '^nvidia.*utils$' | head -1)
    user_ver=$(pacman -Q "$user_pkg" 2>/dev/null | awk '{print $2}' | cut -d- -f1)
    echo "kernel module: $kernel_ver, $user_pkg: $user_ver"
    if [ -n "$user_ver" ] && [ "$kernel_ver" != "$user_ver" ]; then
        warn "NVIDIA kernel module $kernel_ver != userspace $user_ver — reboot needed"
    else
        ok "versions match"
    fi
}

check_temps() {
    command -v sensors >/dev/null || return
    header "Temperatures"
    sensors 2>/dev/null | grep -E '°C' | head -15
    local hot
    hot=$(sensors 2>/dev/null | grep -oE '^[^:]+:\s+\+[0-9]+' | awk -F'+' '$2 >= 90 {print $1 $2 "°C"}')
    [ -n "$hot" ] && while read -r t; do warn "hot: $t"; done <<<"$hot"
}

summary() {
    header "Summary"
    if [ ${#PROBLEMS[@]} -eq 0 ]; then
        echo -e "${GREEN}No problems found${NC}"
        return
    fi
    for p in "${PROBLEMS[@]}"; do
        echo -e "${RED}*${NC} $p"
    done
}

check_load
check_memory
check_processes
check_io
check_disks
check_services
check_journal
check_nvidia
check_temps
summary
