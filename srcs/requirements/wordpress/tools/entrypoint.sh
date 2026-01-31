#!/bin/sh
set -eu

: "${MYSQL_HOST:?MYSQL_HOST missing}"
: "${MYSQL_DATABASE:?MYSQL_DATABASE missing}"
: "${MYSQL_USER:?MYSQL_USER missing}"
: "${DOMAIN_NAME:?DOMAIN_NAME missing}"
: "${WP_TITLE:?WP_TITLE missing}"
: "${WP_ADMIN_USER:?WP_ADMIN_USER missing}"
: "${WP_ADMIN_EMAIL:?WP_ADMIN_EMAIL missing}"
: "${WP_USER:?WP_USER missing}"
: "${WP_USER_EMAIL:?WP_USER_EMAIL missing}"

DB_PASS="$(cat /run/secrets/db_password)"
WP_ADMIN_PASS="$(cat /run/secrets/wp_admin_password)"
WP_USER_PASS="$(cat /run/secrets/wp_user_password)"

# Proteção: admin não pode conter admin/Admin/administrator...
lc_admin="$(printf "%s" "$WP_ADMIN_USER" | tr '[:upper:]' '[:lower:]')"
case "$lc_admin" in
  *admin*|*administrator*)
    echo "ERROR: WP_ADMIN_USER cannot contain admin/Admin/administrator." >&2
    exit 1
    ;;
esac

# Se o volume estiver vazio, copia o WP pra /var/www/html
if [ ! -f /var/www/html/wp-settings.php ]; then
  cp -R /usr/src/wordpress/* /var/www/html/
  chown -R www-data:www-data /var/www/html
fi

# Só configura/instala se ainda não existir wp-config.php
if [ ! -f /var/www/html/wp-config.php ]; then
  # Espera o MariaDB (timeout, sem loop infinito)
  i=0
  until mariadb -h"$MYSQL_HOST" -u"$MYSQL_USER" -p"$DB_PASS" \
        -e "SELECT 1;" "$MYSQL_DATABASE" >/dev/null 2>&1; do
    i=$((i+1))
    [ "$i" -ge 60 ] && echo "ERROR: DB not ready (timeout)" >&2 && exit 1
    sleep 1
  done

  # wp-config.php
  wp config create --allow-root --path=/var/www/html \
    --dbname="$MYSQL_DATABASE" \
    --dbuser="$MYSQL_USER" \
    --dbpass="$DB_PASS" \
    --dbhost="$MYSQL_HOST"

  # Instala WP
  wp core install --allow-root --path=/var/www/html \
    --url="https://${DOMAIN_NAME}" \
    --title="$WP_TITLE" \
    --admin_user="$WP_ADMIN_USER" \
    --admin_password="$WP_ADMIN_PASS" \
    --admin_email="$WP_ADMIN_EMAIL"

  # Cria usuário normal
  wp user create --allow-root --path=/var/www/html \
    "$WP_USER" "$WP_USER_EMAIL" \
    --user_pass="$WP_USER_PASS"
fi

# Processo final vira o principal (PID 1 do container)
exec "$@"
