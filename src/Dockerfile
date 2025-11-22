# Official Dockware Image with FrankenPHP
# Copyright 2025 dasistweb GmbH
#
ARG IMAGE_VERSION=latest

FROM dunglas/frankenphp:1-php8.3-bookworm
LABEL title="Dockware web-frankenphp:latest" \
      version=${IMAGE_VERSION} \
      maintainer="dasistweb GmbH"

## ***********************************************************************
##  IMAGE VARIABLES
## ***********************************************************************
ENV TZ=Europe/Berlin
ENV PHP_VERSION=8.3
ENV NODE_VERSION=not-set
ENV FRANKENPHP_CONFIG="worker /var/www/html/public/frankenphp-worker.php"
ENV CADDY_ROOT=/var/www/html/public
ENV RECOVERY_MODE=0
ENV SSH_USER=not-set
ENV SSH_PWD=not-set
ENV XDEBUG_REMOTE_HOST="host.docker.internal"
ENV XDEBUG_CONFIG="idekey=PHPSTORM"
ENV PHP_IDE_CONFIG="serverName=localhost"
ENV XDEBUG_ENABLED=0
ENV FILEBEAT_ENABLED=0
ENV SUPERVISOR_ENABLED=0
ENV TIDEWAYS_KEY=not-set
ENV BASH_ENV=/var/www/.bashrc

# these are all our files that we need to setup the image
COPY --chmod=0755 ./scripts /dockware/tmp/scripts
COPY --chmod=0755 ./config /dockware/tmp/config

# this are runtime executables for users
COPY --chmod=0755 ./assets/scripts/makefile /var/www/makefile
COPY --chmod=0755 ./assets/scripts/bin /var/www/scripts/bin

# Caddy configuration
COPY --chmod=0644 ./config/caddy/Caddyfile /etc/caddy/Caddyfile

# FrankenPHP worker script
COPY --chmod=0644 ./config/frankenphp/worker.php /var/www/html/public/frankenphp-worker.php

# now comment haha, thats clear
COPY --chmod=0755 entrypoint.sh /entrypoint.sh

# -------------------------------------------------------------------------------------------------------

# these are identifier values
# that are read and shown to the user about this image
RUN mkdir -p /dockware && \
    echo "${IMAGE_VERSION}" > /dockware/version.txt && \
    date >/dockware/build-date.txt && \
    echo "$(date +%Y) dasistweb GmbH" > /dockware/copyright.txt && \
    mkdir -p /var/www && \
    mkdir -p /var/www/scripts && \
    mkdir -p /var/dockware/cache

RUN echo "id:env-variables" && \
    echo "export TZ=${TZ}" >> /etc/profile \
    && echo "export PHP_VERSION=${PHP_VERSION}" >> /etc/profile \
    && echo "export CADDY_ROOT=${CADDY_ROOT}" >> /etc/profile \
    && echo "export NODE_VERSION=${NODE_VERSION}" >> /etc/profile \
    && echo "export RECOVERY_MODE=${RECOVERY_MODE}" >> /etc/profile \
    && echo "export SSH_USER=${SSH_USER}" >> /etc/profile \
    && echo "export SSH_PWD=${SSH_PWD}" >> /etc/profile \
    && echo "export XDEBUG_ENABLED=${XDEBUG_ENABLED}" >> /etc/profile \
    && echo "export XDEBUG_REMOTE_HOST=${XDEBUG_REMOTE_HOST}" >> /etc/profile \
    && echo "export XDEBUG_CONFIG=${XDEBUG_CONFIG}" >> /etc/profile \
    && echo "export PHP_IDE_CONFIG=${PHP_IDE_CONFIG}" >> /etc/profile \
    && echo "export FILEBEAT_ENABLED=${FILEBEAT_ENABLED}" >> /etc/profile \
    && echo "export SUPERVISOR_ENABLED=${SUPERVISOR_ENABLED}" >> /etc/profile \
    && echo "export TIDEWAYS_KEY=${TIDEWAYS_KEY}" >> /etc/profile \
    && echo "export FRANKENPHP_CONFIG=${FRANKENPHP_CONFIG}" >> /etc/profile

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##  BASE REQUIREMENTS
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RUN echo "id:basics" && \
    apt-get update && \
    # first install tools to add repositories
    apt-get install -y wget gnupg2 sudo apt-transport-https software-properties-common ca-certificates && \
    # Add Ondrej PHP repository manually without using add-apt-repository
    wget -qO - https://packages.sury.org/php/apt.gpg | gpg --dearmor | tee /usr/share/keyrings/php.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/php.gpg] https://packages.sury.org/php/ bookworm main" | tee /etc/apt/sources.list.d/php.list && \
    # Add Elasticsearch repository
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor | tee /usr/share/keyrings/elastic.gpg > /dev/null && \
    echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-7.x.list && \
    # Add Tideways repository
    wget -qO - 'https://packages.tideways.com/key.gpg' | gpg --dearmor | tee /usr/share/keyrings/tideways.gpg > /dev/null && \
    echo 'deb [signed-by=/usr/share/keyrings/tideways.gpg] https://packages.tideways.com/apt-packages-main any-version main' | tee /etc/apt/sources.list.d/tideways.list && \
    # update our repositories
    apt-get update && \
    # now have fun installing stuff (removed apache packages)
    apt-get install -y --no-install-recommends \
            gosu \
            make \
            curl \
            vim \
            unzip \
            bzip2 \
            zstd \
            ssmtp \
            lsof \
            openssh-server openssl sshpass \
            cron \
            jq \
            gpg-agent \
            rsync \
            supervisor \
            jpegoptim \
            default-mysql-client \
            git git-lfs patch \
            tideways-php tideways-daemon \
            filebeat && \
    mkdir /var/run/sshd && \
    ln -fs /usr/share/zoneinfo/Europe/Berlin /etc/localtime && echo "${TZ}" > /etc/timezone && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##  USER MANAGEMENT
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RUN echo "id:users" && \
    echo "root:root" | chpasswd \
    # set password for www-data, and also
    # avoid shell login (we have a separate user for that)
    echo 'www-data:www-data' | chpasswd && \
    usermod -s /usr/sbin/nologin www-data && \
    # this option makes sure to avoid root SSH login
    # we just replace our lines with nothing
    sed -i 's/PermitRootLogin without-password//' /etc/ssh/sshd_config && \
    sed -i 's/PermitRootLogin prohibit-password//' /etc/ssh/sshd_config && \
    # allow root and sudo group to run sudo without password
    sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g' && \
    sed -i /etc/sudoers -re 's/^root.*/root ALL=(ALL:ALL) NOPASSWD: ALL/g'  &&\
    # remove include directory
    sed -i /etc/sudoers -re 's/^#includedir.*/## **Removed the include directive** ##"/g' && \
    # add our dockware user
    adduser --disabled-password --uid 5577 --gecos "" --ingroup www-data dockware && \
    usermod -m -d /var/www dockware | true && \
    echo "dockware:dockware" | chpasswd && \
    usermod -a -G sudo dockware && \
    # allow sudo without pwd and dont require tty (for entrypoint commands)
    echo "Defaults:dockware !requiretty" >> /etc/sudoers && \
    sed -i 's/dockware:x:5577:33:/dockware:x:33:33:/g' /etc/passwd && \
    echo 'AllowUsers dockware' >> /etc/ssh/sshd_config && \
    # create a new id_rsa for the www-data dockeruser.
    # thus we have a SSH Key for connections out of the box
    mkdir -p /var/www/.ssh && \
    rm -rf /var/www/.ssh/id_rsa; true && \
    rm -rf /var/www/.ssh/id_rsa.pub; true && \
    ssh-keygen -t rsa -b 4096 -f /var/www/.ssh/id_rsa -C "Dockware Container" -P "" && \
    chown -R www-data:www-data /var/www/.ssh && \
    chmod 0700 /var/www/.ssh && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------
##  PHP INSTALLATION
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------

RUN echo "id:php" && \
    sudo apt-get update && \
    cd /dockware/tmp/scripts && bash install_php.sh && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/tmp --version=2.2.9 --quiet && \
    # prepare "global" composer directory for www-data
    mkdir -p /var/www/.composer && \
    export COMPOSER_HOME="/var/www/.composer" && \
    chmod 755 /tmp/composer.phar && \
    mv /tmp/composer.phar /usr/local/bin/composer && \
    chown -R 33:33 /var/www/.composer && \
    # make sure the configured log folder exists and is writeable
    chmod -R 0777 /var/www && \
    mkdir /var/log/php -p  && \
    touch /var/log/php/cli_errors.log && \
    touch /var/log/php/fpm_errors.log && \
    chown -R www-data:www-data /var/log/php && \
    chmod 0755 /var/log/php && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## ***********************************************************************
##  NODE INSTALLATION
## ***********************************************************************

RUN echo "id:node" && \
    cd /dockware/tmp/scripts && bash install_node.sh && \
    mkdir /var/www/.npm && \
    npm config set cache /var/www/.npm && \
    cd /var/www && npm install -g --no-install-recommends yarn && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## ***********************************************************************
##  PERMISSIONS
## ***********************************************************************

RUN echo "id:permissions" && \
    chown 33:33 -R /var/www/.composer && \
    chown 33:33 -R /var/www/.npm && \
    chown 33:33 -R /var/www/scripts && \
    chown 33:33 -R /var/www/html && \
    rm -rf /dockware/tmp && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

## ***********************************************************************
## SWITCH TO NORMAL USER (NOT ROOT ANYMORE!)
## everything down here is now done as our www-data / dockware user
## just like you would do it manually in the container
## ***********************************************************************

USER dockware

# make the apache folder the working directory
WORKDIR /var/www/html

## ***********************************************************************
##  POST BUILD
## ***********************************************************************

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]

HEALTHCHECK --interval=5s --timeout=3s --retries=10 CMD [ "sh", "-c", "test -f /var/www/container.launched" ]