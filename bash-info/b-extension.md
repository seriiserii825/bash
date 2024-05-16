## extract extension

```
f='/path/to/complex/file.1.0.1.tar.gz'

# Filename : 'file.1.0.x.tar.gz'
    echo "$f" | awk -F'/' '{print $NF}'

# Extension (last): 'gz'
    echo "$f" | awk -F'[.]' '{print $NF}'
    
# Extension (all) : '1.0.1.tar.gz'
    echo "$f" | awk '{sub(/[^.]*[.]/, "", $0)} 1'
    
# Extension (last-2): 'tar.gz'
    echo "$f" | awk -F'[.]' '{print $(NF-1)"."$NF}'

# Basename : 'file'
    echo "$f" | awk '{gsub(/.*[/]|[.].*/, "", $0)} 1'

# Basename-extended : 'file.1.0.1.tar'
    echo "$f" | awk '{gsub(/.*[/]|[.]{1}[^.]+$/, "", $0)} 1'

# Path : '/path/to/complex/'
    echo "$f" | awk '{match($0, /.*[/]/, a); print a[0]}'
    # or 
    echo "$f" | grep -Eo '.*[/]'
    
# Folder (containing the file) : 'complex'
    echo "$f" | awk -F'/' '{$1=""; print $(NF-1)}'
    
# Version : '1.0.1'
    # Defined as 'number.number' or 'number.number.number'
    echo "$f" | grep -Eo '[0-9]+[.]+[0-9]+[.]?[0-9]?'

    # Version - major : '1'
    echo "$f" | grep -Eo '[0-9]+[.]+[0-9]+[.]?[0-9]?' | cut -d. -f1

    # Version - minor : '0'
    echo "$f" | grep -Eo '[0-9]+[.]+[0-9]+[.]?[0-9]?' | cut -d. -f2

    # Version - patch : '1'
    echo "$f" | grep -Eo '[0-9]+[.]+[0-9]+[.]?[0-9]?' | cut -d. -f3

# All Components : "path to complex file 1 0 1 tar gz"
    echo "$f" | awk -F'[/.]' '{$1=""; print $0}'
    
# Is absolute : True (exit-code : 0)
    # Return true if it is an absolute path (starting with '/' or '~/'
    echo "$f" | grep -q '^[/]\|^~/'
 
```
