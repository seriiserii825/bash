## read

```
echo "Linux:is:awesome." | (IFS=":" read -r var1 var2 var3; echo -e "$var1 n$var2 n$var3")
Linux
is
awesome.
```

Чтобы указать строку приглашения, используйте параметр -p . Подсказка печатается перед выполнением read и не включает новую строку.

```
read -r -p "Are you sure?"

while true; do
    read -r -p "Do you wish to reboot the system? (Y/N): " answer
    case $answer in
        [Yy]* ) reboot; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer Y or N.";;
    esac
done
```

Если сценарий оболочки просит пользователей ввести конфиденциальную информацию, например пароль, используйте параметр -s который сообщает read не печатать ввод на терминале:

```
read -r -s -p "Enter your password: "
```

Чтобы присвоить слова массиву вместо имен переменных, вызовите команду read с параметром -a :

```
read -r -a MY_ARR <<< "Linux is awesome."

for i in "${MY_ARR[@]}"; do
  echo "$i"
done
```
