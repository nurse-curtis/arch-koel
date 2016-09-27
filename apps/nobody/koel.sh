#!/bin/bash

# if php timezone specified then set in php.ini (prevents issues with dst)
if [[ ! -z "${PHP_TZ}" ]]; then

	echo "[info] Setting PHP timezone to ${PHP_TZ}..."
	sed -i -e "s~.*date\.timezone \=.*~date\.timezone \= ${PHP_TZ}~g" "/etc/php/php.ini"

else

	echo "[warn] PHP timezone not set, this may cause issues with the ruTorrent Scheduler plugin, see here for a list of available PHP timezones, http://php.net/manual/en/timezones.php"

fi

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

	# if nginx defaiult config file exists then delete
	if [[ -f "/etc/nginx/nginx.conf" && ! -L "/etc/nginx/nginx.conf" ]]; then
		rm -rf /etc/nginx/nginx.conf
	fi
	
	cp /home/nobody/nginx/config/* /config/nginx/config/

else

	echo "[info] nginx config file already exists, skipping copy"

fi

# create soft link to nginx config file
ln -fs /config/nginx/config/nginx.conf /etc/nginx/nginx.conf

# if php config file doesnt exist then copy default to host config volume (soft linked)
if [ ! -f "/config/php/config/php.ini" ]; then

	echo "[info] php config file doesnt exist, copying default to /config/php/config/..."

	mkdir -p /config/php/config

	# if php defaiult config file exists then delete
	if [[ -f "/etc/php/php.ini" && ! -L "/etc/php/php.ini" ]]; then
		mv /etc/php/php.ini /etc/php/php.ini-default
	fi

	cp /etc/php/php.ini-default /config/php/config/php.ini

else

	echo "[info] php config file already exists, skipping copy"

fi

# create soft link to php config file
ln -fs /config/php/config/php.ini /etc/php/php.ini

# if koel config file doesnt exist then copy default to host config volume (soft linked)
if [ ! -f "/config/koel/config/.env" ]; then

	echo "[info] koel config file doesnt exist, copying default to /config/koel/config/..."

	mkdir -p /config/koel/config

	# if koel defaiult config file exists then delete
	if [[ -f "/opt/koel/.env" && ! -L "/opt/koel/.env" ]]; then
		mv /opt/koel/.env /opt/koel/.env-default
	fi
	
	cp /opt/koel/.env-default /config/koel/config/.env

else

	echo "[info] koel config file already exists, skipping copy"

fi

# create soft link to koel config file
ln -fs /config/koel/config/.env /opt/koel/.env

echo "[info] starting php-fpm..."

# run php-fpm and specify path to pid file
/usr/bin/php-fpm --pid /home/nobody/php-fpm.pid

echo "[info] waiting for mysql..."

# wait for mysql to come up
while ! mysqladmin ping -h"127.0.0.1" --silent; do
	sleep 0.1
done

echo "[info] initialise koel..."

# initialise koel
cd /opt/koel && /usr/bin/php artisan koel:init

echo "[info] starting nginx..."

# run nginx in foreground and specify path to pid file
/usr/bin/nginx -g "daemon off; pid /home/nobody/nginx.pid;"