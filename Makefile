# PROJECT_NAME defaults to name of the current directory.
# should not to be changed if you follow GitOps operating procedures.
PROJECT_NAME = $(notdir $(PWD))

##
## This makefile is allows for the following commands:
##
## COMMAND         | Description
##--------------------------------------------------------------------
DOCKER_COMPOSE_MAIN_FILE_NAME = docker-compose.yml
DOCKER_COMPOSE_TEST_FILE_NAME = docker-compose.test.yml

.PHONY: build build-test clean deploy deploy-attach help precommit rebuild rebuild-test

## build           | Builds the main service
build:
	NODE_ENV=$(NODE_ENV) docker-compose --file $(DOCKER_COMPOSE_MAIN_FILE_NAME) build

## build-test      | Builds the test docker image
build-test:
	NODE_ENV=$(NODE_ENV) docker-compose --file $(DOCKER_COMPOSE_TEST_FILE_NAME) build

## clean           | Stops all docker containers running
clean:
	docker-compose --file $(DOCKER_COMPOSE_MAIN_FILE_NAME) --file $(DOCKER_COMPOSE_TEST_FILE_NAME) \
	down --remove-orphans --rmi all

## deploy          | Deploys the main service
deploy: build
	docker-compose --file $(DOCKER_COMPOSE_MAIN_FILE_NAME) up --detach

## deploy-attach   | Deploys the main service without detaching
deploy-attach: build
	docker-compose --file $(DOCKER_COMPOSE_MAIN_FILE_NAME) up

# test-unit       | Runs the unit tests
test-unit: build-test
	NODE_ENV=$(NODE_ENV) docker-compose --file $(DOCKER_COMPOSE_TEST_FILE_NAME) run test-unit

## help            | Outputs the possible make commands
help: Makefile
	@sed -n 's/^##//p' $<

## precommit       | Runs necessary build/tests before committing
precommit: build build-test test-unit

## rebuild         | Builds the main service with no caching and pulling in the latest images
rebuild:
	NODE_ENV=$(NODE_ENV) docker-compose --file $(DOCKER_COMPOSE_MAIN_FILE_NAME) build --no-cache --pull

## rebuild-test    | Builds the test image with no caching and pulling in the latest image
rebuild-test:
	docker-compose --file $(DOCKER_COMPOSE_TEST_FILE_NAME) build --no-cache --pull
