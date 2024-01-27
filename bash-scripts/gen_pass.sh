#!/bin/bash

# Define the character set for the password
CHARACTER_SET="AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789!@#$%^&*"

defaultOption=12 # Set the default option here


select action in WITH_CHARS WITHOUT_CHARS
do
  case $action in
    WITH_CHARS)
      CHARACTER_SET="$CHARACTER_SET"
      break
      ;;
    WITHOUT_CHARS)
      CHARACTER_SET="AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz0123456789"
      break
      ;;
    *)
      echo "WITH_CHARS"
      CHARACTER_SET="$CHARACTER_SET"
      break
      ;;
  esac
done

read -p "Select password length, by default is $defaultOption: " choice
if [ -z "$choice" ]; then
  choice=$defaultOption
fi

# Use /dev/urandom to generate random bytes and convert them to characters
password=""
for i in $(seq 1 $choice); do
    random_byte=$(od -An -N1 -i /dev/urandom)
    index=$((random_byte % ${#CHARACTER_SET}))
    password="${password}${CHARACTER_SET:index:1}"
done

# Print the generated password
echo "Generated password: $password"
# Remove the newline character using tr
echo $password | tr -d '\n' | xsel -b -i 
