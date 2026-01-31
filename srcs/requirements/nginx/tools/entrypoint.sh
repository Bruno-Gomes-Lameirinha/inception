#!/bin/sh
set -eu

mkdir -p /etc/nginx/ssl

if [ ! -f "/etc/nginx/ssl/${DOMAIN_NAME}.crt" ] || [ ! -f "/etc/nginx/ssl/${DOMAIN_NAME}.key" ]; then
  openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
    -subj "/C=BR/ST=SP/L=SaoPaulo/O=42/OU=Inception/CN=${DOMAIN_NAME}" \
    -keyout "/etc/nginx/ssl/${DOMAIN_NAME}.key" \
    -out "/etc/nginx/ssl/${DOMAIN_NAME}.crt"
fi

envsubst '$DOMAIN_NAME' \
  < /etc/nginx/templates/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec "$@"
