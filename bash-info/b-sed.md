### sed

```
echo "Enter file name to search text from"
read file_name

if [ -f $file_name ]
then
    ## this command will not change the file, just show output
   sed 's/i/I/g' $file_name

   ## this command will change the file
   sed -i 's/i/I/g' $file_name
else
  echo "File '$file_name' does not exist"
fi
```
