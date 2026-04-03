function findPortInFile(){
    local filePath="$1"
    local port="PORT"

    if [[ -f "$filePath" ]]; then
        if grep -q "$port" "$filePath"; then
            echo "Port $port found in $filePath"
            return 0
        else
            echo "Port $port not found in $filePath"
            return 1
        fi
    else
        echo "File $filePath does not exist."
        return 2
    fi
}
