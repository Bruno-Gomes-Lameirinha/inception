*This project has been created as part of the 42 curriculum by bgomes-l.*

# Inception (NGINX + WordPress/PHP-FPM + MariaDB)

## Description
This project builds a small, production-like web stack using **Docker** and **Docker Compose**:
- **NGINX** as the only public entrypoint (HTTPS only)
- **WordPress** running on **PHP-FPM** (no web server inside this container)
- **MariaDB** as the database backend

Goal: orchestrate the services with Docker Compose, ensure proper networking between containers, use persistent storage for database and website files, and manage secrets securely.

### What is included in this repository
- `srcs/docker-compose.yml`: orchestrates the stack and the network
- `srcs/requirements/nginx`: NGINX image (TLS 1.2/1.3, reverse proxy + FastCGI to PHP-FPM)
- `srcs/requirements/wordpress`: WordPress + PHP-FPM image, installs/configures WP on first run
- `srcs/requirements/mariadb`: MariaDB image, initializes DB/users on first run
- `secrets/`: secret files used by Docker secrets (DB and WP passwords)
- `Makefile`: one-command build/up/down and clean targets

### Design choices (high level)
- **One process per container**, running in the foreground (no `tail -f`, no infinite loops).
- Entrypoints end with `exec "$@"` so the real service becomes PID 1 and receives signals correctly.
- **HTTPS only** exposed by NGINX (`443/tcp`). Other services are internal-only.
- **Service discovery** uses the Docker Compose network and DNS (services communicate by service name).

### Comparison notes required by the subject

#### Virtual Machines vs Docker
- **VMs** virtualize full hardware + OS per VM (heavier, slower to boot, larger footprint).
- **Docker containers** share the host kernel and isolate processes (lighter, faster, reproducible builds).
- In this project, we use a **VM** as the host environment and **Docker** to run the services.

#### Secrets vs Environment Variables
- **Environment variables** are convenient for non-sensitive config (domain, db name, usernames),
  but can leak via logs, `docker inspect`, or shell history if misused.
- **Docker secrets** mount sensitive values as files inside the container (e.g. `/run/secrets/...`),
  keeping passwords out of images, compose files, and command history.

#### Docker Network vs Host Network
- **Docker (bridge) network** provides isolation and service discovery by name (recommended).
- **Host network** removes isolation and binds directly to host networking (not used/allowed here).
- This project uses a dedicated Compose network so containers reach each other by service name.

#### Docker Volumes vs Bind Mounts
- **Docker volumes** are managed by Docker (stored under Docker’s data directory by default).
- **Bind mounts** map a specific host path into the container.
- This project persists data under `/home/<login>/data/...` on the host so it survives container recreation.

---

## Instructions

### Prerequisites
- Docker Engine
- Docker Compose plugin
- GNU Make

### Configure
1) Create an environment file (recommended: `srcs/.env`) with non-secret configuration.
Example:
- `DOMAIN_NAME=bgomes-l.42.fr`
- `MYSQL_DATABASE=wordpress`
- `MYSQL_USER=<your_db_user>`
- `MYSQL_HOST=mariadb`
- `WP_ADMIN_USER=<must NOT contain "admin">`
- `WP_ADMIN_EMAIL=<email>`
- `WP_USER=<regular_user>`
- `WP_USER_EMAIL=<email>`

2) Create secrets files in `secrets/`:
- `secrets/db_root_password.txt`
- `secrets/db_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

### Build & run
```bash
make
Stop
make down
Clean everything (removes containers/images + persistent data)
make fclean
Access
Website: https://<DOMAIN_NAME>
Example: https://bgomes-l.42.fr

Admin panel: https://<DOMAIN_NAME>/wp-admin
Example: https://bgomes-l.42.fr/wp-admin

Resources
Documentation / References
Docker Docs: images, containers, volumes, networks

Docker Compose Docs: service orchestration

NGINX documentation: TLS and FastCGI (fastcgi_pass)

WordPress documentation: installation and configuration

MariaDB documentation: users, privileges, initialization

How AI was used
AI assistance (ChatGPT) was used for:

explaining Docker concepts (PID 1, entrypoint/CMD, volumes, networks, secrets)

debugging container startup issues (MariaDB initialization, WordPress/PHP-FPM runtime)

improving scripts to follow best practices (foreground processes, exec "$@", safe waits with timeouts)

All final changes were tested locally with docker compose up -d --build and runtime checks (curl, logs, container exec).