#!/bin/bash

# if mysql database doesnt exist then initalise
if [ ! -f "/config/mysql/database/mysql-bin.index" ]; then

	mkdir -p /config/mysql/database

	# initialise mysql
	/usr/bin/mysql_install_db --user=nobody --ldata=/config/mysql/database/ --basedir=/usr

	# create script to run
	echo "CREATE DATABASE IF NOT EXISTS koel;" > /home/nobody/create_db_koel.sql
	echo "CREATE USER 'koel-user'@'localhost' IDENTIFIED BY 'koel-pass';" >> /home/nobody/create_db_koel.sql
	echo "GRANT ALL PRIVILEGES ON koel.* TO 'koel-user'@'localhost' WITH GRANT OPTION;" >> /home/nobody/create_db_koel.sql

	# run mysql as user nobody with data on /config
	nohup /usr/bin/mysqld_safe --user=nobody --datadir='/config/mysql/database/' &

	# wait for mysql to come up
	while ! mysqladmin ping -h"127.0.0.1" --silent; do
		sleep 0.1
	done

	# run script to create db, koel user and grant perms
	/usr/bin/mysql --user=root < /home/nobody/create_db_koel.sql > output.tab

else

	# run mysql as user nobody with data on /config
	nohup /usr/bin/mysqld_safe --user=nobody --datadir='/config/mysql/database/' &

fi
