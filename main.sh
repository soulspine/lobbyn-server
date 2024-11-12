#!/usr/bin/env bash

trap 'killall stunnel; rm -rf tmp' EXIT

cleanup_tmp_files() {
    while true; do
        for file in tmp/*; do
            if [ -f "$file" ]; then
                expiration=$(jq -r '.expiration' "$file")
                if [ $(jq -r '.expiration' "$file") -lt "$(date +%s)" ]; then
                    rm -f "$file"
                fi
            fi
        done
        sleep $CLEANUP_INTERVAL
    done
}

#CONFIG DEFAULTS
defaults=(
    "HTTP_PORT=8080"
    "HTTPS_PORT=8443"
    "RIOT_API_KEY=YOUR_RIOT_API_KEY"
    "RIOT_CONTINENT=EUROPE"
    "TOKEN_LENGTH=32"
    "ARGON2_ITERATIONS=20"
    "ARGON2_MEMORY=4096"
    "ARGON2_PARALLELISM=4"
    "ARGON2_LENGTH=32"
    "BODY_READ_TIMEOUT=1"
    "USER_CREATION_TIMEOUT=180"
    "LOGIN_REQUEST_TIMEOUT=10"
    "ACCESS_SESSION_TIMEOUT=900"
    "CLEANUP_INTERVAL=60"
    "DISPLAY_NAME_MIN_LENGTH=5"
    "DISPLAY_NAME_LENGTH=16"
)

if [ -f config.ini ]; then
    source config.ini
else
    for entry in "${defaults[@]}"; do
        echo "$entry" >> config.ini
    done
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

if [ ! -d SSL ]; then
    echo "SSL directory not found. Run SSLgen.sh to generate SSL certificates and run the script again."
    exit 3
fi

rm -rf tmp
mkdir -p tmp

rm -f SSL/stunnel.conf
touch SSL/stunnel.conf
echo "[https]" >> SSL/stunnel.conf
echo "accept = $HTTPS_PORT" >> SSL/stunnel.conf
echo "connect = 127.0.0.1:$HTTP_PORT" >> SSL/stunnel.conf
echo "cert = SSL/server.crt" >> SSL/stunnel.conf
echo "key = SSL/server.key" >> SSL/stunnel.conf
echo "protocol = proxy" >> SSL/stunnel.conf

stunnel SSL/stunnel.conf

cleanup_tmp_files &
tcpserver -v -R -H 0 $HTTP_PORT ./request.sh