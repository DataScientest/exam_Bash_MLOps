#!/bin/bash
# -----------------------------------------------------------------------------
# This script train.sh runs the Python program src/train.py.
# This program trains a prediction model and saves the final model
# in the model/ directory. The script also logs all execution details
# in the file logs/train.logs.
# -----------------------------------------------------------------------------

set -euo pipefail

cd "$(dirname "$0")/.." || exit 1

LOG_DIR="logs"
LOG_FILE="$LOG_DIR/train.logs"
PY_BIN=".venv/bin/python"
PY_SCRIPT="src/train.py"


logger() {
    # Custom logger matching your specific style
    local _LEVEL=$1
    local _MESSAGE=$2
    local _LOG_PATH=$3
    local _TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$_TIMESTAMP] | $_LEVEL | $_MESSAGE" >> "$_LOG_PATH"
}

check_env() {
    # chck environment and script existence
    if [[ ! -f "$PY_BIN" ]]; then
        echo "Fatal Error: Python binary not found at $PY_BIN" >&2
        exit 1
    fi

    if [[ ! -f "$PY_SCRIPT" ]]; then
        echo "Fatal Error: Training script not found at $PY_SCRIPT" >&2
        exit 1
    fi

    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
}

run_training() {
    logger "INFO" "Initializing Model Training ..." "$LOG_FILE"
    
    # Run Python training and get exist status immediately
    if "$PY_BIN" "$PY_SCRIPT" >> "$LOG_FILE" 2>&1; then
        logger "INFO" "Model training completed and saved to model/ directory." "$LOG_FILE"
    else
        local _RET=$?
        logger "ERROR" "Training process failed with exit code $_RET" "$LOG_FILE"
        echo -e "********************\n" >> "$LOG_FILE"
        exit $_RET
    fi
}

main() {
    check_env

    logger "INFO" "NEW TRAINING REQUEST" "$LOG_FILE"
    
    run_training

    logger "INFO" "End of Training Task." "$LOG_FILE"
    echo -e "********************\n" >> "$LOG_FILE"
}

main "$@"
