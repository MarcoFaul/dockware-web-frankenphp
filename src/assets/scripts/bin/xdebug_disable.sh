echo "DOCKWARE: deactivating Xdebug..."

#make sure we use the current running php version and not that one from the ENV
CURRENT_PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION . '.' . PHP_MINOR_VERSION;")

# For FrankenPHP, only manage CLI Xdebug (web requests use FrankenPHP's built-in PHP)
if [ -f "/etc/php/${CURRENT_PHP_VERSION}/cli/conf.d/20-xdebug.ini" ]; then
    sudo mv /etc/php/${CURRENT_PHP_VERSION}/cli/conf.d/20-xdebug.ini /etc/php/${CURRENT_PHP_VERSION}/cli/conf.d/20-xdebug.ini_disabled > /dev/null 2>&1
    echo "Xdebug disabled for CLI PHP ${CURRENT_PHP_VERSION}"
else
    echo "No Xdebug configuration found for CLI PHP ${CURRENT_PHP_VERSION}"
fi

# Note: FrankenPHP restart required for web Xdebug changes
echo "Note: Restart container for FrankenPHP Xdebug changes to take effect"