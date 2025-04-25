#! /bin/bash

host="google.meeet"
ping -c 1 $host
if [ $? -eq 0 ]; then
    echo "$host is reachable"
else
    echo "$host is not reachable"
fi
