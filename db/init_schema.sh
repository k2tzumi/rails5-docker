#!/bin/bash
set -e

echo "Initializing database schema"

source /docker-entrypoint-initdb.d/credentials.env

mysql -uroot -p"$MYSQL_ROOT_PASSWORD" <<-EOSQL
CREATE DATABASE IF NOT EXISTS db_development;
CREATE DATABASE IF NOT EXISTS db_test;
CREATE DATABASE IF NOT EXISTS db_production;
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};

GRANT ALL PRIVILEGES ON db_development.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON db_test.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON db_production.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON db_development.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON db_test.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON db_production.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO 'root'@'%';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
EOSQL
