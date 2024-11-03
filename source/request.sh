#!/usr/bin/env bash

#LOBBTN_RIOT_USER - the user object from the riot api
#LOBBYN_ERROR_MESSAGE - error message
#LOBBYN_ERROR_CODE - error code

source source/riot.sh
source source/user.sh

ARGON2_ITERATIONS=20
ARGON2_MEMORY=4096
ARGON2_PARALLELISM=4
ARGON2_LENGTH=32

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
        100)
            status="Continue"
            ;;
        101)
            status="Switching Protocols"
            ;;
        102)
            status="Processing"
            ;;
        103)
            status="Early Hints"
            ;;
        200)
            status="OK"
            ;;
        201)
            status="Created"
            ;;
        202)
            status="Accepted"
            ;;
        203)
            status="Non-Authoritative Information"
            ;;
        204)
            status="No Content"
            ;;
        205)
            status="Reset Content"
            ;;
        206)
            status="Partial Content"
            ;;
        207)
            status="Multi-Status"
            ;;
        208)
            status="Already Reported"
            ;;
        226)
            status="IM Used"
            ;;
        300)
            status="Multiple Choices"
            ;;
        301)
            status="Moved Permanently"
            ;;
        302)
            status="Found"
            ;;
        303)
            status="See Other"
            ;;
        304)
            status="Not Modified"
            ;;
        305)
            status="Use Proxy"
            ;;
        307)
            status="Temporary Redirect"
            ;;
        308)
            status="Permanent Redirect"
            ;;
        400)
            status="Bad Request"
            ;;
        401)
            status="Unauthorized"
            ;;
        402)
            status="Payment Required"
            ;;
        403)
            status="Forbidden"
            ;;
        404)
            status="Not Found"
            ;;
        405)
            status="Method Not Allowed"
            ;;
        406)
            status="Not Acceptable"
            ;;
        407)
            status="Proxy Authentication Required"
            ;;
        408)
            status="Request Timeout"
            ;;
        409)
            status="Conflict"
            ;;
        410)
            status="Gone"
            ;;
        411)
            status="Length Required"
            ;;
        412)
            status="Precondition Failed"
            ;;
        413)
            status="Payload Too Large"
            ;;
        414)
            status="URI Too Long"
            ;;
        415)
            status="Unsupported Media Type"
            ;;
        416)
            status="Range Not Satisfiable"
            ;;
        417)
            status="Expectation Failed"
            ;;
        426)
            status="Upgrade Required"
            ;;
        500)
            status="Internal Server Error"
            ;;
        501)
            status="Not Implemented"
            ;;
        502)
            status="Bad Gateway"
            ;;
        503)
            status="Service Unavailable"
            ;;
        504)
            status="Gateway Timeout"
            ;;
        505)
            status="HTTP Version Not Supported"
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

if [ ! -z "$body" ]; then
    logmessage="$logmessage, Body: \"$body\""
fi

log "$logmessage"

segment++ #needed to get the first segment

logic_path="endpoints"

# special case, we want to map everything starting with info to respond with the whole endpoint
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