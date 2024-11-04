#!/usr/bin/env bash

trap 'killall stunnel; rm -rf tmp' EXIT

#CONFIG DEFAULTS
defaults=(
    "HTTP_PORT=8080"
    "HTTPS_PORT=8443"
    "RIOT_API_KEY=YOUR_RIOT_API_KEY"
    "RIOT_CONTINENT=EUROPE"
    "TOKEN_LENGTH=32"
    "BODY_READ_TIMEOUT=1"
    "USER_CREATION_TIMEOUT=180"
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

tcpserver -v -R -H 0 $HTTP_PORT ./source/request.sh