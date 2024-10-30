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
    next_endpoint_segment="/$(echo $endpoint | cut -d '/' -f $((endpoint_segment_index + 1)))"
}

next_segment?(){
    if [ $next_endpoint_segment = "/" ]; then
        next=false
    else
        next=true
    fi
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
    content_length=$(printf "%s" "$2" | wc -c)

    echo -e "HTTP/1.1 $1 $status\r\nContent-Type: application/json\r\nContent-Length: $content_length\r\n\n$2"
    exit $1
}

source config.ini

content_length=0
ip=$TCPREMOTEIP

# READ HEADERS
while read -r line; do
    line=$(echo "$line" | tr -d '[\r\n]')

    if [[ $line =~ HTTP/.*$ ]]; then
        method=$(echo "$line" | cut -d ' ' -f 1)
        endpoint=$(echo "$line" | cut -d ' ' -f 2)

        # Remove multiple slashes and ensure there is one trailing slash
        endpoint=$(echo "$endpoint" | sed -E 's|/{2,}|/|g' | sed -E 's|/$||')/

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

case $endpoint_segment in
    "/")
    # this doesnt need to use next_segment? because it will always be false
        case $method in
            "GET")
                response 200 "Lobbyn API v1 by soulspine"
                ;;
            *)
                error 405 "Invalid method"
                ;;
        esac
        ;;
    "/info")
    #this purposefully accepts any endpoint after /info
        case $method in
            "GET")
                response 200 "$(jo -p ip=$ip method=$method endpoint=$endpoint)"
                ;;
            *)
                error 405 "Invalid method"
                ;;
        esac
        ;;
    "/echo")
        case $method in
            "POST")
                next_segment?
                if [ $next = false ]; then
                    response 200 "$(jo message=$body)"
                else
                    error 404 "Endpoint not found."
                fi
                ;;
            *)
                error 405 "Invalid method"
                ;;
        esac
        ;;
    "/summoner")
        case $method in
            "GET")
                next_segment? #if segment is just /summoner - exit
                if [ $next = false ]; then
                    error 404 "Endpoint not found."
                fi

                segment++ #get next segment, this should be either /by-name/ or /by-puuid/

                if [ $endpoint_segment = "/by-name" ]; then
                    #echo "by-name"
                    next_segment?
                    if [ $next = false ]; then
                        error 404 "Endpoint not found."
                    fi

                    segment++ #get next segment, this should be the summoner name
                    summoner_name=${endpoint_segment:1}

                    next_segment?
                    if [ $next = false ]; then
                        error 404 "Endpoint not found."
                    fi

                    segment++ #get next segment, this should be the tagline
                    tagline=${endpoint_segment:1}

                    next_segment?
                    if [ $next = true ]; then
                        error 404 "Endpoint not found."
                    else
                        riot_account_response=$(curl -s -X GET "https://europe.api.riotgames.com/riot/account/v1/accounts/by-riot-id/$summoner_name/$tagline?api_key=$RIOT_API_KEY")
                        puuid=$(echo $riot_account_response | jq -r '.puuid')
                        riot_summoner_response=$(curl -s -X GET "https://eun1.api.riotgames.com/lol/summoner/v4/summoners/by-puuid/$puuid?api_key=$RIOT_API_KEY")
                        response 200 "$riot_summoner_response"
                    fi

                elif [ $endpoint_segment = "/by-puuid" ]; then
                echo "by-puuid"
                else
                    error 404 "Endpoint not found."
                fi

                ;;
            *)
                error 405 "Invalid method"
                ;;
        esac
        ;;
    *)
        error 404 "Endpoint not found."
        ;;
esac