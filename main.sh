#!/usr/bin/env bash

trap 'killall stunnel; rm -rf tmp' EXIT

DEFAULT_HTTP_PORT=8080
DEFAULT_HTTPS_PORT=8443
DEFAULT_RIOT_API_KEY="YOUR_RIOT_API_KEY"
DEFAULT_BODY_READ_TIMEOUT=1
DEFAULT_LOBBYN_RIOT_CONTINENT="EUROPE"
DEFAULT_USER_CREATION_TIMEOUT=180

if [ -f config.ini ]; then
    source config.ini
else
    echo "RIOT_API_KEY=\"$DEFAULT_RIOT_API_KEY\"" >> config.ini
    echo "HTTP_PORT=$DEFAULT_HTTP_PORT" >> config.ini
    echo "HTTPS_PORT=$DEFAULT_HTTPS_PORT" >> config.ini
    echo "BODY_READ_TIMEOUT=$DEFAULT_BODY_READ_TIMEOUT" >> config.ini
    echo "LOBBYN_RIOT_CONTINENT=$DEFAULT_LOBBYN_RIOT_CONTINENT" >> config.ini
    echo "USER_CREATION_TIMEOUT=$DEFAULT_USER_CREATION_TIMEOUT" >> config.ini
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
mkdir -p tmp/user

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