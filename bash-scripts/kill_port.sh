#!/bin/bash

read -p "Enter port number: " port
fuser -k $port/tcp && echo 'Terminated' || echo "Nothing was running on the $port"
# fuser -k $port_number/tcp && echo 'Terminated' || echo "Nothing was running on the $port_number"
