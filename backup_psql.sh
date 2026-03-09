#!/bin/bash

# Exit on error
set -e

# Function to display help
usage() {
    echo "Usage: $0 -d <db_name> -u <user> -h <host> -p <port> -f <output_file> -l <log_file>"
    echo "  -d  Database name"
    echo "  -u  Database user"
    echo "  -h  Database host (default: localhost)"
    echo "  -p  Database port (default: 5432)"
    echo "  -f  Output file path (default: backup_\$db_name_\$(date +%Y%m%d_%H%M%S).sql)"
    echo "  -l  Log file path (default: backup_\$db_name.log)"
    exit 1
}

# Default values
HOST="localhost"
PORT="5432"

# Parse arguments
while getopts "d:u:h:p:f:l:" opt; do
    case ${opt} in
        d) DB_NAME=$OPTARG ;;
        u) DB_USER=$OPTARG ;;
        h) HOST=$OPTARG ;;
        p) PORT=$OPTARG ;;
        f) OUTPUT_FILE=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        *) usage ;;
    esac
done

# Check required arguments
if [[ -z "$DB_NAME" ]] || [[ -z "$DB_USER" ]]; then
    echo "Error: Database name and user are required."
    usage
fi

# Set default output file if not provided
if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S).sql"
fi

# Set default log file if not provided
if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="backup_${DB_NAME}.log"
fi

echo "Starting backup of $DB_NAME from $HOST:$PORT..."
echo "Output file: $OUTPUT_FILE"
echo "Log file: $LOG_FILE"
echo "---"

# Run pg_dump with verbose output for progress
# Note: PGPASSWORD environment variable should be set externally for non-interactive use
(
    echo "--- Backup started at $(date) ---"
    pg_dump -h "$HOST" -p "$PORT" -U "$DB_USER" -d "$DB_NAME" -v -F p -f "$OUTPUT_FILE" 2>&1
    STATUS=$?
    echo "--- Backup finished at $(date) with status $STATUS ---"
    exit $STATUS
) | tee -a "$LOG_FILE"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    echo "---"
    echo "Backup completed successfully: $OUTPUT_FILE"
else
    echo "---"
    echo "Backup failed! Check log: $LOG_FILE"
    exit 1
fi
