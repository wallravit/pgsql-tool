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
    echo "  --log Log file path (default: compare_\$src_db_to_\$target_db.log)"
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
    LOG_FILE="compare_${SRC_DB}_to_${TARGET_DB}.log"
fi

echo "Comparing $SRC_DB ($SRC_HOST) and $TARGET_DB ($TARGET_HOST)..."
echo "Log file: $LOG_FILE"
echo "---"

# Helper to run psql queries
run_query() {
    local host=$1
    local port=$2
    local user=$3
    local db=$4
    local query=$5
    psql -h "$host" -p "$port" -U "$user" -d "$db" -Atc "$query"
}

(
    echo "--- Comparison started at $(date) ---"

    echo "Fetching table lists..."
    TABLE_QUERY="SELECT table_schema || '.' || table_name FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog') AND table_type = 'BASE TABLE' ORDER BY 1"
    
    SRC_TABLES=$(run_query "$SRC_HOST" "$SRC_PORT" "$SRC_USER" "$SRC_DB" "$TABLE_QUERY")
    TARGET_TABLES=$(run_query "$TARGET_HOST" "$TARGET_PORT" "$TARGET_USER" "$TARGET_DB" "$TABLE_QUERY")

    echo "--- Table Comparison ---"
    
    # Use comm to find differences (requires sorted input)
    # Tables in Source but not in Target
    MISSING_IN_TARGET=$(comm -23 <(echo "$SRC_TABLES") <(echo "$TARGET_TABLES"))
    if [[ -n "$MISSING_IN_TARGET" ]]; then
        echo "Tables in source but missing in target:"
        while IFS= read -r line; do echo "  - $line"; done <<< "$MISSING_IN_TARGET"
    fi

    # Tables in Target but not in Source
    MISSING_IN_SRC=$(comm -13 <(echo "$SRC_TABLES") <(echo "$TARGET_TABLES"))
    if [[ -n "$MISSING_IN_SRC" ]]; then
        echo "Tables in target but missing in source:"
        while IFS= read -r line; do echo "  - $line"; done <<< "$MISSING_IN_SRC"
    fi

    # Common tables
    COMMON_TABLES=$(comm -12 <(echo "$SRC_TABLES") <(echo "$TARGET_TABLES"))
    
    echo "--- Row Count Comparison ---"
    printf "%-50s | %10s | %10s | %s\n" "Table Name" "Source" "Target" "Status"
    printf "%-50s-+-%10s-+-%10s-+-%s\n" "--------------------------------------------------" "----------" "----------" "------"

    DIFF_COUNT=0
    for table in $COMMON_TABLES; do
        SRC_COUNT=$(run_query "$SRC_HOST" "$SRC_PORT" "$SRC_USER" "$SRC_DB" "SELECT count(*) FROM $table")
        TARGET_COUNT=$(run_query "$TARGET_HOST" "$TARGET_PORT" "$TARGET_USER" "$TARGET_DB" "SELECT count(*) FROM $table")
        
        STATUS="OK"
        if [[ "$SRC_COUNT" != "$TARGET_COUNT" ]]; then
            STATUS="DIFF"
            ((DIFF_COUNT++))
        fi
        
        printf "%-50s | %10s | %10s | %s\n" "$table" "$SRC_COUNT" "$TARGET_COUNT" "$STATUS"
    done

    echo "---"
    echo "Summary:"
    echo "  Total common tables checked: $(echo "$COMMON_TABLES" | wc -l | xargs)"
    echo "  Tables with differences: $DIFF_COUNT"
    
    if [[ -n "$MISSING_IN_TARGET" ]] || [[ -n "$MISSING_IN_SRC" ]] || [[ $DIFF_COUNT -gt 0 ]]; then
        echo "RESULT: DATA MISMATCH FOUND!"
        exit 1
    else
        echo "RESULT: DATA MATCHES SUCCESSFULLY!"
    fi
) | tee "$LOG_FILE"

# Capture the exit status from the subshell
EXIT_CODE=${PIPESTATUS[0]}
exit "$EXIT_CODE"
