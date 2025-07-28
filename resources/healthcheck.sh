#!/bin/bash
# Health check script for Android development container

set -e

# Check if essential tools are available
command -v java >/dev/null 2>&1 || { echo "Java not found"; exit 1; }
command -v gradle >/dev/null 2>&1 || { echo "Gradle not found"; exit 1; }
command -v cmake >/dev/null 2>&1 || { echo "CMake not found"; exit 1; }

# Check if Android SDK is properly installed
if [ ! -d "$ANDROID_HOME" ]; then
    echo "Android SDK not found"
    exit 1
fi

# Check if Android SDK tools are accessible
command -v sdkmanager >/dev/null 2>&1 || { echo "Android SDK Manager not found"; exit 1; }
command -v adb >/dev/null 2>&1 || { echo "ADB not found"; exit 1; }

# Check if NDK is available
if [ ! -d "$ANDROID_NDK_HOME" ]; then
    echo "Android NDK not found"
    exit 1
fi

echo "All health checks passed"
exit 0
