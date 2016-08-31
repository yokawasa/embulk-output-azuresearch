#!/bin/sh

SERVICE_NAME='yoichikademo'
API_KEY='9E55964F8254BBXX04D53F66A39AF5EB'

URL="https://${SERVICE_NAME}.search.windows.net/indexes?api-version=2015-02-28"
curl -s\
 -H "Content-Type: application/json"\
 -H "api-key: ${API_KEY}"\
 -XPOST $URL -d'{
    "name": "sampleindex01",
    "fields": [
        { "name":"id", "type":"Edm.String", "key": true, "searchable": false, "filterable":true, "facetable":false },
        { "name":"title", "type":"Edm.String", "searchable": true, "filterable":true, "sortable":true, "facetable":false, "analyzer":"en.microsoft" },
        { "name":"speakers", "type":"Edm.String", "searchable": false },
        { "name":"url", "type":"Edm.String", "searchable": false, "filterable":false, "sortable":false, "facetable":false },
        { "name":"text", "type":"Edm.String", "searchable": true, "filterable":false, "sortable":false, "facetable":false, "analyzer":"en.microsoft" }
     ]
}'
