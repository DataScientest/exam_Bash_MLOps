#!/bin/bash
# =============================================================================
# This script preprocessed.sh runs the program src/preprocessed.py
# and logs the execution details in the log file
# logs/preprocessed.logs.
# =============================================================================
set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/preprocessed.logs"
PY_BIN=".venv/bin/python"
PY_SCRIPT="src/preprocessed.py"

logger() {
    # logger function
    local _LEVEL=$1
    local _MESSAGE=$2
    local _LOG_PATH=$3
    local _TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$_TIMESTAMP] | $_LEVEL | $_MESSAGE" >> "$_LOG_PATH"
}

check_environment() {
    # Ensure necessary files exist before running
    if [[ ! -f "$PY_BIN" ]]; then
        echo "Fatal Error: Virtual environment python not found at $PY_BIN" >&2
        exit 1
    fi

    if [[ ! -f "$PY_SCRIPT" ]]; then
        echo "Fatal Error: Python script not found at $PY_SCRIPT" >&2
        exit 1
    fi

    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
}

run_preprocessing() {
    logger "INFO" "Starting Preprocessing Pipeline..." "$LOG_FILE"
    
    # Execute Python script and capture exit code
    # We use '2>&1' within the command to ensure Python errors go to the log
    if "$PY_BIN" "$PY_SCRIPT" >> "$LOG_FILE" 2>&1; then
        logger "INFO" "Python preprocessing completed successfully." "$LOG_FILE"
    else
        local _RET=$?
        logger "ERROR" "Python script failed with exit code $_RET" "$LOG_FILE"
        echo -e "********************\n" >> "$LOG_FILE"
        exit $_RET
    fi
}


main() {
    check_environment

    logger "INFO" "NEW PREPROCESSING UPDATE REQUEST" "$LOG_FILE"
    
    run_preprocessing

    logger "INFO" "End of Preprocessing Task." "$LOG_FILE"
    echo -e "********************\n" >> "$LOG_FILE"
}

main "$@"
