function multipleSelect() {
  result=()
  # Usage: multipleSelect choice1 choice2 ...
  local all_choices=("$@")
  local choices=("$@")
  choices=("All" "${choices[@]}")
  # initialize the counter
  local i=0
  # present numbered choices to user
  COLUMNS=1
  select dummy in "${choices[@]}"; do 
    # Parse ,-separated numbers entered into an array.
    # -r prevents backslash escapes from being interpreted.
    # -a assigns the words read to sequential indices of the array variable.
    # Variable $REPLY contains whatever the user entered.
    IFS=', ' read -ra selChoices <<<"$REPLY"
    # Loop over all numbers entered.
    for choice in "${selChoices[@]}"; do
      # Validate the number entered.
      (( choice >= 1 && choice <= ${#choices[@]} )) || { echo "Invalid choice: $choice. Try again." >&2; continue 2; }
      # If valid, echo the choice and its number.
      # echo "Choice #$(( ++i )): ${choices[choice-1]} ($choice)"
      result+=("${choices[choice-1]}")
    done

    [[ ${result[*]} =~ "All" ]] && echo "${all_choices[@]}" || echo "${result[@]}"

    break
  done
}
