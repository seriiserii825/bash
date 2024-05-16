### output
```
ls -al 1>output.txt 2>error.txt

ls -al >output.txt

ls +al >file1.txt 2>&1 -- will place output or error in the same file
ls +al >& file1.txt -- will place output or error in the same file

```
