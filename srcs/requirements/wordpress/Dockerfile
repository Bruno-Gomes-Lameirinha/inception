FROM debian:oldstable

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl tar \
    php-fpm php-mysql php-cli \
    mariadb-client \
    msmtp-mta \
 && rm -rf /var/lib/apt/lists/*

RUN sed -i 's|^listen = .*|listen = 9000|' /etc/php/*/fpm/pool.d/www.conf \
 && sed -i 's|^;clear_env = no|clear_env = no|' /etc/php/*/fpm/pool.d/www.conf || true

RUN mkdir -p /usr/src/wordpress \
 && curl -fsSL https://wordpress.org/latest.tar.gz \
 | tar -xz --strip-components=1 -C /usr/src/wordpress

RUN curl -fsSL -o /usr/local/bin/wp \
    https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
 && chmod +x /usr/local/bin/wp

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm8.2", "-F"]