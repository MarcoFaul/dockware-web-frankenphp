.PHONY: help
.DEFAULT_GOAL := help

PHP_VERSION_CURRENT=$(shell php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
XDEBUG_STATUS=$(shell php -r 'echo (int)extension_loaded("xdebug");')

help:
	@echo "COMMANDS"
	@echo "---------------------------------------------------------------------------------------------------------"
	@printf "\033[33mSystem:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##1 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##1 "}; {printf "\033[33m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "---------------------------------------------------------------------------------------------------------"
	@printf "\033[36mDev:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##2 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##2 "}; {printf "\033[36m  - %-30s\033[0m %s\n", $$1, $$2}'

# -------------------------------------------------------------------------------------------------

status: ##1 Display status of the system
	sh /var/www/scripts/bin/status.sh

switch-php: ##1 Switches to another supported PHP version, [make switch-php version=x.y]
ifndef version
	$(warning Provide the required PHP version using "make switch-php version=x.y")
	@exit 1;
endif
	@# ATTENTION, keep this steps exactly like they are. they ensure that its fail-fast
	@# non existing PHP versions will do nothing, switching to the same php version will also work
	@# ---------------------------------------------------------------------------------------
	sudo sed -i '/^date\.timezone/c\date.timezone = $(TZ)' /etc/php/$(version)/fpm/conf.d/01-general.ini
	sudo sed -i '/^date\.timezone/c\date.timezone = $(TZ)' /etc/php/$(version)/cli/conf.d/01-general.ini
	@# ---------------------------------------------------------------------------------------
	@# Start new PHP to see if its existing, then stop current one, and if we use the same php version that
	@# is currently used, just make sure to start it again ;)
	sudo service php$(version)-fpm start
	sudo service php$(PHP_VERSION_CURRENT)-fpm stop
	sudo service php$(version)-fpm start
	export PHP_VERSION=$(version)
	@# ---------------------------------------------------------------------------------------
	@# Update Caddy configuration with the new PHP version
	@# Update environment variable for current session
	export PHP_VERSION=$(version)
	@# ---------------------------------------------------------------------------------------
	@# last but not least update php for cli -> this is used for our variable in here
	sudo update-alternatives --set php /usr/bin/php$(version)
ifeq ($(XDEBUG_STATUS),1)
	make xdebug-on
else
	make xdebug-off
endif
	php -v

switch-node: ##1 Switches to another supported NodeJS version, [make switch-node version=x.y]
ifndef version
	$(warning Provide the required Node version using "make switch-node version=x.y")
	@exit 1;
endif
	nvm use $(version)

permission-repair: ##1 Repairs file permissions
	sudo chown -R 33:33 /var/www/html/*
	sudo chmod -R 775 /var/www/html

restart-php: ##1 Restarts PHP-FPM service
	sudo service php$(PHP_VERSION_CURRENT)-fpm stop
	sudo service php$(PHP_VERSION_CURRENT)-fpm start
	@echo "PHP-FPM restarted. FrankenPHP will automatically detect the changes."

restart-frankenphp: ##1 Restarts FrankenPHP (requires container restart)
	@echo "FrankenPHP restart requires container restart."
	@echo "Run: docker restart <container_name>"

# -------------------------------------------------------------------------------------------------

xdebug-on: ##2 Enables Xdebug
	sh /var/www/scripts/bin/xdebug_enable.sh

xdebug-off: ##2 Disables Xdebug
	sh /var/www/scripts/bin/xdebug_disable.sh