# DEV_DOC — Inception Stack (Developer Guide)

## 1) Set up the environment from scratch

### Prerequisites
Install:
- Docker Engine
- Docker Compose plugin
- Make

Verify:
```bash
docker --version
docker compose version
make --version
Repository structure (overview)
srcs/docker-compose.yml — orchestration

srcs/requirements/nginx/ — NGINX Dockerfile, config template, entrypoint

srcs/requirements/wordpress/ — WordPress/PHP-FPM Dockerfile + entrypoint

srcs/requirements/mariadb/ — MariaDB Dockerfile + init script

secrets/ — secret files mounted via Docker secrets

Makefile — convenience targets

Configuration files
Create or edit:

srcs/.env (recommended)

secrets/*.txt for passwords

Example .env values:

DOMAIN_NAME=bgomes-l.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=bgomes-l42sp
MYSQL_HOST=mariadb

WP_ADMIN_USER=bgomes-l
WP_ADMIN_EMAIL=bgomes-l@student.42.fr

WP_USER=visitor
WP_USER_EMAIL=visitor@student.42.fr
Secrets (examples):

secrets/db_root_password.txt

secrets/db_password.txt

secrets/wp_admin_password.txt

secrets/wp_user_password.txt

2) Build and launch (Makefile + Docker Compose)
Build and start
make
Stop
make down
Rebuild everything (manual compose)
docker compose -f srcs/docker-compose.yml -p inception up -d --build
3) Commands to manage containers and volumes
Containers status
docker ps
docker ps -a
Inspect logs
docker logs --tail 200 nginx
docker logs --tail 200 wordpress
docker logs --tail 200 mariadb
Enter a container
docker exec -it nginx sh
docker exec -it wordpress sh
docker exec -it mariadb sh
WordPress status (WP-CLI)
docker exec -it wordpress sh -lc \
'wp core is-installed --allow-root --path=/var/www/html && echo "WP OK"'
MariaDB checks
docker exec -it mariadb sh -lc \
'mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"$(cat /run/secrets/db_root_password)" \
-e "SELECT User,Host FROM mysql.user;"'
HTTPS check
curl -kI https://<DOMAIN_NAME>
Example:

curl -kI https://bgomes-l.42.fr
4) Where project data is stored (persistence)
Data is persisted on the host under:

/home/bgomes-l/data/wordpress — WordPress files (including wp-content)

/home/bgomes-l/data/mariadb — MariaDB datadir

This ensures data survives container recreation and rebuilds.

What resets what
make down: removes containers and network, but keeps persistent data.

make fclean: expected to remove containers/images and wipe host data directories (use with care).

5) Debugging tips
HTTPS error right after make
NGINX may be generating a self-signed certificate on the first start. Retry:

curl -kI --retry 30 --retry-delay 1 --retry-all-errors https://<DOMAIN_NAME>
Example:

curl -kI --retry 30 --retry-delay 1 --retry-all-errors https://bgomes-l.42.fr
Database connectivity issues
Checklist:

Confirm MariaDB is up:

docker ps --filter name=mariadb
Check logs:

docker logs --tail 200 mariadb
Confirm secrets exist inside container:

docker exec -it mariadb sh -lc 'ls -l /run/secrets'
Confirm MYSQL_HOST=mariadb matches the service name in Compose:

docker exec -it wordpress sh -lc 'printenv | grep MYSQL_HOST'
6) Configuration change practice (evaluation trap)
Example: change PHP-FPM port (9000 → 9001)

What must change
Update PHP-FPM listen port in WordPress container

Update NGINX fastcgi_pass wordpress:<port>

Rebuild and verify the site is still reachable

Rebuild steps
make down
make
Validate
curl -kI https://<DOMAIN_NAME>
Example:

curl -kI https://bgomes-l.42.fr