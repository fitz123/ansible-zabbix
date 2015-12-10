#!/bin/bash
##################################
# Zabbix monitoring script
#
# Naxsi rate using elasticsearch database
#
# https://gist.github.com/fitz123/6d8e03e8c287a6988553
#
##################################
# Contact:
#  anton.lugovoi@yandex.ru
##################################
# ChangeLog:
#  20151210    initial creation
##################################

es_addr='http://183.90.170.101:9200'
index_type='nginx'

last=`printf $1 2>/dev/null | grep -o '^[[:digit:]]*[smhdM]$'`
host=`printf $2 2>/dev/null | grep -Eo '^([[:lower:]]|[[:digit:]]|-)*$'`
tag=`printf $3 2>/dev/null | grep -Eo '^([[:alnum:]]|-|_)*$'`
error_type_raw=`printf $4 2>/dev/null | grep -Eo '^([[:alnum:]]|-|_)*$'`
match_message=`printf $5 2>/dev/null | grep -Eo '^([[:alnum:]]|-|_)*$'`

if [ "$1" == "help" ]; then
    printf "
    first parameter must be number followed by measure unit: s(sec), m(min), h(hour), d(day), M(month)
    second parameter: \"host\" may contain only the ASCII letters 'a' through 'z' (case-sensitive), the digits \'0\' through \'9\', and the hyphen
    third, fourth and fifth parameters must contain the ASCII letters 'a' through 'z' (case-insensitive), the digits \'0\' through \'9\', the hyphen and the underscore
    "
    echo
    echo "example: $0 1h knd3 error NAXSI NAXSI_FMT"
    exit 0
fi

if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    echo "for help use: $0 help"
    exit 0
fi

if [ -z "$last" ] || [ -z "$host" ] || [ -z "$tag" ] || [ -z "$error_type_raw" ] || [ -z "match_message" ]; then
    echo "Illegal parameter(s)"
    echo "for help use: $0 help"
    exit 0
fi

request=`printf "{
  \"query\": { 
    \"bool\": { 
      \"filter\": [ 
        { \"term\":  { \"tags\": \"$tag\" }},
        { \"term\":  { \"host.raw\": \"$host\" }},
        { \"term\" : { \"error.type.raw\": \"$error_type_raw\" }},
        { \"query\": { \"match\": { \"message\": \"$match_message\" }}},
        { \"range\": { \"@timestamp\": { \"gt\": \"now-$last\" }}}
      ]
    }
  }
}
"`
curl -XGET "$es_addr/_all/$index_type/_count" -d"$request" 2>/dev/null | grep -oP '(?<=\"count\":)[0-9]+'
#echo "curl -XGET \"$es_addr/_all/$index_type/_count\" -d\"$request\" 2>/dev/null | grep -oP '(?<=\"count\":)[0-9]+'"

exit 0
