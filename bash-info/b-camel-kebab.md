### change from camelCase to kebab-case

```
#!/bin/bash

# camelCase to kebab
sed -i -E 's/([a-z])([A-Z])/\1-\L\2/g'

# first upper camelCase to kebab-case
sed -E 's/(class=")([A-Z][a-zA-Z0-9]*)/\1\L\2/g' input.html > output.html

# class to lowercase

sed -i -e 's/class="\([^"]*\)"/class="\L\1"/g' $file_path
``
