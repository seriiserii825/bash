#!/bin/bash

select vps in vps2 vps3 vps4 vps5 vps6 vps6host vps6admin
do
  case $vps in
    vps2)
      echo "Dev02dev02!!" | xclip -selection clipboard
      sleep 1
      echo "ssh developer@51.75.16.130" | xclip -selection clipboard
      break
      ;;
    vps3)
      echo "Host03host03" | xclip -selection clipboard
      echo "ssh host@51.178.82.114" | xclip -selection clipboard
      break
      ;;
    vps4)
      echo "Dar04dar04!" | xclip -selection clipboard
      echo "ssh admin@185.116.60.81" | xclip -selection clipboard
      break
      ;;
    vps5)
      echo "Dar05dar05!!" | xclip -selection clipboard
      echo "ssh admin@151.80.119.73" | xclip -selection clipboard
      break
      ;;
    vps6)
      echo "Web06web06!!" | xclip -selection clipboard
      sleep 1
      echo "password copied"
      sleep 1
      echo "ssh webmaster@37.187.90.56" | xclip -selection clipboard
      break
      ;;
    vps6host)
      echo "Host06host06!!" | xclip -selection clipboard
      sleep 1
      echo "password copied"
      sleep 1
      echo "ssh host@37.187.90.56" | xclip -selection clipboard
      break
      ;;
    vps6admin)
      echo "Dar06dar06!!" | xclip -selection clipboard
      sleep 1
      echo "password copied"
      sleep 1
      echo "ssh admin@37.187.90.56" | xclip -selection clipboard
      break
      ;;
    *)
      echo "Invalid selection"
      ;;
  esac
done



