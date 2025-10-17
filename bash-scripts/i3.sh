#!/bin/bash

lock() {
    i3lock -i ~/Pictures/wallpapers/i3lock.png -t
}

select action in "lock" "logout" "suspend" "reboot" "shutdown" "cancel"; do
    case $action in
        "lock")
            lock
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
