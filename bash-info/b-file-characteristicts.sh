if [ -d "$DIRPLACE" ]
then
 cd $DIRPLACE
140 | Chapter 6: Shell Logic and Arithmetic
 if [ -e "$INFILE" ]
 then
 if [ -w "$OUTFILE" ]
 then
 doscience < "$INFILE" >> "$OUTFILE"
 else
 echo "cannot write to $OUTFILE"
 fi
 else
 echo "cannot read from $INFILE"
 fi
else
 echo "cannot cd into $DIRPLACE"
fi


-b File is a block special device (for les like /dev/hda1)
-c File is character special (for les like /dev/tty)
-d File is a directory
-e File exists
-f File is a regular le
-g File has its set-group-ID (setgid) bit set
-h File is a symbolic link (same as -L)
-G File is owned by the eective group ID
-k File has its sticky bit set
-L File is a symbolic link (same as -h)
-N File has been modied since it was last read
-O File is owned by the eective user ID
-p File is a named pipe
-r File is readable
-s File has a size greater than zero
-S File is a socket
-u File has its set-user-ID (setuid) bit set
-w File is writable
-x File is executable
