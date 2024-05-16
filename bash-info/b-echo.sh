# -n
echo -n "some text"
echo -n "new text"

# result (stdout)
# sometextnewtext

# -e
echo -e "some text\nnew text" 
echo -e "some text\tnew text"

# result (stdout)
# some text
# new text
# some text	new text
