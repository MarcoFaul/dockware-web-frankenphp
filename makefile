.PHONY: help build
.DEFAULT_GOAL := help



help:
	@echo "PROJECT COMMANDS"
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[33mInstallation:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##1 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##1 "}; {printf "\033[33m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[36mDevelopment:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##2 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##2 "}; {printf "\033[36m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[35mDevOps:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##3 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##3 "}; {printf "\033[35m  - %-30s\033[0m %s\n", $$1, $$2}'
	@echo "--------------------------------------------------------------------------------------------"
	@printf "\033[32mTests:%-30s\033[0m %s\n"
	@grep -E '^[a-zA-Z_-]+:.*?##4 .*$$' $(firstword $(MAKEFILE_LIST)) | awk 'BEGIN {FS = ":.*?##4 "}; {printf "\033[32m  - %-30s\033[0m %s\n", $$1, $$2}'

# ----------------------------------------------------------------------------------------------------------------

install: ##1 Installs all dependencies
	composer install

clear: ##1 Clears all dependencies and dangling images
	rm -rf vendor/*
	rm -rf node_modules/*
	cd tests/cypress && make clean
	docker images -aq -f 'dangling=true' | xargs docker rmi
	docker volume ls -q -f 'dangling=true' | xargs docker volume rm

# ----------------------------------------------------------------------------------------------------------------

all: ##2 Helper that builds, tests and analyzes the image
ifndef version
	$(error Please provide the argument version=xyz to run the command)
endif
	make build version=$(version)
	make svrunit version=$(version)
	make cypress version=$(version)
	make analyze version=$(version)

# ----------------------------------------------------------------------------------------------------------------
# ----------------------------------------------------------------------------------------------------------------

build: ##3 Builds the image
ifndef version
	$(error Please provide the argument version=xyz to run the command)
endif
	@cd ./src && DOCKER_BUILDKIT=1 docker build --build-arg IMAGE_VERSION=$(version) -t diwmarco/web-frankenphp:$(version) .

analyze: ##3 Shows the size of the image
ifndef version
	$(error Please provide the argument version=xyz to run the command)
endif
	docker history --format "{{.CreatedBy}}\t\t{{.Size}}" diwmarco/web-frankenphp:$(version) | grep -v "0B"
	# --------------------------------------------------
	docker save -o web.tar diwmarco/web-frankenphp:$(version)
	gzip web.tar
	ls -lh web.tar.gz
	# --------------------------------------------------
	rm -rf web.tar
	rm -rf web.tar.gz | true

# ----------------------------------------------------------------------------------------------------------------

svrunit: ##4 Runs all SVRUnit tests
ifndef version
	$(error Please provide the argument version=xyz to run the command)
endif
	php ./vendor/bin/svrunit test --configuration=./tests/svrunit/suite.xml --docker-tag=$(version) --debug --report-junit --report-html

cypress: ##4 Runs all Cypress tests
ifndef version
	$(error Please provide the argument version=xyz to run the command)
endif
	cd ./tests/cypress && make install
	cd ./tests/cypress && make start-env version=$(version)
	while ! curl -k -s -o /dev/null http://localhost:1000; do echo Waiting for dockware; sleep 1; done
	cd ./tests/cypress && make run url=http://localhost:1000 || (make stop-env && false)
