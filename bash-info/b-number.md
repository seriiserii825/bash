### sum

```
n1=4
n2=6
echo $(( n1 + n2 ))
echo $(( n1 - n2 ))
echo $(( n1 * n2 ))
echo $(( n1 / n2 ))
echo $(( n1 % n2 ))
```

### floating

```
n1=20.5
n2=4
echo "$n1+$n2" | bc
echo "scale=2;$n1+$n2" | bc -- scale 0 after dots
```

### check number

```
re='^[0-9]+$'
if ! [[ $num =~ $re ]] ; then
   echo "error: Not a number" >&2; exit 1
fi
```

```bash
IFS=', ' read -r -a array <<< "$string"
```

Note that the characters in `$IFS` are treated individually as separators so that in this case fields may be separated by _either_ a comma or a space rather than the sequence of the two characters. Interestingly though, empty fields aren't created when comma-space appears in the input because the space is treated specially.

To access an individual element:

```bash
echo "${array[0]}"
```

To iterate over the elements:

```bash
for element in "${array[@]}"
do
    echo "$element"
done
```

To get both the index and the value:

```bash
for index in "${!array[@]}"
do
    echo "$index ${array[index]}"
done
```

The last example is useful because Bash arrays are sparse. In other words, you can delete an element or add an element and then the indices are not contiguous.

```bash
unset "array[1]"
array[42]=Earth
```

To get the number of elements in an array:

```bash
echo "${#array[@]}"
```

As mentioned above, arrays can be sparse so you shouldn't use the length to get the last element. Here's how you can in Bash 4.2 and later:

```bash
echo "${array[-1]}"
```

in any version of Bash (from somewhere after 2.05b):

```bash
echo "${array[@]: -1:1}"
```
