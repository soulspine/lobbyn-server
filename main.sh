#!/usr/bin/env bash

DEFAULT_PORT=8080
DEFAULT_RIOT_API_KEY="YOUR_RIOT_API_KEY"

log(){
    echo -e "[$(date '+%d-%m-%Y %H:%M:%S')] $1" | tee -a lobbyn.log
}

error(){
    response $1 "$(jo error="$2")"
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
        *)
            status="Internal Server Error"
            ;;
    esac

    echo -e "HTTP/1.1 $1 $status\r\nContent-Type: application/json\r\n\n$2" > out
}



# Start of the script

if [ -f config.ini ]; then
    source config.ini
else
    echo "RIOT_API_KEY=\"$DEFAULT_RIOT_API_KEY\"" >> config.ini
    echo "PORT=$DEFAULT_PORT" >> config.ini
    echo "Default config file created at $(pwd)/config.ini - Update configuration values and run the script again."
    exit 1
fi

if [ "$RIOT_API_KEY" == "$DEFAULT_RIOT_API_KEY" ] || [ ! ${#RIOT_API_KEY} -eq 42 ]; then
    echo "Invalid RIOT_API_KEY"
    config_valid="false"
fi

if [ ! -z $config_valid ]; then
    echo "Update configuration values in config.ini and run the script again."
    exit 2
fi

rm -f out
mkfifo out
trap "rm -f out" EXIT

log "Server started at port $PORT"

while true; do
    cat out | nc -Nnlvp $PORT > >(
        method=""
        path=""
        ip=""
        
        while read -r line; do
            line=$(echo "$line" | tr -d '[\r\n]')

            if [[ $line =~ HTTP/.*$ ]]; then

                method=$(echo "$line" | cut -d ' ' -f 1)
                path=$(echo "$line" | cut -d ' ' -f 2)

                # Remove multiple slashes and ensure there is one trailing slash
                path=$(echo "$path" | sed -E 's|/{2,}|/|g' | sed -E 's|/$||')/
                
            elif [[ $line =~ "Connection received on" ]]; then

                ip=$(echo "$line" | cut -d ' ' -f 4)

            elif [ "x$line" = x ]; then

                log "$ip - $method $path"
                
                case $path in
                    "/")
                        response 200 "$(jo message="Hello, World!")"
                        ;;
                    "/info/")
                        response 200 "$(jo ip=$ip, method=$method, path=$path)"
                        ;;
                    *)
                        error 404 "Invalid endpoint"
                        ;;
                esac

            fi
        done
        
    ) 2>&1
done