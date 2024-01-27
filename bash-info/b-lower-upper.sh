declare -l lcfn # contents will be converted to lowercase
for FN in *.JPG
do
 lcfn="$FN"
 mv "$FN" "$lcfn"
done

# There are similar declarations for variables that change the case of all letters or only
# the first letter. Here’s a simple demonstration program to show how they work:

declare -u UP # all UPPERCASE
declare -l dn # all lowercase
declare -c Ca # only the first Uppercase
while read TXT
do
 UP="${TXT}"
 dn="${TXT}"
 Ca="${TXT}"
 echo $TXT $UP $dn $Ca
done

#camelCase
while read TXT
do
 RA=($TXT) # must be ($ not $(
 echo ${RA[@]^}
done
