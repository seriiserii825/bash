
# Define a function that returns an array
function return_array() {
    local my_array=("apple" "banana" "cherry")
    echo "${my_array[@]}"
}

# Call the function and capture the result in a variable
result=($(return_array))

# Print the elements of the returned array
for element in "${result[@]}"; do
    echo "$element"
done
