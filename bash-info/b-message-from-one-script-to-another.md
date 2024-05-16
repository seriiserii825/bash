### file1
```
MESSAGE="hello from script 1"
export MESSAGE
./file2.sh
```

### file2
```
echo "file2 message from script 1 is $MESSAGE"
```
