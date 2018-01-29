#!/bin/bash

# exit script if return code != 0
set -e

# build scripts
####

# download build scripts from github
curl --connect-timeout 5 --max-time 600 --retry 5 --retry-delay 0 --retry-max-time 60 -o /tmp/scripts-master.zip -L https://github.com/binhex/scripts/archive/master.zip

# unzip build scripts
unzip /tmp/scripts-master.zip -d /tmp

# move shell scripts to /root
mv /tmp/scripts-master/shell/arch/docker/*.sh /root/

# pacman packages
####

# define pacman packages
pacman_packages="php npm nodejs composer git mariadb libnotify php-fpm nginx expect"

# install compiled packages using pacman
if [[ ! -z "${pacman_packages}" ]]; then
	pacman -S --needed $pacman_packages --noconfirm
fi

# aor packages
####

# define arch official repo (aor) packages
aor_packages="yarn"

# call aor script (arch official repo)
source /root/aor.sh

# aur packages
####

# define aur packages
aur_packages=""

# call aur install script (arch user repo)
source /root/aur.sh

# github releases
####

# download koel
/root/github.sh -df "github-download.zip" -dp "/tmp" -ep "/tmp/extracted" -ip "/opt/koel" -go "phanan" -gr "koel" -rt "source"

# install koel
cd /opt/koel && yarn install --unsafe-perm
composer install

# another hack, laravel 5.4 uses the utf8mb4 character set by default, which includes support for storing "emojis" in the database.
# mysql 5.7.7+ / mariadb 10.2.2+) both have this new character set by default, so this is only a tempory hack until they are updated.
sed -i -e 's~mb4~~g' /opt/koel/config/database.php

# config
####

# copy example koel env file and define
cp /home/nobody/koel/.env.example /opt/koel/.env.backup || ls -al
sed -i 's/ADMIN_EMAIL=/ADMIN_EMAIL=admin@example.com/g' /opt/koel/.env.backup
sed -i 's/ADMIN_NAME=/ADMIN_NAME=admin/g' /opt/koel/.env.backup
sed -i 's/ADMIN_PASSWORD=/ADMIN_PASSWORD=admin/g' /opt/koel/.env.backup
sed -i 's/DB_CONNECTION=/DB_CONNECTION=mysql/g' /opt/koel/.env.backup
sed -i 's/DB_HOST=/DB_HOST=127.0.0.1/g' /opt/koel/.env.backup
sed -i 's/DB_DATABASE=/DB_DATABASE=koel/g' /opt/koel/.env.backup
sed -i 's/DB_USERNAME=/DB_USERNAME=koel-user/g' /opt/koel/.env.backup
sed -i 's/DB_PASSWORD=/DB_PASSWORD=koel-pass/g' /opt/koel/.env.backup
sed -i 's/STREAMING_METHOD=.*/STREAMING_METHOD=x-accel-redirect/g' /opt/koel/.env.backup
sed -i 's/APP_MAX_SCAN_TIME=.*/APP_MAX_SCAN_TIME=6000/g' /opt/koel/.env.backup

# modify php.ini to add in required extension
sed -i 's/;extension=pdo_mysql.so/extension=pdo_mysql.so/g' /etc/php/php.ini
sed -i 's/;extension=exif.so/extension=exif.so/g' /etc/php/php.ini

# configure php-fpm to use tcp/ip connection for listener
echo "" >> /etc/php/php-fpm.conf
echo "; Set php-fpm to use tcp/ip connection" >> /etc/php/php-fpm.conf
echo "listen = 127.0.0.1:7777" >> /etc/php/php-fpm.conf

# configure php-fpm listener for user nobody, group users
echo "" >> /etc/php/php-fpm.conf
echo "; Specify user listener owner" >> /etc/php/php-fpm.conf
echo "listen.owner = nobody" >> /etc/php/php-fpm.conf
echo "" >> /etc/php/php-fpm.conf
echo "; Specify user listener group" >> /etc/php/php-fpm.conf
echo "listen.group = users" >> /etc/php/php-fpm.conf

# create socket for mysqld
mkdir -p /run/mysqld

# container perms
####

# create file with contets of here doc
cat <<'EOF' > /tmp/permissions_heredoc
# set permissions inside container
chown -R "${PUID}":"${PGID}" /opt/koel/ /usr/share/nginx/html/ /etc/nginx/ /etc/php/ /run/php-fpm/ /var/lib/nginx/ /var/log/nginx/ /var/lib/mysql/ /home/nobody /run/mysqld
chmod -R 775 /opt/koel/ /usr/share/nginx/html/ /etc/nginx/ /etc/php/ /run/php-fpm/ /var/lib/nginx/ /var/log/nginx/ /var/lib/mysql/ /home/nobody /run/mysqld

EOF

# replace permissions placeholder string with contents of file (here doc)
sed -i '/# PERMISSIONS_PLACEHOLDER/{
    s/# PERMISSIONS_PLACEHOLDER//g
    r /tmp/permissions_heredoc
}' /root/init.sh
rm /tmp/permissions_heredoc

# env vars
####

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /usr/share/gtk-doc/*
rm -rf /tmp/*
