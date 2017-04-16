#!/bin/bash

# exit script if return code != 0
set -e

# find latest koel release tag from github
release_tag=$(curl --connect-timeout 5 --max-time 10 --retry 5 --retry-delay 0 --retry-max-time 60 -s https://github.com/phanan/koel/releases | grep -P -o -m 1 '(?<=/phanan/koel/releases/tag/)[^"]+')

# git clone koel and install pre-reqs
mkdir -p /opt/koel && cd /opt/koel
git clone --branch "${release_tag}" https://github.com/phanan/koel .
yarn install --unsafe-perm

# below is a hack to get around install issue for v3.4.1
composer require pusher/pusher-php-server --no-scripts
composer install

# another hack, laravel 5.4 uses the utf8mb4 character set by default, which includes support for storing "emojis" in the database.
# mysql 5.7.7+ / mariadb 10.2.2+) both have this new character set by default, so this is only a tempory hack until they are updated.
sed -i -e 's~mb4~~g' /opt/koel/config/database.php
