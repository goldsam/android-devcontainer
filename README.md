# Android Development Container

This project provides a comprehensive Android development environment using Docker with optimized caching for faster builds and efficient CI/CD pipelines.

## Features

- **Multi-stage optimized builds** with dedicated Dockerfiles for each component
- **Advanced caching** using Docker BuildKit cache mounts and GitHub Actions cache
- **Modular architecture** allowing individual component updates without rebuilding everything
- **Complete Android development stack**:
  - Android SDK & NDK
  - Java 17 OpenJDK
  - Gradle
  - CMake
  - Git, Ninja, ccache, and other build tools

## Quick Start

### Prerequisites

- Docker with BuildKit support
- Docker Buildx plugin

### Building Locally

```bash
# Build the development container with local cache
make build-dev

# Build all components
make build-all

# Test the built container
make test-dev
```

### Using with GitHub Actions

The repository includes a GitHub Actions workflow that automatically builds and caches the container. The cache is shared across builds for maximum efficiency.

## Architecture

The build system is split into modular components:

1. **base** - Ubuntu 22.04 with essential packages
2. **java** - Java 17 OpenJDK runtime
3. **cmake** - CMake build system
4. **gradle** - Gradle build tool
5. **tools** - Development tools (git, ninja, ccache, etc.)
6. **android-sdk** - Android SDK and NDK
7. **android-devcontainer** - Final assembled container

## Build Configuration

### docker-bake.hcl

The main build configuration uses Docker Bake for:
- **Parallel builds** of independent components
- **Cache optimization** with mount caches for downloads
- **Flexible targeting** for different environments
- **Variable substitution** for version management

### Cache Strategy

#### Local Development
```bash
# Uses local filesystem cache
docker buildx bake dev
```

#### GitHub Actions
```bash
# Uses GitHub Actions cache with scoped layers
docker buildx bake github-actions
```

#### Custom Cache
```bash
# Export cache to registry
CACHE_TO="type=registry,ref=myregistry.com/cache,mode=max" docker buildx bake android-devcontainer
```

### Build Targets

- `android-devcontainer` - Main target (default)
- `github-actions` - Optimized for GitHub Actions with GHA cache
- `dev` - Development target with local cache
- `all` - Build all intermediate targets

## Customization

### Version Variables

Edit `docker-bake.hcl` to customize versions:

```hcl
variable "CMAKE_VERSION" {
  default = "3.31.8"
}

variable "ANDROID_NDK_VERSION" {
  default = "27.2.12479018"
}

variable "GRADLE_VERSION" {
  default = "8.10.2"
}
```

### Build Arguments

Override at build time:

```bash
CMAKE_VERSION=3.30.0 docker buildx bake android-devcontainer
```

## Cache Optimization Features

1. **Download Caching**: Downloaded artifacts (CMake, Gradle, Android SDK) are cached using BuildKit cache mounts
2. **Conditional Downloads**: Scripts check if artifacts exist in cache before downloading
3. **Layer Caching**: Each component is built independently for optimal layer reuse
4. **GitHub Actions Integration**: Automatic cache management in CI/CD

## Usage Examples

### Local Development

```bash
# Build and run interactively
make build-dev
make shell-dev

# Run with volume mounts for development
docker run -it --rm \
  -v $(pwd):/workspace \
  -v android-gradle-cache:/home/vscode/.gradle \
  android-devcontainer:dev bash
```

### CI/CD Integration

The included GitHub Actions workflow demonstrates:
- Automatic building on push/PR
- Cache optimization across builds  
- Container testing with health checks
- Optional registry pushing

### VS Code DevContainer

Create `.devcontainer/devcontainer.json`:

```json
{
  "name": "Android Development",
  "image": "android-devcontainer:latest",
  "features": {},
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-vscode.cpptools",
        "ms-python.python",
        "vscjava.vscode-java-pack"
      ]
    }
  }
}
```

## Maintenance

### Updating Dependencies

1. Update version variables in `docker-bake.hcl`
2. Test locally: `make build-dev && make test-dev`
3. Commit and push for CI validation

### Cache Management

```bash
# Clean local cache
make clean

# Inspect cache usage
docker system df

# Prune unused cache
docker buildx prune
```

## Troubleshooting

### Build Issues

1. **Cache conflicts**: Run `make clean` to reset local cache
2. **Network timeouts**: Check internet connectivity and proxy settings
3. **Disk space**: Ensure sufficient space for cache and layers

### Runtime Issues

1. **Permission problems**: Ensure proper user setup in final stage
2. **Missing tools**: Verify health check script passes
3. **Android SDK issues**: Check ANDROID_HOME and PATH variables

## Contributing

1. Fork the repository
2. Create a feature branch
3. Test changes with `make build-all && make test`
4. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.