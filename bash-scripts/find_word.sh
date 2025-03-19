#!/bin/bash

echo -n "Word to find: "
read -r WORD

echo -n "File extension (without dot): "
read -r EXT

# Find word in files with extension using find and grep
# ignore dist build node_modules .git directories
find . -type f -not -path '*/\.*' -not -path '*/dist/*' -not -path '*/build/*' -not -path '*/node_modules/*' -not -path '*/.git/*' -name "*.$EXT" -exec grep -Hn "$WORD" {} \;
# find . -type f -name "*.$EXT" -exec grep -Hn "$WORD" {} \;

 
#  The script will ask for the word to find and the file extension. It will then search for the word in all files with the specified extension in the current directory and its subdirectories. 
#  To make the script executable, run the following command: 
#  chmod +x find_word.sh
#  
#  You can then run the script by typing: 
#  ./find_word.sh
#  
#  The script will prompt you for the word and file extension and then display the results. 
#  Conclusion 
#  In this tutorial, you learned how to use the  find  command in Linux to search for files and directories based on various criteria. You also learned how to combine the  find  command with other commands like  grep  to search for files containing specific text. 
#  If you have any questions or feedback, feel free to leave a comment. 
#  If you liked this article, then do  subscribe to email alerts for Linux tutorials. If you have any questions or doubts? do  ask for help in the comments section. 
#  TecMint is the fastest growing and most trusted community site for any kind of Linux Articles, Guides and Books on the web. Millions of people visit TecMint! to search or browse the thousands of published articles available FREELY to all. 
#  If you like what you are reading, please consider buying us a coffee ( or 2 ) as a token of appreciation. 
#  We are thankful for your never ending support. 
#  I have a question. I have a directory with a lot of files and subdirectories. I want to find all files that are not in a subdirectory. How can I do that? 
#  You can use the following command to find all files that are not in a subdirectory: 
#  find . -maxdepth 1 -type f
#  
#  This command will search for files in the current directory only.
