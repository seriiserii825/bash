#!/bin/bash
current_date=`date +%m-%d-%Y`
current_time=`date | awk '{print $4}'`
date=`echo $current_date`
time=`echo $current_time`
start=`echo $date $time`
echo "Start = $start"
current_start=$current_date@:$current_time
echo "${tmagenta}Running your bash script ...${treset}"


sudo apt update
sudo apt -y upgrade
sudo apt  -y autoremove
sudo apt autoclean

# Finish time
current_date=`date +%m-%d-%Y`
current_time=`date | awk '{print $4}'`
date=`echo $current_date`
time=`echo $current_time`
finish=`echo $date $time`
echo "${tblue}Finish = $finish${treset}"
current_finish=$current_date@:$current_time
echo
date2sec() { date -d "$(sed 's|-|/|g; s|@| |; s|:| |' <<<"$*")" +%s; }
second=`echo $(( $(date2sec "$current_finish") - $(date2sec "$current_start") ))`
echo "${tgreen}Your bash script needs $second second to process${treset}"
