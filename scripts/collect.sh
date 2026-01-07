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
# ==============================================================================


LOGGER() {
    local LEVEL=$1
    local MESSAGE=$2
    local LOG_FILE=$3
    local TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [$LEVEL] $MESSAGE" >> "$LOG_FILE"
}


DATA_DIR=$1
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
FILE_TIMESTAMP=$(date "+%Y%m%d_%H%M")
MODELS=("rtx3060" "rtx3070" "rtx3080" "rtx3090" "rx6700")

# CHECKING THE DATA DIR
# Check for the data path, option for general access
if [ ! -z $DATA_DIR ]; then
    echo "The data dir set to $DATA_DIR"
else
    read -p "Please write the data dir: " DATA_DIR
fi

# Checl weather the data dir exsit
if [ ! -d "$DATA_DIR" ]; then
    echo "Fatal Error: Directory '$DATA_DIR' does not exist!"
    exit 0
fi

# Set teh log dir
BASE_DIR=$(dirname $(readlink -f "$DATA_DIR/.."))
LOG_DIR="$BASE_DIR/logs"
LOG="${LOG_DIR}/collect.logs"
mkdir -p "$LOG_DIR"

LOGGER "INFO" "NEW UPDATE REQUEST" $LOG


# CHECK THE LATEST DATA FILE
SOURCE_DATA=$(ls -t $DATA_DIR/sales_data*.csv | head -n 1)
if [ ! -f "$SOURCE_DATA" ]; then
    touch "$SOURCE_DATA"
fi
LOGGER "INFO" "The source data is set to: $SOURCE_DATA" $LOG

# Set the new output data file
OUTPUT_FILE="${DATA_DIR}/sales_data_${FILE_TIMESTAMP}.csv"

# Make sure the files are not the same
if [ $OUTPUT_FILE == $SOURCE_DATA ]; then
    echo "Trying so soon! Please try again later"
    LOGGER "WARNING" "Trying so soon! Please try again later." $LOG
    echo -e "********************\n" >> $LOG
    exit -1
fi

LOGGER "INFO" "The update data is writing into: $OUTPUT_FILE" $LOG
# Copy the latest to the new 
cp $SOURCE_DATA $OUTPUT_FILE

# Create file if it doesn't exist, ensure newline at end if file has content
if [ ! -f "$OUTPUT_FILE" ]; then
    touch "$OUTPUT_FILE"
elif [ -s "$OUTPUT_FILE" ] && [ -n "$(tail -c 1 "$OUTPUT_FILE")" ]; then
    echo "" >> "$OUTPUT_FILE"
fi


for MODEL in "${MODELS[@]}"; do

    SALES=$(curl -s "http://0.0.0.0:5000/$MODEL")

    if [ -n "$SALES" ] && [[ "$SALES" =~ ^[0-9]+$ ]]; then
        echo "$TIMESTAMP,$MODEL,$SALES" >> $OUTPUT_FILE
        LOGGER "INFO" "The queried models: $MODEL, Sales: $SALES" $LOG
    else
        LOGGER "ERROR" "Could not fetch data for >>$MODEL<<" $LOG
    fi

done

echo -e "********************\n" >> $LOG
