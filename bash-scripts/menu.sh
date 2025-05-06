#! /bin/bash

options="One Two Three Four Five Six Seven Eight Nine Ten"

COLUMNS=1
select opt in $options; do
  echo "REPLY: $REPLY"
  echo "opt: $opt"
  case $opt in
    One)
      echo "You chose One"
      ;;
    Two)
      echo "You chose Two"
      ;;
    Three)
      echo "You chose Three"
      ;;
    Four)
      echo "You chose Four"
      ;;
    Five)
      echo "You chose Five"
      ;;
    Six)
      echo "You chose Six"
      ;;
    Seven)
      echo "You chose Seven"
      ;;
    Eight)
      echo "You chose Eight"
      ;;
    Nine)
      echo "You chose Nine"
      ;;
    Ten)
      echo "You chose Ten"
      ;;
    *)
      break
  esac
done
