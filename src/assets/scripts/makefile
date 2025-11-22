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
	@# FrankenPHP uses its own PHP runtime, only configure CLI for development
	@# ---------------------------------------------------------------------------------------
	@# Determine FrankenPHP built-in PHP version dynamically
	@FRANKENPHP_VERSION=$$(command -v php >/dev/null 2>&1 && php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;' 2>/dev/null || echo ""); \
	if [ "$(version)" = "$$FRANKENPHP_VERSION" ] && command -v php >/dev/null 2>&1; then \
		echo "Using FrankenPHP built-in PHP $(version)"; \
		export PHP_VERSION=$(version); \
	elif command -v php$(version) >/dev/null 2>&1; then \
		if [ -f "/etc/php/$(version)/cli/conf.d/01-general.ini" ]; then \
			sudo sed -i '/^date\.timezone/c\date.timezone = $(TZ)' /etc/php/$(version)/cli/conf.d/01-general.ini; \
		fi; \
		sudo update-alternatives --set php $$(which php$(version)) 2>/dev/null || true; \
		export PHP_VERSION=$(version); \
		echo "Switched CLI PHP to version $(version)"; \
	else \
		echo "PHP version $(version) not found"; \
		echo "Available PHP versions:"; \
		ls /usr/bin/php* 2>/dev/null | grep -E 'php[0-9]\.' | sort || echo "No additional PHP versions found"; \
		if [ -n "$$FRANKENPHP_VERSION" ]; then \
			echo "FrankenPHP provides PHP $$FRANKENPHP_VERSION by default"; \
		fi; \
		echo "Version $(version) may not be installed"; \
		exit 1; \
	fi
	@# ---------------------------------------------------------------------------------------
	@# Handle Xdebug for CLI
ifeq ($(XDEBUG_STATUS),1)
	make xdebug-on
else
	make xdebug-off
endif
	@echo "Note: FrankenPHP uses its own PHP runtime. Container restart may be needed for web requests."
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

restart-php: ##1 Note: PHP runtime is managed by FrankenPHP
	@echo "FrankenPHP manages its own PHP runtime."
	@echo "To restart the PHP runtime, restart the container:"
	@echo "  docker restart <container_name>"

restart-frankenphp: ##1 Restarts FrankenPHP (requires container restart)
	@echo "FrankenPHP restart requires container restart."
	@echo "Run: docker restart <container_name>"

# -------------------------------------------------------------------------------------------------

xdebug-on: ##2 Enables Xdebug
	sh /var/www/scripts/bin/xdebug_enable.sh

xdebug-off: ##2 Disables Xdebug
	sh /var/www/scripts/bin/xdebug_disable.sh