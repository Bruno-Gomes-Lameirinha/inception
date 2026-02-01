# USER_DOC — Inception Stack (User/Admin Guide)

## What services are provided

This stack provides:
- **NGINX**: HTTPS entrypoint (**port 443**) serving the WordPress site.
- **WordPress (PHP-FPM)**: application backend (**internal port 9000**).
- **MariaDB**: database backend (**internal port 3306**).

Only **NGINX** is exposed to the host. **WordPress** and **MariaDB** are internal to the Docker network.

---

## Start and stop the project

### Start
```bash
make
Stop
make down
Check status
docker ps
Access the website and administration panel
Website: https://<DOMAIN_NAME>
Example: https://bgomes-l.42.fr

Admin panel: https://<DOMAIN_NAME>/wp-admin
Example: https://bgomes-l.42.fr/wp-admin

Notes:

The TLS certificate is self-signed. Your browser may warn you; you can proceed.

With curl, use -k to ignore self-signed certificate warnings.

Credentials: where to find and how to manage them
Environment variables (non-secret configuration)
The .env file (recommended: srcs/.env) contains non-sensitive configuration:

domain name (example: bgomes-l.42.fr)

database name and usernames

WordPress admin username (must NOT contain "admin")

emails, etc.

Secrets (passwords)
Passwords are stored as files in secrets/ and mounted into containers via Docker secrets:

secrets/db_root_password.txt

secrets/db_password.txt

secrets/wp_admin_password.txt

secrets/wp_user_password.txt

Inside containers, they are available under:

/run/secrets/db_root_password

/run/secrets/db_password

/run/secrets/wp_admin_password

/run/secrets/wp_user_password

Rotate a password
Edit the corresponding secrets/*.txt file

Rebuild/recreate the affected services:

docker compose -f srcs/docker-compose.yml -p inception up -d --build --force-recreate
Check that the services are running correctly
1) NGINX (HTTPS)
curl -kI https://<DOMAIN_NAME>
Example:

curl -kI https://bgomes-l.42.fr
Expected: HTTP/1.1 200 OK (or a redirect), but it must respond over HTTPS.

2) WordPress installed (WP-CLI)
docker exec -it wordpress sh -lc 'wp core is-installed --allow-root --path=/var/www/html && echo "WP OK"'
3) MariaDB reachable
docker exec -it mariadb sh -lc 'mariadb --socket=/run/mysqld/mysqld.sock -uroot -p"$(cat /run/secrets/db_root_password)" -e "SHOW DATABASES;"'
4) Logs (when something fails)
docker logs --tail 100 nginx
docker logs --tail 100 wordpress
docker logs --tail 100 mariadb
Persistence (data survives container recreation)
Project data is stored on the host under:

/home/bgomes-l/data/wordpress

/home/bgomes-l/data/mariadb

Verify persistence
Edit a WordPress page or create a post

Restart the stack:

make down
make
Verify your changes are still present at:
Example: https://bgomes-l.42.fr