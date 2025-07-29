.PHONY: build build-dev build-all clean test help fast

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

# debug-cache: ## Show cache path for debugging
# 	@echo "MAKEFILE_DIR: $(MAKEFILE_DIR)"
# 	@echo "CACHE_DIR: $(CACHE_DIR)"
# 	@echo "BUILDX_FLAGS: $(BUILDX_FLAGS)"

build: ## Build the final Android development container
	docker buildx bake android-devcontainer

build-dev: ## Build with local cache for development
	@mkdir -p $(CACHE_PATH)
	CACHE_PATH=$(CACHE_PATH) docker buildx bake $(BUILDX_FLAGS) dev

fast: ## Build fast version (without Android SDK) for quick iteration
	@mkdir -p $(CACHE_PATH)
	CACHE_PATH=$(CACHE_PATH) docker buildx bake $(BUILDX_FLAGS) fast

build-all: ## Build all targets
	CACHE_PATH=$(CACHE_PATH) docker buildx bake $(BUILDX_FLAGS) all

build-final: ## Build both final images (devcontainer + emulator)
	@mkdir -p $(CACHE_PATH)
	CACHE_PATH=$(CACHE_PATH) docker buildx bake $(BUILDX_FLAGS) final-images

build-final-dev: ## Build both final images with local cache
	@mkdir -p $(CACHE_PATH)
	CACHE_PATH=$(CACHE_PATH) docker buildx bake $(BUILDX_FLAGS) dev-images

build-emulator: ## Build the emulator container
	@mkdir -p $(CACHE_PATH)
	CACHE_PATH=$(CACHE_PATH) docker buildx bake $(BUILDX_FLAGS) android-emulator

build-github: ## Build with GitHub Actions cache (for testing locally)
	docker buildx bake github-actions

clean: ## Clean up build cache and containers
	docker buildx prune -f
	docker system prune -f
	rm -rf $(CACHE_DIR)

test: ## Test the built container
	docker run --rm android-devcontainer:$(TAG) /usr/local/bin/healthcheck.sh

test-dev: ## Test the development container
	docker run --rm android-devcontainer:dev /usr/local/bin/healthcheck.sh

test-fast: ## Test the fast build container
	docker run --rm android-devcontainer:fast java -version && \
	docker run --rm android-devcontainer:fast which git

test-emulator: ## Test the emulator container
	docker run --rm android-devcontainer:android-emulator /usr/local/bin/healthcheck.sh

shell: ## Run an interactive shell in the container
	docker run -it --rm android-devcontainer:$(TAG) bash

shell-dev: ## Run an interactive shell in the development container
	docker run -it --rm android-devcontainer:dev bash

shell-fast: ## Run an interactive shell in the fast container
	docker run -it --rm android-devcontainer:fast bash

inspect: ## Show information about the built image
	docker image inspect android-devcontainer:$(TAG)

size: ## Show image sizes
	docker images | grep android-devcontainer | head -10
