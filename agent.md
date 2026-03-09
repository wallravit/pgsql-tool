# Agent Notes: PostgreSQL Tooling Suite

This document provides context and guidelines for AI agents and developers working on this project.

## Project Overview
A collection of robust, portable Bash scripts for managing PostgreSQL database operations including backups, restorations, migrations, and data verification.

## Tech Stack & Requirements
- **Language**: Bash (targeting version 4.x+).
- **Dependencies**: 
  - PostgreSQL Client Tools (`psql`, `pg_dump`, `pg_restore`).
  - Standard Unix utilities (`grep`, `sed`, `awk`, `comm`, `tee`).
  - **Compression**: `gzip`, `zstd` (optional).
  - **CI/Linting**: `shellcheck` (pre-installed in GitHub Actions `ubuntu-latest`).
- **Security**: Scripts assume `PGPASSWORD` is set in the environment or handled via `.pgpass` to avoid interactive prompts. **Never hardcode passwords.**

## Standard Script Architecture
When adding a new script, follow this pattern:

1.  **Header**: `#!/bin/bash` followed by `set -e` (Exit on error).
2.  **Usage Function**: Define a `usage()` function that prints help and exits.
3.  **Defaults**: Set default values for optional parameters (e.g., `HOST="localhost"`, `PORT="5432"`).
4.  **Argument Parsing**: Use `getopts` for simple flags or a `while` loop with `case` for long-form arguments.
5.  **Validation**: Check if required arguments (like `DB_NAME`, `DB_USER`) are provided.
6.  **Logging**: 
    - Wrap the main execution in a subshell `(...)` and pipe to `tee -a "$LOG_FILE"`.
    - Always capture and check `PIPESTATUS` to ensure the database command itself succeeded.
7.  **Cleanup**: Ensure temporary files (if any) are removed even on failure.
8.  **Linting**: Ensure all scripts pass `shellcheck` and `bash -n` syntax checks.

## Implementation Guidelines
- **Idempotency**: Scripts should be safe to run multiple times.
- **Verbose Output**: Use verbose flags (`-v` for `pg_dump`) to provide progress feedback.
- **Error Handling**: Use `set -e` and explicit checks for critical commands.
- **Portability**: Avoid bash-isms that are too specific to a single OS if possible, though targeting Linux/macOS is standard.
- **Coding Style**: 
    - Always quote variables to prevent word splitting (SC2086).
    - Prefer bash loops (`while read`) over `sed` for complex multi-line prefixing to satisfy `shellcheck` (SC2001).

## How to Add a New Feature
1.  **Define Scope**: Determine the specific PostgreSQL task (e.g., "Analyze table statistics", "Kill long-running queries").
2.  **Create Script**: Follow the "Standard Script Architecture".
3.  **Lint Script**: Run `shellcheck <script>.sh` locally.
4.  **Test Locally**: Verify with a local PostgreSQL instance.
5.  **Update README**: Add the new script and its usage to `README.md`.
6.  **Update Agent Notes**: Add the new script to the "Scripts" section and update "Progress".

## Current Progress
- [x] Initialized project.
- [x] Created `backup_psql.sh` for database backups.
- [x] Created `restore_psql.sh` for database restoration.
- [x] Created `migrate_psql.sh` for direct database migration.
- [x] Created `compare_psql.sh` for data verification after restore/migration.
- [x] Set up GitHub Actions CI for `shellcheck` and bash syntax validation.
- [x] Resolved all `shellcheck` linting issues across the codebase.
- [x] Add support for compressed backups (gzip/zstd).
- [x] Add schema-only export/import options.

## Active Scripts
- `backup_psql.sh`: Backs up a PostgreSQL database to a `.sql` file. Supports gzip/zstd compression and schema-only dumps.
- `restore_psql.sh`: Restores a `.sql`, `.gz`, or `.zst` file to a PostgreSQL database.
- `migrate_psql.sh`: Direct migration from one database to another using a pipe (`pg_dump | psql`).
- `compare_psql.sh`: Validates data integrity by comparing table lists and row counts between two databases.
