#!/usr/bin/env bash

log(){
    echo "[$(date '+%d-%m-%Y %H:%M:%S')] $1" >> lobbyn.log
}

error(){
    response $1 "$(jo error="$2")"
}

segment++(){
    if [ -z $endpoint_segment_index ]; then
        endpoint_segment_index=1
    fi
    endpoint_segment_index=$((endpoint_segment_index + 1))
    endpoint_segment="/$(echo $endpoint | cut -d '/' -f $endpoint_segment_index)"
}

response(){
    local status
    case $1 in
        200)
            status="OK"
            ;;
        404)
            status="Not Found"
            ;;
        405)
            status="Method Not Allowed"
            ;;
        *)
            status="Internal Server Error"
            ;;
    esac

    local content_length
    content_length=$(echo -e -n "$2" | wc -c)

    echo -e "HTTP/1.1 $1 $status\r\nContent-Type: application/json\r\nContent-Length: $content_length\r\n\n$2"
    exit $1
}

source config.ini

content_length=0
ip=$TCPREMOTEIP

# READ HEADERS
while read -r line; do
    line=$(echo "$line" | tr -d '[\r\n]')

    #echo "$line" >> lobbyn.log

    if [[ $line =~ HTTP/.*$ ]]; then
        method=$(echo "$line" | cut -d ' ' -f 1)
        endpoint=$(echo "$line" | cut -d ' ' -f 2)

        # Remove multiple slashes and ensure there is one trailing slash
        endpoint=$(echo "$endpoint" | sed -E 's|/{2,}|/|g' | sed -E 's|/$||')/

    elif [[ $line =~ "PROXY" ]]; then
        ip=$(echo "$line" | cut -d ' ' -f 3)

    elif [[ $line =~ "Content-Length: " ]]; then
        content_length=$(echo "$line" | cut -d ' ' -f 2)

    elif [ "x$line" = "x" ]; then
        break
    fi
done

# READ BODY
if [ $content_length -gt 0 ]; then
    read -t $BODY_READ_TIMEOUT -r -N $content_length body

    if [ ${#body} -ne $content_length ]; then
        error 400 "Bad Request. Invalid Content-Length value."
    fi

fi

logmessage="IP: $ip, Method: $method, endpoint: $endpoint"
if [ ! -z $body ]; then
    logmessage="$logmessage, Body: \"$body\""
fi

log "$logmessage"

segment++ #needed to get the first segment

logic_path="endpoints"

# special case, we want to map everything starting with info there to respond with the whole endpoint
if [ "$endpoint_segment" = "/info" ]; then
    source "endpoints/info"
fi

while [ ! $endpoint_segment = "/" ]; do
    logic_path="$logic_path$endpoint_segment"
    segment++
done

if [ ! -d "$logic_path" ]; then
    error 404 "Endpoint not found."
elif [ ! -f "$logic_path/$method" ]; then
    error 405 "Invalid method."
else
    dos2unix "$logic_path/$method"
    source "$logic_path/$method"
fi