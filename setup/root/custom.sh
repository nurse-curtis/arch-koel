#!/bin/bash

# exit script if return code != 0
set -e

# find latest koel release tag from github
release_tag=$(curl -s https://github.com/phanan/koel/releases | grep -P -o -m 1 '(?<=/phanan/koel/releases/tag/)[^"]+')

# git clone koel and install pre-reqs
mkdir -p /opt/koel && cd /opt/koel
git clone --branch "${release_tag}" https://github.com/phanan/koel .
npm install --unsafe-perm
# below is a hack to get around install issue for v3.4.1
composer require pusher/pusher-php-server --no-scripts
composer install
