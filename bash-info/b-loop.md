### while

```
myvar=1

while [ $myvar -le 10 ]
do
  echo $myvar
  myvar=$[ $myvar + 1 ]
  sleep 0.5
done

```

### read file

```

while IFS= read -r line;
do
    echo "$line"
done < $1
```

### print all directories or files

```
for item in *
do
    if [ -d $item ];
    then
        echo $item
    fi
done
```

### for

```
for i in 1 2 4 6
for i in {1..10..2} 2 - increment
for (( i=0; i<5; i++ ))
for VARIABLE in file1 file2 file3
for OTPUT in $(Linux-or-unix-command)
do
    echo "Hello World $i"
done
```

### break

```
for (( i=0; i<10; i++ ))
do
  if(( $i == 5 ))
  then
    break
  fi
    echo "Hello World $i"
done

```
