#!/usr/bin/env bash

set -e

ROOT_USERNAME=root
ROOT_PASSWORD=admin
REDIS_CACHE=redis-cache:6379
REDIS_QUEUE=redis-queue:6379

CURRENT_DIR=/home/frappe/frappe-bench

echo "Current directory: $CURRENT_DIR"
echo "Whoami: $(whoami)"

cd $CURRENT_DIR || exit 1

configure_bench() {
  echo "Configure bench settings..."
  cd "$CURRENT_DIR" || exit 1
  ls -1 apps >sites/apps.txt 2>/dev/null || true
  echo "DB_HOST: $DB_HOST"
  echo "REDIS_CACHE: $REDIS_CACHE"
  echo "REDIS_CACHE: $REDIS_QUEUE"
  echo "SOCKETIO_PORT: $SOCKETIO_PORT"
  bench set-config -g db_host $DB_HOST
  bench set-config -gp db_port $DB_PORT
  bench set-config -g redis_cache "redis://$REDIS_CACHE"
  bench set-config -g redis_queue "redis://$REDIS_QUEUE"
  bench set-config -g redis_socketio "redis://$REDIS_QUEUE"
  bench set-config -gp socketio_port $SOCKETIO_PORT
  if [ -f "/tmp/first_run" ]; then
    echo "Building site (frontend) for the first time..."
    bench setup requirements
    ls -1 apps
    echo bench new-site frontend --force --mariadb-user-host-login-scope='%' --admin-password=$ROOT_PASSWORD --db-root-username=$ROOT_USERNAME --db-root-password=$ROOT_PASSWORD $(echo $(ls -1 ./apps | xargs -n1 echo --install-app))
    bench new-site frontend --force --mariadb-user-host-login-scope='%' --admin-password=$ROOT_PASSWORD --db-root-username=$ROOT_USERNAME --db-root-password=$ROOT_PASSWORD $(echo $(ls -1 ./apps | xargs -n1 echo --install-app))
    bench build
    rm /tmp/first_run
  fi
}

configure_bench

/home/frappe/frappe-bench/env/bin/gunicorn \
  --chdir=/home/frappe/frappe-bench/sites \
  --bind=0.0.0.0:8000 \
  --threads=4 \
  --workers=2 \
  --worker-class=gthread \
  --worker-tmp-dir=/dev/shm \
  --timeout=120 \
  --preload \
  frappe.app:application
