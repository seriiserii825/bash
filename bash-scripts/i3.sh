#!/bin/bash
# i3 power menu: lock screen, logout, suspend, reboot, or shutdown

lock() {
    i3lock \
        --image="$HOME/Pictures/wallpapers/i3lock.png" \
        --tiling \
        --indicator \
        --radius=140 \
        --ring-width=8 \
        --clock \
        --time-str="%H:%M:%S" \
        --date-str="%A, %d %B %Y" \
        --time-font="sans-serif" \
        --date-font="sans-serif" \
        --time-size=48 \
        --date-size=20 \
        --verif-text="Verifying..." \
        --wrong-text="Wrong password!" \
        --noinput-text="No input" \
        --lock-text="Locking..." \
        --lockfailed-text="Lock failed!" \
        --greeter-text="$USER" \
        --greeter-size=24 \
        --ignore-empty-password \
        --show-failed-attempts \
        --inside-color=1e1e2eee \
        --ring-color=89b4faff \
        --line-color=1e1e2e00 \
        --separator-color=00000000 \
        --insidever-color=1e1e2eee \
        --ringver-color=a6e3a1ff \
        --insidewrong-color=1e1e2eee \
        --ringwrong-color=f38ba8ff \
        --keyhl-color=89b4faff \
        --bshl-color=f38ba8ff \
        --time-color=cdd6f4ff \
        --date-color=cdd6f4ff \
        --greeter-color=cdd6f4ff \
        --verif-color=cdd6f4ff \
        --wrong-color=f38ba8ff \
        --layout-color=cdd6f4ff \
        --modif-color=f9e2afff \
        --greeteroutline-color=00000000 \
        --timeoutline-color=00000000 \
        --dateoutline-color=00000000 \
        --verifoutline-color=00000000 \
        --wrongoutline-color=00000000 \
        --pass-media-keys \
        --pass-volume-keys \
        --pass-screen-keys
}

select action in "lock" "logout" "suspend" "reboot" "shutdown" "cancel"; do
    case $action in
        "lock")
            lock
            exit 0
            ;;
        "logout")
            read -p "Are you sure you want to logout? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                i3-msg exit
            fi
            ;;
        "suspend")
            read -p "Are you sure you want to suspend? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                lock && systemctl suspend
            fi
            ;;
        "reboot")
            read -p "Are you sure you want to reboot? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                systemctl reboot
            fi
            ;;
        "shutdown")
            read -p "Are you sure you want to shutdown? (y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                systemctl poweroff
            fi
            ;;
        "cancel")
            echo "Cancelled."
            exit 0
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done

exit 0
