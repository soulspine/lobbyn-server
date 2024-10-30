#!/usr/bin/env bash

DEFAULT_PORT=8080
DEFAULT_RIOT_API_KEY="YOUR_RIOT_API_KEY"
DEFAULT_BODY_READ_TIMEOUT=1

if [ -f config.ini ]; then
    source config.ini
else
    echo "RIOT_API_KEY=\"$DEFAULT_RIOT_API_KEY\"" >> config.ini
    echo "PORT=$DEFAULT_PORT" >> config.ini
    echo "BODY_READ_TIMEOUT=$DEFAULT_BODY_READ_TIMEOUT" >> config.ini
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

tcpserver -v -R -H 0 $PORT ./request.sh