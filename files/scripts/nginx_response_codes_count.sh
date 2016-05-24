#!/bin/bash
##################################
# Zabbix monitoring script
#
# Nginx response codes count
# using elasticsearch database
#
# https://gist.githubusercontent.com/fitz123/433561fac586713685cd/raw/9a6b7eb6704b9a1ec270673f2997105c4a95ff0c/nginx_response_codes_count.sh
#
##################################
# Contact:
#  anton.lugovoi@yandex.ru
##################################
# ChangeLog:
#  20151210    initial creation
##################################

es_addr='http://es.service.cs.consul:9200'
index_type='nginx'

last=`printf $1 2>/dev/null | grep -o '^[[:digit:]]*[smhdM]$'`
host=`printf $2 2>/dev/null | grep -Eo '^([[:lower:]]|[[:digit:]]|-)*$'`
gte=`printf $3 2>/dev/null | grep -o '^[[:digit:]]*$'`
lte=`printf $4 2>/dev/null | grep -o '^[[:digit:]]*$'`

if [ "$1" == "help" ]; then
    printf "
    first parameter must be number followed by measure unit: s(sec), m(min), h(hour), d(day), M(month)
    second parameter: \"host\" may contain only the ASCII letters 'a' through 'z' (case-insensitive), the digits \'0\' through \'9\', and the hyphen
    third and fourth parameters must contain digits only
    "
    echo
    echo "example: $0 10m knd2 200 399"
    exit 0
fi

if [ "$#" -ne 4 ]; then
    echo "Illegal number of parameters"
    echo "for help use: $0 help"
    exit 0
fi

if [ -z "$last" ] || [ -z "$host" ] || [ -z "$gte" ] || [ -z "$lte" ] ; then
    echo "Illegal parameter(s)"
    echo "for help use: $0 help"
    exit 0
fi

request=`printf "{
  \"query\": { 
    \"bool\": { 
      \"filter\": [ 
        { \"term\":  { \"tags\": \"access\" }},
        { \"term\":  { \"host.raw\": \"$host\" }},
        { \"range\": { \"response.code\": { \"gte\": \"$gte\", \"lte\": \"$lte\" }}},
        { \"range\": { \"@timestamp\": { \"gt\": \"now-$last\" }}}
      ]
    }
  }
}
"`

curl -XGET "$es_addr/_all/$index_type/_count" -d"$request" 2>/dev/null | grep -oP '(?<=\"count\":)[0-9]+'

exit 0
