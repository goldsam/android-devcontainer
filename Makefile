.PHONY: build build-dev build-all clean test help fast

# Variables
TAG ?= latest
REGISTRY ?= 
CACHE_DIR ?= /tmp/.buildx-cache
BUILDX_FLAGS ?= --allow=fs=$(CACHE_DIR)

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the final Android development container
	docker buildx bake android-devcontainer

build-dev: ## Build with local cache for development
	docker buildx bake $(BUILDX_FLAGS) dev

fast: ## Build fast version (without Android SDK) for quick iteration
	docker buildx bake $(BUILDX_FLAGS) fast

build-all: ## Build all targets
	docker buildx bake $(BUILDX_FLAGS) all

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
