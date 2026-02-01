FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx openssl gettext-base ca-certificates \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/ssl /etc/nginx/templates

COPY conf/default.conf.template /etc/nginx/templates/default.conf.template
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
