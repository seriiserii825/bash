### debug

```
#! /bin/bash  -x
```

### second set -x and +x
```
if [-f $file_name ]
then
    ## this command will not change the file, just show output
   sed 's/i/I/g' $file_name

set -x
   ## this command will change the file
   sed -i 's/i/I/g' $file_name
set +x
else
  echo "File '$file_name' does not exist"
fi
```
