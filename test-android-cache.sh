#!/bin/bash
# Test script to verify Android SDK caching

set -e

echo "=== Testing Android SDK Cache Verification ==="
echo

# Build just the android-sdk component with verbose output
echo "1. Building Android SDK component with cache debugging..."
docker buildx bake --progress=plain android-sdk 2>&1 | tee /tmp/android-build.log

echo
echo "2. Checking build log for cache activity..."
if grep -q "Using cached" /tmp/android-build.log; then
    echo "✓ Cache usage detected in build"
    grep "Using cached\|Downloading\|cp -r" /tmp/android-build.log | head -10
else
    echo "ℹ No cache usage detected (expected on first run)"
fi

echo
echo "3. Verifying Android SDK installation in built image..."
if docker run --rm android-devcontainer:android-sdk sdkmanager --list 2>/dev/null | head -5; then
    echo "✓ Android SDK is functional"
else
    echo "✗ Android SDK not working"
fi

echo
echo "4. Building again to test cache effectiveness..."
echo "Building android-sdk again..."
time docker buildx bake android-sdk 2>&1 | tee /tmp/android-build-2.log

echo
echo "5. Comparing build times and cache hits..."
echo "First build log excerpt:"
tail -10 /tmp/android-build.log
echo
echo "Second build log excerpt:"
tail -10 /tmp/android-build-2.log

echo
echo "Cache verification complete. Check logs above for cache mount activity."
