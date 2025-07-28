#!/bin/bash
set -e

# Initialize git configuration if not already set
if [ ! -f /home/vscode/.gitconfig ]; then
    git config --global user.name "vscode"
    git config --global user.email "vscode@localhost"
    git config --global init.defaultBranch main
fi

# Initialize Android SDK if needed
if [ ! -d "$ANDROID_HOME/licenses" ]; then
    echo "Initializing Android SDK licenses..."
    yes | sdkmanager --sdk_root=$ANDROID_HOME --licenses > /dev/null 2>&1 || true
fi

# Start any background services if needed
echo "Android Development Container Ready!"
echo "Java Home: $JAVA_HOME"
echo "Android Home: $ANDROID_HOME"
echo "Android NDK Home: $ANDROID_NDK_HOME"
echo "CMake Home: $CMAKE_HOME"
echo "Gradle Home: $GRADLE_HOME"

# Execute the main command
exec "$@"
