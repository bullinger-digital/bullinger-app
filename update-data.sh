#/bin/sh

data="/Users/windauer/office/customers/bullinger/bullinger-data/data/index"
app="."

for path in $data/*.xml; do
    file=$(basename ${path%.*})
    url="http://localhost:8080/exist/apps/bullinger/api/cleanup-register-data/$file.xml"
    echo "Cleaning & downloading register data: $url"
    curl -X 'GET' \
        $url \
            -H 'accept: text/html' \
            -H 'Authorization: Basic YnVsbGluZ2VyOmJ1bGxpbmdlcg==' \
            -o "$data/$file.xml"
    echo "download cleaned up register file to: $data/$file.xml"
done



