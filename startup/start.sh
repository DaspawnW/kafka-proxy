#!/bin/sh

dnsServerHost=${DNS_SERVER_HOST}
dnsServerPort=${DNS_SERVER_PORT:-53}
txtDomain=${KAFKA_TXT_DNS}
mappingFile=${MAPPING_FILE:-"/opt/startup/mapping.json"}
bootstrapServerMapping=""

if [[ -z $txtDomain ]];
then
    echo "No KAFKA_TXT_DNS variable defined"
    exit 1
fi

if [[ -n $dnsServerHost ]];
then
    echo "Using custom DNS Server $dnsServerHost:$dnsServerPort"
    dnsServer="@$dnsServerHost -p $dnsServerPort"
fi

dnsServerMapping() {
    dnsRecord=$(dig $txtDomain txt $dnsServer +short | cut -d \" -f 2)
    mapped=$(cat $mappingFile | jq -r --arg RECORD "$dnsRecord" '.[$RECORD]')
    
    ## mapping returned an invalid result
    if [[ $mapped == "null" ]];
    then
        echo "null"
        return
    fi

    ## generate bootstrap-server-mapping per array entry
    bootstrapServerArgs=""
    for row in $(echo "${mapped}" | jq -r '.[] | @base64'); do
        _jq() {
            echo ${row} | base64 -q | jq -r ${1}
        }

        item=$(_jq '.' -r)
        bootstrapServerArgs="$bootstrapServerArgs --bootstrap-server-mapping $item"
    done

    echo $bootstrapServerArgs
}

bootstrapServerMapping=$(dnsServerMapping)

if [[ $bootstrapServerMapping == "null" ]];
then
    echo "Invalid DNS response for $txtDomain"
    exit 1
fi

echo "Starting kafka-proxy with bootstrap-server-mapping: $bootstrapServerMapping"
/opt/kafka-proxy/bin/kafka-proxy \
  server \
  $bootstrapServerMapping \
  "$@" &

KAFKA_PROXY_PID=$!

while true
do
    sleep 10

    changedBootstrapServerMapping=$(dnsServerMapping)
    if [[ $changedBootstrapServerMapping == "null" ]];
    then
        echo "Invalid dns response, continue..."
        continue
    fi

    if [[ $changedBootstrapServerMapping != $bootstrapServerMapping ]];
    then
        echo "Send kill command as bootstrapserver has changed..."
        kill -2 $KAFKA_PROXY_PID
        sleep 2
        exit 1
    fi
done