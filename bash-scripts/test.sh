#! /bin/bash
name=$USER
# shor_name=$(cat /etc/passwd | grep $name | awk -F : '{print $5}' | cut -d "" -f1)
shor_name=$(cat /etc/passwd | grep $name | awk -F : '{print $6}' | cut -d / -f 3)
# shor_name=$(cat /etc/passwd | grep $name | awk -F : '{print $6}')
# shor_name=$(cat /etc/passwd | grep $name)
echo "Hello $shor_name"
