### trim white space

```
#!/bin/bash
echo "  It is     a    bright    day       today    " | tr -s '[:blank:]'
echo "  It is     a    bright    day       today    " | sed -r 's/[[:blank:]]+/ /g'
```
