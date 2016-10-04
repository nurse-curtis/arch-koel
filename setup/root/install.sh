#!/bin/bash

# exit script if return code != 0
set -e

# define pacman packages
pacman_packages="php npm nodejs composer git mariadb libnotify php-fpm nginx"

# install pre-reqs
pacman -S --needed $pacman_packages --noconfirm

# find latest koel release tag from github
release_tag=$(curl -s https://github.com/phanan/koel/releases | grep -P -o -m 1 '(?<=/phanan/koel/releases/tag/)[^"]+')

# git clone koel and install pre-reqs
mkdir -p /opt/koel && cd /opt/koel
git clone --branch "${release_tag}" https://github.com/phanan/koel .
npm install --unsafe-perm
composer install

# copy example koel env file and define
cp ./.env.example ./.env
sed -i 's/ADMIN_EMAIL=/ADMIN_EMAIL=admin@example.com/g' ./.env
sed -i 's/ADMIN_NAME=/ADMIN_NAME=admin/g' ./.env
sed -i 's/ADMIN_PASSWORD=/ADMIN_PASSWORD=admin/g' ./.env
sed -i 's/DB_CONNECTION=/DB_CONNECTION=mysql/g' ./.env
sed -i 's/DB_HOST=/DB_HOST=127.0.0.1/g' ./.env
sed -i 's/DB_DATABASE=/DB_DATABASE=koel/g' ./.env
sed -i 's/DB_USERNAME=/DB_USERNAME=koel-user/g' ./.env
sed -i 's/DB_PASSWORD=/DB_PASSWORD=koel-pass/g' ./.env

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

# cleanup
yes|pacman -Scc
rm -rf /usr/share/locale/*
rm -rf /usr/share/man/*
rm -rf /tmp/*
