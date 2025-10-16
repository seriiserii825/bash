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
            read -p "Are you sure you want to logout? (y/n) " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]
              i3-msg exit
            fi
            ;;
        "suspend")
            lock && systemctl suspend
            read -p "Are you sure you want to suspend? (y/n) " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]
              lock && systemctl suspend
            fi
            ;;
        "reboot")
            systemctl reboot
            read -p "Are you sure you want to reboot? (y/n) " -n 1 -r
            if [[ $REPLY =~ ^[Yy]$ ]]
              systemctl reboot
            fi
            ;;
        "shutdown")
          read -p "Are you sure you want to shutdown? (y/n) " -n 1 -r
          if [[ $REPLY =~ ^[Yy]$ ]]
            systemctl poweroff
          fi
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
