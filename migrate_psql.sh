#!/bin/bash

# Exit on error
set -e

# Function to display help
usage() {
    echo "Usage: $0 --sd <src_db> --su <src_user> [--sh <src_host>] [--sp <src_port>] --td <target_db> --tu <target_user> [--th <target_host>] [--tp <target_port>] [--log <log_file>]"
    echo ""
    echo "Source (from):"
    echo "  --sd  Source Database name"
    echo "  --su  Source User"
    echo "  --sh  Source Host (default: localhost)"
    echo "  --sp  Source Port (default: 5432)"
    echo ""
    echo "Target (to):"
    echo "  --td  Target Database name"
    echo "  --tu  Target User"
    echo "  --th  Target Host (default: localhost)"
    echo "  --tp  Target Port (default: 5432)"
    echo ""
    echo "General:"
    echo "  --log Log file path (default: migration_\$src_db_to_\$target_db.log)"
    exit 1
}

# Default values
SRC_HOST="localhost"
SRC_PORT="5432"
TARGET_HOST="localhost"
TARGET_PORT="5432"

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --sd) SRC_DB="$2"; shift ;;
        --su) SRC_USER="$2"; shift ;;
        --sh) SRC_HOST="$2"; shift ;;
        --sp) SRC_PORT="$2"; shift ;;
        --td) TARGET_DB="$2"; shift ;;
        --tu) TARGET_USER="$2"; shift ;;
        --th) TARGET_HOST="$2"; shift ;;
        --tp) TARGET_PORT="$2"; shift ;;
        --log) LOG_FILE="$2"; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# Check required arguments
if [[ -z "$SRC_DB" ]] || [[ -z "$SRC_USER" ]] || [[ -z "$TARGET_DB" ]] || [[ -z "$TARGET_USER" ]]; then
    echo "Error: Source and Target database name and user are required."
    usage
fi

# Set default log file if not provided
if [[ -z "$LOG_FILE" ]]; then
    LOG_FILE="migration_${SRC_DB}_to_${TARGET_DB}.log"
fi

echo "Starting migration from $SRC_DB ($SRC_HOST) to $TARGET_DB ($TARGET_HOST)..."
echo "Log file: $LOG_FILE"
echo "---"

# Note: For non-interactive use, export PGPASSWORD or use ~/.pgpass
(
    echo "--- Migration started at $(date) ---"
    pg_dump -h "$SRC_HOST" -p "$SRC_PORT" -U "$SRC_USER" -d "$SRC_DB" -v -F p | \
    psql -h "$TARGET_HOST" -p "$TARGET_PORT" -U "$TARGET_USER" -d "$TARGET_DB"
    STATUS=$?
    echo "--- Migration finished at $(date) with status $STATUS ---"
    exit $STATUS
) | tee -a "$LOG_FILE"

if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
    echo "---"
    echo "Migration completed successfully."
else
    echo "---"
    echo "Migration failed! Check log: $LOG_FILE"
    exit 1
fi
