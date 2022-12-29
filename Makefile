#!make
include .build.env

BUILD_DATE ?= $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')

_BUILD_ARGS_TAG ?= latest
_BUILD_ARGS_TARGET ?= prd

.DEFAULT_GOAL := help
.PHONY: help build test

help: ## Show this help
	@egrep '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

build: ## Build Docker image (PRD)
		$(MAKE) _build_prd

build-dev: ## Build Docker image (DEV)
		$(MAKE) _build_dev

_build_%: 
		$(MAKE) _builder \
			-e _BUILD_ARGS_TAG="${ELASTICMS_ADMIN_VERSION}-$*" \
			-e _BUILD_ARGS_TARGET="$*"

_builder:
		docker build \
			--build-arg VERSION_ARG="${ELASTICMS_ADMIN_VERSION}" \
			--build-arg RELEASE_ARG="${_BUILD_ARGS_TAG}" \
			--build-arg BUILD_DATE_ARG="${BUILD_DATE}" \
			--build-arg VCS_REF_ARG="${GIT_HASH}" \
			--target ${_BUILD_ARGS_TARGET} \
			--tag ${DOCKER_IMAGE_NAME}:${_BUILD_ARGS_TAG} .

test: ## Test Docker image (PRD)
		$(MAKE) _tester_prd

test-dev: ## Test Docker image (DEV)
		$(MAKE) _tester_dev

_tester_%: 
		$(MAKE) _tester \
			-e DOCKER_IMAGE_NAME="${DOCKER_IMAGE_NAME}:${ELASTICMS_ADMIN_VERSION}-$*"

_tester:
		bats test/tests.bats