### readonly var

```
var=30
readonly var
var=50
echo "var => $var"
```

### function

```
hello() {
    echo "some"
}
readonly -f hello
hello() {
    echo "new"
}
```

### check readonly
```
readonly # check var
readonly -f # check function
```
