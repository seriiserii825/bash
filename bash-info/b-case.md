### case

```
if [ ! $# -gt 0 ]; then
    echo "Insert argument"
    exit 1
fi

vehicle=$1

# if capital don't wor, change LANG to C, LANG=C
# for special char set "?" in terminal
case $vehicle in
    [a-z] )
        echo "Lower case" ;;
    [A-Z] )
        echo "Uppercase" ;;
    [0-9] )
        echo "Number" ;;
    ? )
        echo "One special char" ;;
    * )
        echo "More special chars" ;;
esac

```
