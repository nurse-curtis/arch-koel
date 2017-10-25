#!/bin/bash

# exit script if return code != 0
set -e

repo_name="phanan"
app_name="koel"
install_name="koel"

# find latest release tag from github
/root/curly.sh -rc 6 -rw 10 -of /tmp/release_tag -url "https://github.com/${repo_name}/${app_name}/releases"
release_tag=$(cat /tmp/release_tag | grep -P -o -m 1 "(?<=/${repo_name}/${app_name}/releases/tag/)[^\"]+")

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
