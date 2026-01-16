#!/bin/bash
# ==============================================================================
# Script: collect.sh
# Description:
#   This script queries an API to retrieve sales data for the following graphics card models:
#     - rtx3060
#     - rtx3070
#     - rtx3080
#     - rtx3090
#     - rx6700
#
#   The collected data is appended to a copy of the file:
#     data/raw/sales_data.csv
#
#   The output file is saved in the format:
#     data/raw/sales_YYYYMMDD_HHMM.csv
#   with the following columns:
#     timestamp, model, sales
#
#   Collection activity (requests, queried models, results, errors)
#   is recorded in a log file:
#     logs/collect.logs
#
#   The log should be human-readable and must include:
#     - The date and time of each request
#     - The queried models
#     - The retrieved sales data
#     - Any possible errors
# **********************************************************
# If running ./api failed, run this:
#       sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
# **********************************************************
# ==============================================================================

set -euo pipefail

# Constants of the scripts
MODELS=("rtx3060" "rtx3070" "rtx3080" "rtx3090" "rx6700")
API_BASE="http://0.0.0.0:5000"

# Setting dates
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
FILE_TIMESTAMP=$(date "+%Y%m%d_%H%M")

logger() {
    # logger function
    local _LEVEL=$1
    local _MESSAGE=$2
    local _LOG_FILE=$3
    local _TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$_TIMESTAMP] | $_LEVEL | $_MESSAGE" >> "$_LOG_FILE"
}

get_raw_dir() {
    # Helper for checking the data directory
    local _RAW_DIR="${1-}"

    if [[ -n "$_RAW_DIR" ]]; then
        echo "The data dir is set to: $_RAW_DIR" >&2
    else
        read -r -p "Please write the data dir:" _RAW_DIR
    fi

    printf "%s" "$_RAW_DIR"
}

check_raw_dir() {
    # Check the data directory
    local _RAW_DIR="$1"

    if [[ ! -d "$_RAW_DIR" ]]; then
        # CANNOT LOG THIS!
        echo "Fatal Error: Directory '$_RAW_DIR' does not exist!" >&2
        exit 1
    fi
}

set_log_file() {
    # Helper to setting the log directory and the log file
    local _SOURCE="$1"
    local _BASE_DIR _LOG_DIR _LOG_FILE

    _BASE_DIR="$(dirname "$(readlink -f "$_SOURCE/..")")"
    _LOG_DIR="$_BASE_DIR/logs"
    _LOG_FILE="${_LOG_DIR}/collect.logs"

    mkdir -p "$_LOG_DIR"
    touch "$_LOG_FILE"

    echo "Log file is: $_LOG_FILE" >&2

    printf "%s" "$_LOG_FILE"
}

manage_csv_file() {
    # Find the most recent sales_data*.csv file; and create a new one.
    local _RAW_DIR="$1"
    local _LATEST _OUT_CSV

    # Sanity consideration for output pattern
    shopt -s nullglob
    # Get the last file (ordered by date)
    _LATEST="$(ls -1t "${_RAW_DIR}"/sales_data*.csv 2>/dev/null | head -n1 || true)"
    shopt -u nullglob

    _OUT_CSV="${_RAW_DIR}/sales_data_${FILE_TIMESTAMP}.csv"

    if [[ "$(basename $_LATEST)" == "$(basename $_OUT_CSV)" ]]; then
        local _MSG="The Trying so soon! Please try again later!"
        echo "$_MSG" >&2
        logger "WARNING" "$_MSG" $LOG
        echo -e "********************\n" >> $LOG
        exit 1
    fi
    
    cp "$_LATEST" "$_OUT_CSV"

    check_out_csv "$_OUT_CSV"

    logger "INFO" "The latest csv file is: $(basename $_LATEST)" $LOG

    printf "%s" "$_OUT_CSV"
}

check_out_csv() {
    # Create file if it doesn't exist, ensure newline at end if file has content
    local _OUT_CSV="$1"

    if [ ! -f "$_OUT_CSV" ]; then
        touch "$_OUT_CSV"
    elif [ -s "$_OUT_CSV" ] && [ -n "$(tail -c 1 "$_OUT_CSV")" ]; then
        echo "" >> "$_OUT_CSV"
    fi
}

fetch_sales() {
  # Get the Endpoint
  local _MODEL="$1"
  local _URL="${API_BASE}/${_MODEL}"
  local _RESP

  if ! _RESP="$(curl --silent --show-error --fail --max-time 5 "$_URL")"; then
    logger "ERROR" "API Request (${_URL})" $LOG
    echo ""
    return 1
  fi

  _RESP="$(echo "$_RESP" | tr -d '\r\n[:space:]')"
  if [[ ! "$_RESP" =~ ^[0-9]+$ ]]; then
    logger "ERROR" "Invalid response for  ${_MODEL} : '${_RESP}' (integer expected)" $LOG
    echo ""
    return 1
  fi
  
  echo "$_RESP"
}

append_batch() {
  local _OUT_CSV="$1"
  local _MODEL
  local _N_LINE _N_COL

  logger "INFO" "Collecting Data..." $LOG
  logger "INFO" "Writing into file (append) : ${_OUT_CSV}" $LOG
  logger "INFO" "Timestamp (UTC) : ${TIMESTAMP}" $LOG
  logger "INFO" "Models: ${MODELS[*]}" $LOG

  for _MODEL in "${MODELS[@]}"; do
    _SALES="$(fetch_sales "$_MODEL" || true)"
    if [[ -z "$_SALES" ]]; then
      _SALES=0
      logger "Warning" " | ${_MODEL} -> fall back to 0 (Failed API)" $LOG
    fi
    echo "${TIMESTAMP},${_MODEL},${_SALES}" >> "$_OUT_CSV"
    logger "INFO" "Result | ${_MODEL} -> ${_SALES}" $LOG
  done

  _N_LINE="$(wc -l < "$_OUT_CSV" | tr -d ' ')"
  _N_COL="$(head -n1 "$_OUT_CSV" | awk -F',' '{print NF}')"
  logger "INFO" "File summary: ${_OUT_CSV} | lines=${_N_LINE} columns=${_N_COL}" $LOG
  logger "INFO" "End of Collections." $LOG
}


main() {
    RAW_DIR="$(get_raw_dir ${1-})"
    check_raw_dir "$RAW_DIR"

    LOG="$(set_log_file "$RAW_DIR")"

    logger "INFO" "NEW UPDATE REQUEST" $LOG
    OUT_CSV="$(manage_csv_file "$RAW_DIR")"

    append_batch $OUT_CSV

    echo -e "********************\n" >> $LOG
}

main "$@"
