#!/bin/bash
for win in $(i3-msg -t get_tree | jq -r '.. | objects | select(.window and .focused == false) | .id'); do
    i3-msg "[con_id=$win] kill"
done
