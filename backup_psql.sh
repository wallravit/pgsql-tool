#!/bin/bash

# Exit on error
set -e

# Function to display help
usage() {
    echo "Usage: $0 -d <db_name> -u <user> [-h <host>] [-p <port>] [-f <output_file>] [-l <log_file>] [-z <gzip|zstd>] [-s]"
    echo "  -d  Database name"
    echo "  -u  Database user"
    echo "  -h  Database host (default: localhost)"
    echo "  -p  Database port (default: 5432)"
    echo "  -f  Output file path"
    echo "  -l  Log file path (default: backup_\$db_name.log)"
    echo "  -z  Compress output using gzip or zstd"
    echo "  -s  Schema-only backup"
    exit 1
}

# Default values
HOST="localhost"
PORT="5432"
COMPRESS=""
SCHEMA_ONLY=false

# Parse arguments
while getopts "d:u:h:p:f:l:z:s" opt; do
    case ${opt} in
        d) DB_NAME=$OPTARG ;;
        u) DB_USER=$OPTARG ;;
        h) HOST=$OPTARG ;;
        p) PORT=$OPTARG ;;
        f) OUTPUT_FILE=$OPTARG ;;
        l) LOG_FILE=$OPTARG ;;
        z) COMPRESS=$OPTARG ;;
        s) SCHEMA_ONLY=true ;;
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
    EXTENSION="sql"
    if [[ "$COMPRESS" == "gzip" ]]; then
        EXTENSION="sql.gz"
    elif [[ "$COMPRESS" == "zstd" ]]; then
        EXTENSION="sql.zst"
    fi
    OUTPUT_FILE="backup_${DB_NAME}_$(date +%Y%m%d_%H%M%S).${EXTENSION}"
fi

# Set default log file if not provided
if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="backup_${DB_NAME}.log"
fi

# Validate compression method
if [[ -n "$COMPRESS" ]] && [[ "$COMPRESS" != "gzip" ]] && [[ "$COMPRESS" != "zstd" ]]; then
    echo "Error: Invalid compression method. Use 'gzip' or 'zstd'."
    exit 1
fi

echo "Starting backup of $DB_NAME from $HOST:$PORT..."
[[ "$SCHEMA_ONLY" == true ]] && echo "Mode: Schema-only"
[[ -n "$COMPRESS" ]] && echo "Compression: $COMPRESS"
echo "Output file: $OUTPUT_FILE"
echo "Log file: $LOG_FILE"
echo "---"

# Prepare pg_dump arguments
DUMP_ARGS=("-h" "$HOST" "-p" "$PORT" "-U" "$DB_USER" "-d" "$DB_NAME" "-v" "-F" "p")
[[ "$SCHEMA_ONLY" == true ]] && DUMP_ARGS+=("-s")

# Run pg_dump
(
    echo "--- Backup started at $(date) ---"
    
    if [[ "$COMPRESS" == "gzip" ]]; then
        pg_dump "${DUMP_ARGS[@]}" | gzip > "$OUTPUT_FILE"
    elif [[ "$COMPRESS" == "zstd" ]]; then
        pg_dump "${DUMP_ARGS[@]}" | zstd > "$OUTPUT_FILE"
    else
        pg_dump "${DUMP_ARGS[@]}" -f "$OUTPUT_FILE"
    fi
    
    DUMP_STATUS=${PIPESTATUS[0]}
    echo "--- Backup finished at $(date) with status $DUMP_STATUS ---"
    exit "$DUMP_STATUS"
) 2>&1 | tee -a "$LOG_FILE"

# Check the actual status from the subshell/pipe
if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    echo "---"
    echo "Backup completed successfully: $OUTPUT_FILE"
else
    echo "---"
    echo "Backup failed! Check log: $LOG_FILE"
    exit 1
fi
