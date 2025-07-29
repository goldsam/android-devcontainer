#!/bin/bash

# connect-adb.sh - Connect to Android emulator on host

set -e

# Configuration with defaults
ADB_HOST="${ADB_HOST:-emulator}"
ADB_PORT="${ADB_PORT:-5555}"
ADB_CONNECT_TIMEOUT="${ADB_CONNECT_TIMEOUT:-300}"  # 5 minutes in seconds
RETRY_INTERVAL="${RETRY_INTERVAL:-5}"              # 5 seconds between retries

# Simple logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Main connection logic
main() {
    local start_time=$(date +%s)
    local end_time=$((start_time + ADB_CONNECT_TIMEOUT))
    local attempt=1
    
    log "Connecting to ADB at ${ADB_HOST}:${ADB_PORT}"
    
    while true; do
        local current_time=$(date +%s)
        
        # Check timeout
        if [ "$current_time" -ge "$end_time" ]; then
            log "Timeout reached after ${ADB_CONNECT_TIMEOUT} seconds"
            exit 1
        fi
        
        log "Attempt #${attempt} - ${ADB_HOST}:${ADB_PORT}"
        
        # Try ADB connection
        if adb connect "${ADB_HOST}:${ADB_PORT}" >/dev/null 2>&1; then
            if adb devices | grep -q "${ADB_HOST}:${ADB_PORT}"; then
                log "Connected successfully"
                break
            fi
        fi
        
        sleep "$RETRY_INTERVAL"
        attempt=$((attempt + 1))
    done
    
    log "ADB connection established"
}

# Signal handler
trap 'log "Shutting down"; exit 0' SIGTERM SIGINT

main "$@"
