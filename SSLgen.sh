#!/usr/bin/env bash
mkdir -p SSL
openssl req -x509 -days 365 -nodes -out SSL/server.crt -keyout SSL/server.key