### run script

---

```
#! /bin/bash

sudo chmod +x script.sh
```

### bash scripts globally

- Create a folder in your home directory called bin. (For your personal scripts)
- cd ~ (Takes you to your home directory)
- mkdir bin (create a bin folder)
- vim .bash_profile (to set path environment variable)
- export PATH=~/bin:$PATH (Press i then add this line and then do esc and type :wq)
- Now you can just type the name of your script and run it from anywhere you want.
