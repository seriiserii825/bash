### select
```
  backup_files=$(ls -t | grep '\.wpress')

  PS3='Please enter your choice: '
  select backup_file in $backup_files
  do
    wp ai1wm restore $backup_file
    wp rewrite flush
    exit 0
  done
```

### dynamic select
```
  select type in "page" "post_type" "taxonomy" "user" "comment" "option" "menu" "widget" "block" "exit"; do
    [[ $type ]] || continue
    break
  done
```

```
select car in BMW MERCEDES TESLA ROVER TOYOTA
do
  case $car in
    BMW)
      echo "BMW SELECTED";;
    MERCEDES)
      echo "MERCEDES SELECTED";;
    TESLA)
      echo "TESLA SELECTED";;
    ROVER)
      echo "ROVER SELECTED";;
    TOYOTA)
      echo "TOYOTA SELECTED";;
    *)
      echo "ERROR! Please select between 1..5";;
  esac
done
```

### default value
```

defaultOption="php" # Set the default option here
read -p "Select an option (php/scss/js/vue), by default is php: " choice
if [ -z "$choice" ]; then
  choice=$defaultOption
  echo "Default option selected: $choice"
fi

case $choice in
  php)
    phpCreate
    scssCreate
    echo "$file_path was created";
    ;;
  scss)
    echo "Selected: $choice"
    scssCreate
    echo "$file_path was created";
    ;;
  js)
    echo "Selected: $choice"
    jsCreate 
    echo "$file_path was created";
    ;;
  vue)
    echo "Selected: $choice"
    vueCreate 
    echo "$file_path was created";
    ;;
  *)
    echo "Invalid option selected"
    ;;
esac

```

### dynamic options
```
# Define an array of options
options=("option1" "option2" "option3")

# Prompt the user to select an option
echo "Select an option:"
for i in "${!options[@]}"; do
  echo "$i) ${options[i]}"
done

# Read the user's choice
read choice

# Use a case statement to perform actions based on the choice
case "$choice" in
  0) echo "You selected option1";;
  1) echo "You selected option2";;
  2) echo "You selected option3";;
  *) echo "Invalid choice";;
esac
```

### go back from select
```
anew=yes
while [ "$anew" = yes ]; do
   anew=no
   select x in a b c d
   do
      case $x in
         a) echo "a"
            anew=yes
            break;;
         b) echo "b";;
         c) echo "c";;
         d) echo "You are now exiting the program"
            break;;
         *) echo "Invalid entry. Please try an option on display";;
      esac
   done
done
```

### exit from nested select
```
while true; do
    select outer_choice in "Continue" "Exit"; do
        case $outer_choice in
            "Continue")
                echo "Continuing..."
                while true; do
                    select inner_choice in "Inner Continue" "Inner Exit"; do
                        case $inner_choice in
                            "Inner Continue")
                                echo "Inner continuing..."
                                # Your inner loop logic here
                                ;;
                            "Inner Exit")
                                echo "Exiting inner loop..."
                                break 2  # Breaks out of both inner and outer loops
                                ;;
                            *)
                                echo "Invalid inner choice. Try again."
                                ;;
                        esac
                    done
                done
                ;;
            "Exit")
                echo "Exiting..."
                exit
                ;;
            *)
                echo "Invalid choice. Try again."
                ;;
        esac
    done
done
```
