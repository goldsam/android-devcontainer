# Quick Reference Guide

## Docker Bake Commands

### Build Targets
```bash
# Build final container (default)
docker buildx bake

# Build with development cache
docker buildx bake dev

# Build for GitHub Actions
docker buildx bake github-actions

# Build all components
docker buildx bake all

# Build specific components
docker buildx bake base java cmake gradle tools android-sdk
```

### Using Variables
```bash
# Override versions
CMAKE_VERSION=3.30.0 docker buildx bake cmake

# Set registry and tag
REGISTRY=myregistry.com/ TAG=v1.0 docker buildx bake android-devcontainer
```

### Cache Management
```bash
# Local cache
CACHE_FROM="type=local,src=/tmp/.buildx-cache" docker buildx bake dev

# Registry cache
CACHE_TO="type=registry,ref=myregistry.com/cache,mode=max" docker buildx bake
```

## Makefile Commands
```bash
make help           # Show all available targets
make build          # Build final container
make build-dev      # Build with local cache
make build-all      # Build all components
make test           # Test container functionality
make clean          # Clean caches and images
make shell          # Interactive shell in container
```

## Development Workflow

1. **Initial setup:**
   ```bash
   git clone <repo>
   cd android-devcontainer
   ```

2. **Build for development:**
   ```bash
   make build-dev
   ```

3. **Test changes:**
   ```bash
   make test-dev
   ```

4. **Interactive development:**
   ```bash
   make shell-dev
   ```

## GitHub Actions Usage

The workflow automatically:
- Builds on push/PR
- Uses GitHub Actions cache
- Tests the container
- Pushes to registry (on main branch)

## Cache Locations

- **CMake**: `/var/cache/cmake`
- **Gradle**: `/var/cache/gradle`
- **Android SDK**: `/var/cache/android` + `/opt/android-sdk-cache`
- **Kotlin LSP**: `/var/cache/kotlin`

## Environment Variables in Final Container

```bash
CMAKE_HOME=/opt/cmake
GRADLE_HOME=/opt/gradle
ANDROID_HOME=/opt/android-sdk
ANDROID_NDK_HOME=${ANDROID_HOME}/ndk/${ANDROID_NDK_VERSION}
JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```
