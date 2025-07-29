#!/bin/bash
set -e

# Signal handler for graceful shutdown
cleanup() {
    echo "Shutting down container..."
    if [ -n "${ADB_CONNECT_PID:-}" ]; then
        echo "Terminating ADB connection script (PID: $ADB_CONNECT_PID)..."
        kill -TERM "$ADB_CONNECT_PID" 2>/dev/null || true
        wait "$ADB_CONNECT_PID" 2>/dev/null || true
    fi
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

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

# Start ADB connection to emulator in background if ADB_HOST is set
if [ -n "${ADB_HOST:-}" ] || [ "${ENABLE_ADB_CONNECT:-true}" = "true" ]; then
    echo "Starting ADB connection to emulator in background..."
    echo "Target: ${ADB_HOST:-emulator}:${ADB_PORT:-5555}"
    echo "Timeout: ${ADB_CONNECT_TIMEOUT:-300} seconds"
    
    # Start the ADB connection script in background
    nohup /usr/local/bin/connect-adb.sh > /tmp/adb-connect.log 2>&1 &
    ADB_CONNECT_PID=$!
    echo "ADB connection script started with PID: $ADB_CONNECT_PID"
    echo "Logs available at: /tmp/adb-connect.log"
fi

# Execute the main command
exec "$@"
