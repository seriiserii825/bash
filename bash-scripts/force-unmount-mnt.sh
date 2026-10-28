#!/usr/bin/env bash
# Unmounts /mnt (or the mount point given as $1). If it is busy, first shows WHY
# (processes, submounts, swap, loop devices, other mount namespaces), then asks
# how to proceed: kill the processes and unmount, lazy unmount, or cancel.
# Usage: force-unmount-mnt.sh [mount_point]

MNT="${1:-/mnt}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if ! findmnt -M "$MNT" >/dev/null 2>&1; then
    echo -e "${YELLOW}$MNT is not mounted.${NC}"
    exit 0
fi

# Ask for the sudo password once, up front
sudo -v || exit 1

echo -e "${CYAN}Mount:${NC}"
findmnt -M "$MNT" -o TARGET,SOURCE,FSTYPE,OPTIONS
echo ""

# Easy path: nothing holds it
if sudo umount "$MNT" 2>/dev/null; then
    echo -e "${GREEN}Unmounted $MNT${NC}"
    exit 0
fi

echo -e "${RED}$MNT is busy. Reasons found:${NC}"
echo ""
found=0

# 1. Processes in the current namespace (open files, cwd, mmaps)
mapfile -t pids < <(sudo fuser -m "$MNT" 2>/dev/null | tr -s ' ' '\n' | tr -cd '0-9\n' | grep -v '^$')
if [ ${#pids[@]} -gt 0 ]; then
    found=1
    echo -e "${YELLOW}Processes using $MNT:${NC}"
    ps -o pid,user,comm,args -p "$(IFS=,; echo "${pids[*]}")"
    echo ""
    echo -e "${YELLOW}Open files:${NC}"
    sudo lsof +f -- "$MNT" 2>/dev/null | head -30
    echo ""
fi

# 2. Something else mounted inside it
submounts=$(findmnt -R -n -o TARGET,SOURCE,FSTYPE "$MNT" | tail -n +2)
if [ -n "$submounts" ]; then
    found=1
    echo -e "${YELLOW}Submounts inside $MNT:${NC}"
    echo "$submounts"
    echo ""
fi

# 3. Swap file on it
swaps=$(swapon --show=NAME --noheadings 2>/dev/null | grep "^$MNT/")
if [ -n "$swaps" ]; then
    found=1
    echo -e "${YELLOW}Active swap files on $MNT (fix: sudo swapoff <file>):${NC}"
    echo "$swaps"
    echo ""
fi

# 4. Loop devices backed by a file on it
loops=$(losetup -a 2>/dev/null | grep "($MNT/")
if [ -n "$loops" ]; then
    found=1
    echo -e "${YELLOW}Loop devices backed by files on $MNT (fix: sudo losetup -d /dev/loopN):${NC}"
    echo "$loops"
    echo ""
fi

# 5. Processes in OTHER mount namespaces (docker, flatpak, systemd PrivateTmp...),
#    which fuser/lsof don't see. Match by the mount's device id (MAJ:MIN).
majmin=$(findmnt -M "$MNT" -n -o MAJ:MIN | head -1)
my_ns=$(readlink /proc/self/ns/mnt)
ns_pids=()
for f in /proc/[0-9]*/mountinfo; do
    pid=${f#/proc/}
    pid=${pid%/mountinfo}
    ns=$(sudo readlink "/proc/$pid/ns/mnt" 2>/dev/null) || continue
    [ "$ns" = "$my_ns" ] && continue
    if sudo awk -v mm="$majmin" '$3 == mm { found=1 } END { exit !found }' "$f" 2>/dev/null; then
        ns_pids+=("$pid")
    fi
done
if [ ${#ns_pids[@]} -gt 0 ]; then
    found=1
    echo -e "${YELLOW}Processes in other mount namespaces holding this filesystem:${NC}"
    ps -o pid,user,comm,args -p "$(IFS=,; echo "${ns_pids[*]}")"
    echo ""
fi

if [ "$found" -eq 0 ]; then
    echo "  Nothing obvious found (maybe a kernel/NFS/FUSE reference)."
    echo ""
fi

echo "How to proceed?"
echo "  k - kill processes using $MNT (SIGKILL, unsaved work is lost), then unmount"
echo "  l - lazy unmount (detach now, finish when nothing uses it)"
echo "  q - cancel"
read -rp "> " choice

case "$choice" in
    k|K)
        [ ${#pids[@]} -gt 0 ] && sudo fuser -km "$MNT"
        [ -n "$submounts" ] && sudo umount -R "$MNT" 2>/dev/null
        sleep 1
        if sudo umount "$MNT" 2>/dev/null || ! findmnt -M "$MNT" >/dev/null 2>&1; then
            echo -e "${GREEN}Unmounted $MNT${NC}"
        else
            echo -e "${RED}Still busy. Try 'l' (lazy unmount) or resolve the reasons above.${NC}"
            exit 1
        fi
        ;;
    l|L)
        if sudo umount -l "$MNT"; then
            echo -e "${GREEN}Lazy-unmounted $MNT${NC}"
            echo "If it's a USB drive, wait until activity stops before unplugging."
        else
            exit 1
        fi
        ;;
    *)
        echo "Cancelled."
        ;;
esac
