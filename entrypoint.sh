#!/bin/bash

source /etc/profile.d/rbenv.sh
source /etc/profile.d/ndenv.sh

export PATH=$PATH:`npm bin -g`
export PATH=$PATH:`yarn global bin`

# set timezone
if [ -e /usr/share/${TZ} ]; then
  sudo ln -sf /usr/share/${TZ} /etc/localtime
fi

if [ ! -e ${APP_ROOT}/Gemfile ]; then
  cp -R ${APP_ROOT}/../current/* ${APP_ROOT}/.
fi

cd ${APP_ROOT}

# Wait for MySQL
if [ -n "$MYSQL_USER" ]; then
  echo `date '+%Y/%m/%d %H:%M:%S'` $0 "[INFO] MySQL Connection confriming..."
  while :
  do
    if echo `/usr/bin/mysqladmin ping -h ${MYSQL_HOST} -u${MYSQL_USER} -p${MYSQL_PASSWORD} 2> /dev/null` | grep 'alive'; then
      break
    fi
    sleep 3;
  done
fi

rake db:migrate

set -e

if [ -z "$1" ]; then
  set -- rails server "$@"
fi

if [[ "$1" = "rails" && ("$2" = "s" || "$2" = "server") ]]; then
  rake assets:precompile

  if [ -f tmp/pids/server.pid ]; then
    rm tmp/pids/server.pid
  fi
fi

exec "$@"
