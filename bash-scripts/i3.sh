#!/bin/bash
#
lock() {
    i3lock -i ~/Pictures/wallpapers/i3lock.png -t
}

select action in "lock" "logout" "suspend" "reboot" "shutdown" "cancel";
do
    case $action in
        "lock")
            lock
            ;;
        "logout")
            i3-msg exit
            ;;
        "suspend")
            lock && systemctl suspend
            ;;
        "reboot")
            systemctl reboot
            ;;
        "shutdown")
            systemctl poweroff
            ;;
        "cancel")
          exit 0
          ;;
        *)
            echo "Invalid option $REPLY"
            exit 1
    esac
done

exit 0
