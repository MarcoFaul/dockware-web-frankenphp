#!/bin/bash

echo ""
echo " _____   ____   _____ _  ____          __     _____  ______ "
echo "|  __ \ / __ \ / ____| |/ /\ \        / /\   |  __ \|  ____|"
echo "| |  | | |  | | |    | ' /  \ \  /\  / /  \  | |__) | |__   "
echo "| |  | | |  | | |    |  <    \ \/  \/ / /\ \ |  _  /|  __|  "
echo "| |__| | |__| | |____| . \    \  /\  / ____ \| | \ \| |____ "
echo "|_____/ \____/ \_____|_|\_\    \/  \/_/    \_\_|  \_\______|"
echo ""
echo "68 69 20 64 65 76 65 6C 6F 70 65 72 2C 20 6E 69 63 65 20 74 6F 20 6D 65 65 74 20 79 6F 75"
echo "6c 6f 6f 6b 69 6e 67 20 66 6f 72 20 61 20 6a 6f 62 3f 20 77 72 69 74 65 20 75 73 20 61 74 20 6a 6f 62 73 40 64 61 73 69 73 74 77 65 62 2e 64 65"
echo ""
echo "*******************************************************"
echo "** DOCKWARE IMAGE: web-frankenphp"
echo "** Version: $(cat /dockware/version.txt)"
echo "** Built: $(cat /dockware/build-date.txt)"
echo "** Copyright $(cat /dockware/copyright.txt)"
echo "*******************************************************"
echo ""
echo "launching dockware with FrankenPHP...please wait..."
echo ""

set -e

source /var/www/.bashrc

# this is important to automatically use the bashrc file
# in the "exec" command below when using a simple docker runner command
export BASH_ENV=/var/www/.bashrc

CONTAINER_STARTUP_DIR=$(pwd)

# only do all our stuff
# if we are not in recovery mode
if [ $RECOVERY_MODE = 0 ]; then

    # it's possible to add a custom boot script on startup.
    # so we test if it exists and just execute it
    file="/var/www/boot_start.sh"
    if [ -f "$file" ] ; then
        sh $file
    fi

    echo "DOCKWARE: setting timezone to ${TZ}..."
    sudo ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
    sudo dpkg-reconfigure -f noninteractive tzdata
    echo "-----------------------------------------------------------"

    # checks if a different username is set in ENV and create if its not existing yet
    if [ $SSH_USER != "not-set" ] && (! id -u "${SSH_USER}" >/dev/null 2>&1 ); then
        echo "DOCKWARE: creating additional SSH user...."
        sh /var/www/scripts/bin/add_user.sh $SSH_USER $SSH_PWD
        echo "-----------------------------------------------------------"
    fi

    # start the SSH service with the latest setup
    echo "DOCKWARE: restarting SSH service...."
    sudo service ssh restart
    echo "-----------------------------------------------------------"

    echo "DOCKWARE: starting cron service...."
    sudo service cron start
    echo "-----------------------------------------------------------"

    if [ "$NODE_VERSION" != "not-set" ]; then
       echo "DOCKWARE: switching to Node ${NODE_VERSION}..."
       nvm alias default ${NODE_VERSION}
       # now make sure to at least have node and npm as sudo
       # nvm itself is not possible by design
       sudo rm -f /usr/local/bin/node
       sudo rm -f /usr/local/bin/npm
       sudo ln -s "$(which node)" "/usr/local/bin/node"
       sudo ln -s "$(which npm)" "/usr/local/bin/npm"
       nvm use ${NODE_VERSION}
       echo "-----------------------------------------------------------"
    fi

    if [ "$PHP_VERSION" != "not-set" ]; then
      echo "DOCKWARE: switching to PHP ${PHP_VERSION}..."
      cd /var/www && make switch-php version=${PHP_VERSION}
      echo "-----------------------------------------------------------"
    else
      CURRENT_PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")
      echo "DOCKWARE: Using default PHP version ${CURRENT_PHP_VERSION}..."
      cd /var/www && make switch-php version=${CURRENT_PHP_VERSION}
    fi

    CURRENT_PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")

    # somehow we (once) had the problem that composer does not find a HOME directory this was the solution
    export COMPOSER_HOME=/var/www

    if [ $XDEBUG_ENABLED = 1 ]; then
       sh /var/www/scripts/bin/xdebug_enable.sh
     else
       sh /var/www/scripts/bin/xdebug_disable.sh
    fi

    # make sure the current PHP FPM is started
    echo "DOCKWARE: starting PHP ${CURRENT_PHP_VERSION} FPM..."
    sudo service php${CURRENT_PHP_VERSION}-fpm start
    echo "-----------------------------------------------------------"

    # create log directories for Caddy
    sudo mkdir -p /var/log/caddy
    sudo chown -R www-data:www-data /var/log/caddy
    sudo mkdir -p /var/log/php
    sudo chown -R www-data:www-data /var/log/php

    # Configure Caddy environment variables
    export PHP_VERSION=${CURRENT_PHP_VERSION}
    
    if [ $SUPERVISOR_ENABLED = 1 ]; then
       echo "DOCKWARE: starting supervisord..."
       sudo service supervisor start
    fi

    if [ $FILEBEAT_ENABLED = 1 ]; then
        sudo service filebeat start
    fi

    # prepare the bashrc file for the bash
    # this is from the templates in the assets folder
    echo 'export PS1="\u@\h:\w$ "' > /var/www/.bashrc
    echo 'source ~/.bashrc' >> /var/www/.profile

    # if the project directory exists, add it to our PATH
    if [ -d "/var/www/html" ]; then
       echo 'cd /var/www/html' >> /var/www/.bashrc
       # make sure we have this as owner
       sudo chown -R www-data:www-data /var/www/html
    fi

    if [ -d "/var/www/html/vendor/bin" ]; then
       echo 'export PATH="$PATH:/var/www/html/vendor/bin"' >> /var/www/.bashrc
    fi

    echo 'alias ll="ls -la"' >> /var/www/.bashrc

    # make sure our user can access the bashrc
    sudo chown www-data:www-data /var/www/.bashrc
    sudo chown www-data:www-data /var/www/.profile

    echo "DOCKWARE: setting up Tideways daemon..."
    if [ "${TIDEWAYS_KEY}" != "not-set" ]; then
        echo 'tideways.api_key='${TIDEWAYS_KEY} | sudo tee -a /etc/tideways/tideways-daemon.ini

        # start tideways daemon
        sudo service tideways-daemon start
    fi

    echo "DOCKWARE: creating sample index.php..."
    if [ ! -f "/var/www/html/public/index.php" ]; then
        mkdir -p /var/www/html/public
        echo "<?php echo 'Hello from Dockware with FrankenPHP!'; phpinfo(); ?>" > /var/www/html/public/index.php
        sudo chown www-data:www-data /var/www/html/public/index.php
    fi

    echo "-----------------------------------------------------------"

fi

cd $CONTAINER_STARTUP_DIR

# it's possible to add a custom boot script on startup AFTER
# the original startup. so we test if it exists and just execute it
file="/var/www/boot_end.sh"
if [ -f "$file" ] ; then
    sh $file
fi

echo ""
echo "WOHOOO, diwmarco/web-frankenphp:frankenphp IS READY :) - let's get you started"
echo "-----------------------------------------------------"
echo ""
echo "DOCKWARE CHANGELOG: https://dockware.io/docs/changelog"
echo ""
echo "PHP: $(php -v | head -n 1)"
echo "Node: $(node -v)"
echo "NPM: $(npm -v)"
echo "Yarn: $(yarn -v)"
echo "Composer: $(composer --version | head -n 1)"
echo ""

if [ ! -z "$SSH_USER" ] && [ "$SSH_USER" != "not-set" ]; then
    echo "SSH USER: ${SSH_USER}"
    echo "SSH PWD: ${SSH_PWD}"
else
    echo "SSH USER: dockware"
    echo "SSH PWD: dockware"
fi

echo ""

if [ "${TIDEWAYS_KEY}" != "not-set" ]; then
    echo "TIDEWAYS: ENABLED"
else
    echo "TIDEWAYS: DISABLED"
fi

if [ $XDEBUG_ENABLED = 1 ]; then
    echo "XDEBUG: ENABLED"
else
    echo "XDEBUG: DISABLED"
fi

echo ""
echo "-----------------------------------------------------"

# create a file in here so that our healthcheck
# recognizes that the container is ready
sudo touch /var/www/container.launched

# Start FrankenPHP with Caddy using the configured settings
echo "DOCKWARE: starting FrankenPHP with Caddy..."
exec frankenphp run --config /etc/caddy/Caddyfile --adapter caddyfile