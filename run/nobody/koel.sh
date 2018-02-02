#!/bin/bash

# if nginx cert files dont exist then copy defaults to host config volume (location specified in nginx.conf, no need to soft link)
if [[ ! -f "/config/nginx/certs/host.cert" || ! -f "/config/nginx/certs/host.key" ]]; then

	echo "[info] nginx cert files doesnt exist, copying default to /config/nginx/certs/..."

	mkdir -p /config/nginx/certs
	cp /home/nobody/nginx/certs/* /config/nginx/certs/

else

	echo "[info] nginx cert files already exists, skipping copy"

fi

# if nginx security file doesnt exist then copy default to host config volume (location specified in nginx.conf, no need to soft link)
if [ ! -f "/config/nginx/security/auth" ]; then

	echo "[info] nginx security file doesnt exist, copying default to /config/nginx/security/..."

	mkdir -p /config/nginx/security
	cp /home/nobody/nginx/security/* /config/nginx/security/

else

	echo "[info] nginx security file already exists, skipping copy"

fi

# if nginx config file doesnt exist then copy default to host config volume (soft linked)
if [ ! -f "/config/nginx/config/nginx.conf" ]; then

	echo "[info] nginx config file doesnt exist, copying default to /config/nginx/config/..."

	mkdir -p /config/nginx/config

	# if nginx default config file exists then delete
	if [[ -f "/etc/nginx/nginx.conf" && ! -L "/etc/nginx/nginx.conf" ]]; then
		rm -rf /etc/nginx/nginx.conf
	fi

	cp /home/nobody/nginx/config/* /config/nginx/config/

else

	echo "[info] nginx config file already exists, skipping copy"

fi

# create soft link to nginx config file
ln -fs /config/nginx/config/nginx.conf /etc/nginx/nginx.conf

# if php config file backup doesnt exist then rename
if [ ! -f "/etc/php/php.ini-backup" ]; then
	mv /etc/php/php.ini /etc/php/php.ini-backup
fi

# if php config file doesnt exist then copy default to host config volume (soft linked)
if [ ! -f "/config/php/config/php.ini" ]; then

	echo "[info] php config file doesnt exist, copying default to /config/php/config/..."

	mkdir -p /config/php/config
	cp /etc/php/php.ini-backup /config/php/config/php.ini

else

	echo "[info] php config file already exists, skipping copy"

fi

# create soft link to php config file
ln -fs /config/php/config/php.ini /etc/php/php.ini

# if koel config file doesnt exist then copy default to host config volume (soft linked)
if [ ! -f "/config/koel/config/.env" ]; then

	echo "[info] koel config file doesnt exist, copying default to /config/koel/config/..."

	mkdir -p /config/koel/config
	cp /opt/koel/.env.backup /config/koel/config/.env

else

	echo "[info] koel config file already exists, skipping copy"

fi

# create soft link to koel config file
ln -fs /config/koel/config/.env /opt/koel/.env

# if php memory limit specified then set in php.ini (prevents oom during intial scan)
if [[ ! -z "${PHP_MEMORY_LIMIT}" ]]; then

	echo "[info] Setting PHP memory limit to ${PHP_MEMORY_LIMIT}..."
	sed -i 's/memory_limit =.* /memory_limit = '"${PHP_MEMORY_LIMIT}"'M/g' /config/php/config/php.ini

else

	echo "[warn] PHP memory limit not set, using the default value of 2048 MB"
	sed -i 's/memory_limit =.* /memory_limit = 2048M/g' /config/php/config/php.ini

fi

# if nginx fastcgi read timeout specified then set in nginx.conf (prevents timeout during intial scan)
if [[ ! -z "${FASTCGI_READ_TIMEOUT}" ]]; then

	echo "[info] Setting nginx fastcgi timeout to ${FASTCGI_READ_TIMEOUT}..."
	sed -i 's/fastcgi_read_timeout.*/fastcgi_read_timeout         '"${FASTCGI_READ_TIMEOUT}"'s;/g' /config/nginx/config/nginx.conf

else

	echo "[warn] NGINX fastcgi resd timeout not set, using the default value of 6000 secs"
	sed -i 's/fastcgi_read_timeout.*/fastcgi_read_timeout         6000s;/g' /config/nginx/config/nginx.conf

fi

echo "[info] starting php-fpm..."

# run php-fpm and specify path to pid file
/usr/bin/php-fpm --pid "/home/nobody/php-fpm.pid"

echo "[info] php-fpm started"

echo "[info] waiting for mysql to start..."

# wait for mysql to come up
while ! mysqladmin ping -h"127.0.0.1" --silent; do
	sleep 0.1
done

echo "[info] mysql started"

# check if koel database is populated, if not then init
if [ ! -f "/config/mysql/database/koel/albums.ibd" ]; then

	echo "[info] initialise koel database..."

	cd /opt/koel && expect /home/nobody/koel/init.exp

elif [ ! -f "/opt/koel/dbinit" ]; then

	echo "[info] re-initialise koel database..."

	cd /opt/koel && /usr/bin/php artisan koel:init && touch "/opt/koel/dbinit"

fi

echo "[info] starting nginx..."

# run nginx in foreground and specify path to pid file
/usr/bin/nginx -g "daemon off; pid /home/nobody/nginx.pid;"
