#!/bin/bash

# Exit on error
set -e

# Function to display help
usage() {
    echo "Usage: $0 -f <input_file> -d <db_name> -u <user> -h <host> -p <port> -l <log_file>"
    echo "  -f  Input file path (e.g., .sql file)"
    echo "  -d  Target database name"
    echo "  -u  Database user"
    echo "  -h  Database host (default: localhost)"
    echo "  -p  Database port (default: 5432)"
    echo "  -l  Log file path (default: restore_\$db_name.log)"
    exit 1
}

# Default values
HOST="localhost"
PORT="5432"

# Parse arguments
while getopts "f:d:u:h:p:l:" opt; do
    case ${opt} in
        f) INPUT_FILE=$OPTARG ;;
        d) DB_NAME=$OPTARG ;;
        u) DB_USER=$OPTARG ;;
        h) HOST=$OPTARG ;;
        p) PORT=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        *) usage ;;
    esac
done

# Check required arguments
if [[ -z "$INPUT_FILE" ]] || [[ -z "$DB_NAME" ]] || [[ -z "$DB_USER" ]]; then
    echo "Error: Input file, database name, and user are required."
    usage
fi

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File $INPUT_FILE not found."
    exit 1
fi

# Set default log file if not provided
if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="restore_${DB_NAME}.log"
fi

echo "Starting restore of $INPUT_FILE to $DB_NAME on $HOST:$PORT..."
echo "Log file: $LOG_FILE"
echo "---"

# Run psql with echo-all for progress
# Note: PGPASSWORD environment variable should be set externally for non-interactive use
(
    echo "--- Restore started at $(date) ---"
    # --echo-all shows every command being executed, providing progress
    psql -h "$HOST" -p "$PORT" -U "$DB_USER" -d "$DB_NAME" -f "$INPUT_FILE" --echo-all 2>&1
    STATUS=$?
    echo "--- Restore finished at $(date) with status $STATUS ---"
    exit $STATUS
) | tee -a "$LOG_FILE"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    echo "---"
    echo "Restore completed successfully."
else
    echo "---"
    echo "Restore failed! Check log: $LOG_FILE"
    exit 1
fi
