FROM debian:bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
    mariadb-server \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

COPY conf/60-custom.cnf /etc/mysql/mariadb.conf.d/60-custom.cnf
COPY tools/init.sh /usr/local/bin/init.sh

RUN chmod +x /usr/local/bin/init.sh \
 && mkdir -p /run/mysqld \
 && chown -R mysql:mysql /run/mysqld

EXPOSE 3306

ENTRYPOINT ["/usr/local/bin/init.sh"]
CMD ["mariadbd"]