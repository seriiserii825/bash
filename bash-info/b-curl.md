### curl

```
url="https://www.dundeecity.gov.uk/sites/default/files/publications/civic_renewal_forms.zip"
# curl $url -O -- download original file name

# curl $url > myfilename
curl_status=$(curl -s -o /dev/null -w "%{http_code}" $url)

if [ $curl_status -eq 200 ]; then
    echo "File exists"
    curl $url -O
else
    echo "File does not exist"
fi
```
