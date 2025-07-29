# docker-bake.hcl
# Android Development Container and Emulator

# -----------------------------------------------------------------------------
# Caching Variables
# -----------------------------------------------------------------------------

variable "CACHE_PATH" {
  default = ".buildx-cache"
}

variable "cache-from" {
  default = ["type=local,src=${CACHE_PATH}"]
}

variable "cache-to" {
  default = ["type=local,dest=${CACHE_PATH},mode=max"]
}

# Version args

variable "CMAKE_VERSION"                  { default = "3.31.8" }
variable "ANDROID_CMDLINE_TOOLS_VERSION"  { default = "13114758" }
variable "ANDROID_NDK_VERSION"            { default = "27.2.12479018" }
variable "ANDROID_API_LEVEL"              { default = "34" }
variable "ANDROID_BUILD_TOOLS_VERSION"    { default = "34.0.0" }
variable "KOTLIN_LSP_VERSION"             { default = "0.252.17811" }
variable "GRADLE_VERSION"                 { default = "8.10.2" }
variable "REGISTRY"                       { default = "" }
variable "TAG"                            { default = "latest" }

# -----------------------------------------------------------------------------
# Groups
# -----------------------------------------------------------------------------

group "default" {
  targets = ["android-devcontainer", "android-emulator"]
}

# -----------------------------------------------------------------------------
# Build Targets
# -----------------------------------------------------------------------------

target "base" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.base"
  platforms = ["linux/amd64"]
  cache-from = "${cache-from}"
  cache-to = "${cache-to}"
}

target "java" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.java"
  contexts = {
    base-image = "target:base"
  }
  platforms = ["linux/amd64"]
  cache-from = "${cache-from}"
  cache-to = "${cache-to}"
}

target "cmake" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.cmake"
  contexts = {
    base-image = "target:base"
  }
  args = {
    CMAKE_VERSION = CMAKE_VERSION
  }
  platforms = ["linux/amd64"]
  cache-from = "${cache-from}"
  cache-to = "${cache-to}"
}

target "gradle" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.gradle"
  contexts = {
    base-image = "target:base"
  }
  args = {
    GRADLE_VERSION = GRADLE_VERSION
  }
  platforms = ["linux/amd64"]
  cache-from = "${cache-from}"
  cache-to = "${cache-to}"
}

target "tools" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.tools"
  contexts = {
    java-image = "target:java"
  }
  args = {
    KOTLIN_LSP_VERSION = KOTLIN_LSP_VERSION
  }
  platforms = ["linux/amd64"]
  cache-from = "${cache-from}"
  cache-to = "${cache-to}"
}

target "android-tools" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.android-tools"
  contexts = {
    java-image = "target:java"
  }
  args = {
    ANDROID_CMDLINE_TOOLS_VERSION = ANDROID_CMDLINE_TOOLS_VERSION
    ANDROID_API_LEVEL = ANDROID_API_LEVEL
  }
  platforms = ["linux/amd64"]
  cache-from = "${cache-from}"
  cache-to = "${cache-to}"
}

target "android-devcontainer" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.devcontainer-final"
  contexts = {
    tools-image = "target:tools"
    cmake-image = "target:cmake"
    gradle-image = "target:gradle"
    android-tools-image = "target:android-tools"
  }
  args = {
    ANDROID_CMDLINE_TOOLS_VERSION = ANDROID_CMDLINE_TOOLS_VERSION
    ANDROID_NDK_VERSION = ANDROID_NDK_VERSION
    ANDROID_API_LEVEL = ANDROID_API_LEVEL
    ANDROID_BUILD_TOOLS_VERSION = ANDROID_BUILD_TOOLS_VERSION
  }
  tags = ["android-devcontainer:${TAG}"]
  platforms = ["linux/amd64"]
  cache-from = "${cache-from}"
  cache-to = "${cache-to}"
}

target "android-emulator" {
  context = "."
  dockerfile = "dockerfiles/Dockerfile.emulator-final"
  contexts = {
    android-tools-image = "target:android-tools"
  }
  args = {
    ANDROID_API_LEVEL = ANDROID_API_LEVEL
  }
  tags = ["android-devcontainer:android-emulator"]
  platforms = ["linux/amd64"]
  cache-from = "${cache-from}"
  cache-to = "${cache-to}"
}
