# Azure Search output plugin for Embulk

embulk-output-azuresearch is an embulk output plugin that dumps records to Azure Search. Embulk is a open-source bulk data loader that helps data transfer between various databases, storages, file formats, and cloud services. See [Embulk documentation](http://www.embulk.org/docs/) for details.

## Overview

* **Plugin type**: output
* **Load all or nothing**: no
* **Resume supported**: no
* **Cleanup supported**: yes

## Installation

    $ gem install fluent-plugin-azuresearch

## Configuration

### Azure Search

To use Microsoft Azure Search, you must create an Azure Search service in the Azure Portal. Also you must have an index, persisted storage of documents to which embulk-output-azuresearch writes event stream out. Here are instructions:

 * [Create a service](https://azure.microsoft.com/en-us/documentation/articles/search-create-service-portal/)
 * [Create an index](https://azure.microsoft.com/en-us/documentation/articles/search-what-is-an-index/)


<u>Sample Index Schema: sampleindex01</u>

```json
{
    "name": "sampleindex01",
    "fields": [
        { "name":"id", "type":"Edm.String", "key": true, "searchable": false },
        { "name":"title", "type":"Edm.String", "analyzer":"en.microsoft" },
        { "name":"speakers", "type":"Edm.String" },
        { "name":"url", "type":"Edm.String", "searchable": false, "filterable":false, "sortable":false, "facetable":false },
        { "name":"text", "type":"Edm.String", "filterable":false, "sortable":false, "facetable":false, "analyzer":"en.microsoft" }
    ]
}
```


### Embulk Configuration (config.yml)

```yaml
out:
  type: azuresearch
  endpoint: https://yoichikademo.search.windows.net
  api_key:  9E55964F8254BB4504DX3F66A39AF5EB
  search_index: sampleindex01
  column_names: id,title,speakers,text,url
  key_names: id,title,speakers,description,link
```

 * **endpoint (required)** - Azure Search service endpoint URI
 * **api\_key (required)** - Azure Search API key
 * **search\_index (required)** - Azure Search Index name to insert records
 * **column\_names (required)** - Column names in a target Azure search index. Each column needs to be separated by a comma.
 * **key\_names (optional)** - Default:nil. Key names in incomming record to insert. Each key needs to be separated by a comma. By default, **key\_names** is as same as **column\_names**


## Sample Configurations

### (1) Case: column_names and key_names are same

Suppose you have the following config.yml and sample azure search index schema written above:

<u>config.yml</u>

```yaml
in:
  type: file
  path_prefix: samples/sample_01.csv
  parser:
    charset: UTF-8
    newline: CRLF
    type: csv
    delimiter: ','
    quote: '"'
    escape: '"'
    null_string: 'NULL'
    trim_if_not_quoted: false
    skip_header_lines: 1
    allow_extra_columns: false
    allow_optional_columns: false
    columns:
    - {name: id, type: string}
    - {name: title, type: string}
    - {name: speakers, type: string}
    - {name: text, type: string}
    - {name: url, type: string}
out:
  type: azuresearch
  endpoint: https://yoichikademo.search.windows.net
  api_key:  9E55964F8254BBXX04D53F66A39AF5EB
  search_index: sampleindex01
  column_names: id,title,speakers,text,url
```

The plugin will dump records out to Azure Ssearch like this:

<u>Input CSV</u>

```csv
id,title,speakers,text,url
1,Moving to the Cloud,Narayan Annamalai,Benefits of moving your applications to cloud,https://s.ch9.ms/Events/Build/2016/P576
2,Building Big Data Applications using Spark and Hadoop,Maxim Lukiyanov,How to leverage Spark to build intelligence into your application,https://s.ch9.ms/Events/Build/2016/P420
3,Service Fabric Deploying and Managing Applications with Service Fabric,Chacko Daniel,Service Fabric deploys and manages distributed applications built as microservices,https://s.ch9.ms/Events/Build/2016/P431
```

<u>Output JSON Body to Azure Search</u>

```json
{"value":
    [
        {"id":"1","title":"Moving to the Cloud","speakers":"Narayan Annamalai","text":"Benefits of moving your applications to cloud","url":"https://s.ch9.ms/Events/Build/2016/P576","@search.action":"mergeOrUpload"},
        {"id":"2","title":"Building Big Data Applications using Spark and Hadoop","speakers":"Maxim Lukiyanov","text":"How to leverage Spark to build intelligence into your application","url":"https://s.ch9.ms/Events/Build/2016/P420","@search.action":"mergeOrUpload"},
        {"id":"3","title":"Service Fabric Deploying and Managing Applications with Service Fabric","speakers":"Chacko Daniel","text":"Service Fabric deploys and manages distributed applications built as microservices","url":"https://s.ch9.ms/Events/Build/2016/P431","@search.action":"mergeOrUpload"}
    ]
}
```

### (2) Case: column_names and key_names are NOT same

Suppose you have the following config.yml and sample azure search index schema written above:

<u>config.yml</u>

```yaml
in:
  type: file
  path_prefix: samples/sample_01.csv
  parser:
    charset: UTF-8
    newline: CRLF
    type: csv
    delimiter: ','
    quote: '"'
    escape: '"'
    null_string: 'NULL'
    trim_if_not_quoted: false
    skip_header_lines: 1
    allow_extra_columns: false
    allow_optional_columns: false
    columns:
    - {name: id, type: string}
    - {name: title, type: string}
    - {name: speakers, type: string}
    - {name: description, type: string}
    - {name: link, type: string}
out:
  type: azuresearch
  endpoint: https://yoichikademo.search.windows.net
  api_key:  9E55964F8254BBXX04D53F66A39AF5EB
  search_index: sampleindex01
  column_names: id,title,speakers,description,link
  key_names: id,title,speakers,text,url
```


The plugin will dump records out to Azure Ssearch like this:

<u>Input CSV</u>

```csv
id,title,speakers,description,link
1,Moving to the Cloud,Narayan Annamalai,Benefits of moving your applications to cloud,https://s.ch9.ms/Events/Build/2016/P576
2,Building Big Data Applications using Spark and Hadoop,Maxim Lukiyanov,How to leverage Spark to build intelligence into your application,https://s.ch9.ms/Events/Build/2016/P420
3,Service Fabric Deploying and Managing Applications with Service Fabric,Chacko Daniel,Service Fabric deploys and manages distributed applications built as microservices,https://s.ch9.ms/Events/Build/2016/P431
```

<u>Output JSON Body to Azure Search</u>

```json
{"value":
    [
        {"id":"1","title":"Moving to the Cloud","speakers":"Narayan Annamalai","text":"Benefits of moving your applications to cloud","url":"https://s.ch9.ms/Events/Build/2016/P576","@search.action":"mergeOrUpload"},
        {"id":"2","title":"Building Big Data Applications using Spark and Hadoop","speakers":"Maxim Lukiyanov","text":"How to leverage Spark to build intelligence into your application","url":"https://s.ch9.ms/Events/Build/2016/P420","@search.action":"mergeOrUpload"},
        {"id":"3","title":"Service Fabric Deploying and Managing Applications with Service Fabric","speakers":"Chacko Daniel","text":"Service Fabric deploys and manages distributed applications built as microservices","url":"https://s.ch9.ms/Events/Build/2016/P431","@search.action":"mergeOrUpload"}
    ]
}
```


## Build, Install, and Run

```
$ rake

$ embulk gem install pkg/embulk-output-azuresearch-0.1.0.gem

$ embulk preview config.yml

$ embulk run config.yml

```

## Change log
* [Changelog](ChangeLog.md)

## Links

* http://yokawasa.github.io/embulk-output-azuresearch
* https://rubygems.org/gems/embulk-output-azuresearch/
* http://unofficialism.info/posts/embulk-plugins-for-microsoft-azure-services/

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yokawasa/embulk-output-azuresearch.

## Copyright

<table>
  <tr>
    <td>Copyright</td><td>Copyright (c) 2016- Yoichi Kawasaki</td>
  </tr>
  <tr>
    <td>License</td><td>MIT</td>
  </tr>
</table>

