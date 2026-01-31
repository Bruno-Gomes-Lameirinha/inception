#!/bin/sh
set -eu

: "${MYSQL_DATABASE:?MYSQL_DATABASE missing}"
: "${MYSQL_USER:?MYSQL_USER missing}"

# evita o client usar TCP por causa do .env (MYSQL_HOST=mariadb)
unset MYSQL_HOST MYSQL_PWD MYSQL_TCP_PORT

SOCK="/run/mysqld/mysqld.sock"

DB_ROOT_PASS="$(cat /run/secrets/db_root_password)"
DB_PASS="$(cat /run/secrets/db_password)"

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d /var/lib/mysql/mysql ]; then
  mariadb-install-db --user=mysql --datadir=/var/lib/mysql >/dev/null
fi

# servidor temporário SEM rede
mariadbd --user=mysql --datadir=/var/lib/mysql \
  --skip-networking --socket="$SOCK" &
pid="$!"

i=0
until mariadb-admin --protocol=SOCKET --socket="$SOCK" ping >/dev/null 2>&1; do
  i=$((i+1))
  [ "$i" -ge 30 ] && echo "MariaDB init timeout" >&2 && exit 1
  sleep 1
done

# root com/sem senha (sempre via socket)
if mariadb --protocol=SOCKET --socket="$SOCK" -uroot -p"$DB_ROOT_PASS" -e "SELECT 1" >/dev/null 2>&1; then
  ROOT_ARGS="-uroot -p$DB_ROOT_PASS"
else
  mariadb --protocol=SOCKET --socket="$SOCK" -uroot -e \
    "ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASS}'; FLUSH PRIVILEGES;"
  ROOT_ARGS="-uroot -p$DB_ROOT_PASS"
fi

mariadb --protocol=SOCKET --socket="$SOCK" $ROOT_ARGS -e \
  "CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
   CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASS}';
   GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
   FLUSH PRIVILEGES;"

mariadb-admin --protocol=SOCKET --socket="$SOCK" $ROOT_ARGS shutdown
wait "$pid"

# servidor definitivo COM rede (porta 3306) e rodando como mysql
exec "$@" --user=mysql
