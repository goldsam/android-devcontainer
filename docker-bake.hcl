# docker-bake.hcl
# Android Development Container Build Configuration

# Variables
variable "CMAKE_VERSION" {
  default = "3.31.8"
}

variable "ANDROID_CMDLINE_TOOLS_VERSION" {
  default = "13114758"
}

variable "ANDROID_NDK_VERSION" {
  default = "27.2.12479018"
}

variable "ANDROID_API_LEVEL" {
  default = "34"
}

variable "ANDROID_BUILD_TOOLS_VERSION" {
  default = "34.0.0"
}

variable "KOTLIN_LSP_VERSION" {
  default = "0.252.17811"
}

variable "GRADLE_VERSION" {
  default = "8.10.2"
}

variable "REGISTRY" {
  default = ""
}

variable "TAG" {
  default = "latest"
}

variable "CACHE_PATH" {
  default = ".buildx-cache"
}

# Groups
group "default" {
  targets = ["android-devcontainer"]
}

group "all" {
  targets = ["base", "java", "cmake", "gradle", "tools", "android-sdk", "android-devcontainer"]
}

# Base OS target
target "base" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.base"
  tags = ["android-devcontainer:base"]
  platforms = ["linux/amd64"]
}

# Java runtime target
target "java" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.java"
  contexts = {
    base-image = "target:base"
  }
  tags = ["android-devcontainer:java"]
  platforms = ["linux/amd64"]
}

# CMake target
target "cmake" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.cmake"
  contexts = {
    base-image = "target:base"
  }
  args = {
    CMAKE_VERSION = CMAKE_VERSION
  }
  tags = ["android-devcontainer:cmake"]
  platforms = ["linux/amd64"]
}

# Gradle target
target "gradle" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.gradle"
  contexts = {
    base-image = "target:base"
  }
  args = {
    GRADLE_VERSION = GRADLE_VERSION
  }
  tags = ["android-devcontainer:gradle"]
  platforms = ["linux/amd64"]
}

# Tools target
target "tools" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.tools"
  contexts = {
    java-image = "target:java"
  }
  args = {
    KOTLIN_LSP_VERSION = KOTLIN_LSP_VERSION
  }
  tags = ["android-devcontainer:tools"]
  platforms = ["linux/amd64"]
}

# Android SDK target
target "android-sdk" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.android"
  contexts = {
    java-image = "target:java"
  }
  args = {
    ANDROID_CMDLINE_TOOLS_VERSION = ANDROID_CMDLINE_TOOLS_VERSION
    ANDROID_NDK_VERSION = ANDROID_NDK_VERSION
    ANDROID_API_LEVEL = ANDROID_API_LEVEL
    ANDROID_BUILD_TOOLS_VERSION = ANDROID_BUILD_TOOLS_VERSION
  }
  tags = ["android-devcontainer:android-sdk"]
  platforms = ["linux/amd64"]
}

# Final Android development container
target "android-devcontainer" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.final"
  contexts = {
    tools-image = "target:tools"
    cmake-image = "target:cmake"
    gradle-image = "target:gradle"
    android-image = "target:android-sdk"
  }
  args = {
    ANDROID_NDK_VERSION = ANDROID_NDK_VERSION
    ANDROID_BUILD_TOOLS_VERSION = ANDROID_BUILD_TOOLS_VERSION
  }
  tags = ["android-devcontainer:${TAG}"]
  platforms = ["linux/amd64"]
}

# Development target with local cache
target "dev" {
  inherits = ["android-devcontainer"]
  cache-from = [
    "type=local,src=${CACHE_PATH}"
  ]
  cache-to = [
    "type=local,dest=${CACHE_PATH},mode=max"
  ]
  tags = ["android-devcontainer:dev"]
}

# GitHub Actions target with GHA cache
target "github-actions" {
  inherits = ["android-devcontainer"]
  cache-from = [
    "type=gha,scope=android-build"
  ]
  cache-to = [
    "type=gha,mode=max,scope=android-build"
  ]
}

# Fast build target (tools only)
target "fast" {
  inherits = ["tools"]
  tags = ["android-devcontainer:fast"]
  cache-from = [
    "type=local,src=${CACHE_PATH}"
  ]
  cache-to = [
    "type=local,dest=${CACHE_PATH},mode=max"
  ]
}
