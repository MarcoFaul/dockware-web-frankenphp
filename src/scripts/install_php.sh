#!/bin/bash

# a key value list of php versions and their folder names
PHP_VERSIONS=(
    "8.5:20250925"
    "8.4:20240924"
    "8.3:20230831"
    "8.2:20220829"
    "8.1:20210902"
    "8.0:20200930"
    "7.4:20190902"
    # "7.3:20180731"
    # "7.2:20170718"
    # "7.1:20160303"
    # "7.0:20151012"
    # "5.6:20131226"
)

DEFAULT_PHP_VERSION=${PHP_VERSION:-8.3}

# -----------------------------------------------------------------------------------------

for entry in "${PHP_VERSIONS[@]}"; do
    version="${entry%%:*}"
    phpFolderId="${entry##*:}"

    # -----------------------------------------------------------
    # PHP
    sh ./php/install_php$version.sh

    # Only configure CLI as FrankenPHP handles web requests
    if [ -d "/etc/php/$version/cli/" ]; then
        cat /dockware/tmp/config/php/general.ini >| /etc/php/$version/cli/conf.d/01-general.ini
        cat /dockware/tmp/config/php/cli.ini >| /etc/php/$version/cli/conf.d/01-general-cli.ini
        
        # -----------------------------------------------------------
        # Xdebug (CLI only for FrankenPHP setup)
        if [ -f "/dockware/tmp/config/php/xdebug-3.ini" ]; then
            sed "s/__PHP__FOLDER__ID/$phpFolderId/g" /dockware/tmp/config/php/xdebug-3.ini > /etc/php/$version/cli/conf.d/20-xdebug.ini
        fi

        # -----------------------------------------------------------
        # Tideways (CLI only for FrankenPHP setup)
        if [ -f "/usr/lib/tideways/tideways-php-$version.so" ]; then
            sudo ln -sf /usr/lib/tideways/tideways-php-$version.so /usr/lib/php/$phpFolderId/tideways.so || true
            if [ -f "/dockware/tmp/config/php/tideways.ini" ]; then
                sed "s/__PHP__FOLDER__ID/$phpFolderId/g" /dockware/tmp/config/php/tideways.ini > /etc/php/$version/cli/conf.d/20-tideways.ini
            fi
        fi
    fi

done

# -----------------------------------------------------------------------------------------

# Set the default PHP version
sudo update-alternatives --set php /usr/bin/php$DEFAULT_PHP_VERSION > /dev/null 2>&1 &

# -----------------------------------------------------------------------------------------

# Set PHP alternatives (no FPM needed for FrankenPHP)
sudo update-alternatives --set php /usr/bin/php$DEFAULT_PHP_VERSION > /dev/null 2>&1

# -----------------------------------------------------------------------------------------

# Create session directory for CLI usage (if it exists)
if [ -d "/var/lib/php/sessions" ]; then
    chown www-data:www-data -R /var/lib/php/sessions
fi