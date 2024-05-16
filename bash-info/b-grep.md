### grep

```
echo "Enter file name to search text from"
read file_name

if [ -f $file_name ]
then
  echo "Enter text to search"
  read text
  # -c - show count
  grep -i -n $text $file_name
else
  echo "File '$file_name' does not exist"
fi
```
