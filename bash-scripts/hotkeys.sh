#!/bin/bash
grep "^[ ]*bindsym" ~/.i3/config | sed -e 's/^[ ]*bindsym //' -e 's/^[ ]*$mod/win/' | less
