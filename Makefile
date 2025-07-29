.PHONY: test build build-github clean help

# Variables
TAG ?= latest
REGISTRY ?= 
CACHE_DIR ?= .buildx-cache
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CACHE_PATH := $(MAKEFILE_DIR)$(CACHE_DIR)
BUILDX_FLAGS ?= --allow=fs=$(CACHE_PATH)

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

debug-cache: ## Show cache path for debugging
	@echo "MAKEFILE_DIR: $(MAKEFILE_DIR)"
	@echo "CACHE_DIR: $(CACHE_DIR)"
	@echo "BUILDX_FLAGS: $(BUILDX_FLAGS)"

build: ## Build with local disk cache (development)
	@mkdir -p $(CACHE_PATH)
	CACHE_PATH=$(CACHE_PATH) docker buildx bake $(BUILDX_FLAGS)

build-github: ## Build with GitHub Actions cache (CI)
	docker buildx bake --files docker-bake.hcl --files docker-bake.gha.hcl

clean: ## Purge build cache and containers
	docker buildx prune -f
	docker system prune -f
	rm -rf $(CACHE_DIR)

test: ## Test the built devcontainer
	docker run --rm android-devcontainer:$(TAG) /usr/local/bin/healthcheck.sh
