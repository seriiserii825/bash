# check errors
some_command
if [ $? -eq 0 ]; then
    echo OK
else
    echo FAIL
fi
