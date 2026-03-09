# PostgreSQL Backup and Restore Tools

Simple bash scripts to backup and restore PostgreSQL databases with real-time logging and progress tracking.

## Features
- **Tail Log**: All operations are logged to a file while being displayed in real-time in the terminal.
- **Progress Tracking**: Uses verbose output to show which tables and objects are being processed.
- **Customizable Logging**: Specify your own log file path or use the default.

## 1. Backup Script (`backup_psql.sh`)

Backup a PostgreSQL database to a `.sql` file.

### Usage
```bash
./backup_psql.sh -d <db_name> -u <user> -h <host> -p <port> -f <output_file> -l <log_file>
```
- `-d`: Database name (Required)
- `-u`: Database user (Required)
- `-h`: Database host (Default: localhost)
- `-p`: Database port (Default: 5432)
- `-f`: Output file path (Default: `backup_<db_name>_<timestamp>.sql`)
- `-l`: Log file path (Default: `backup_<db_name>.log`)

### Example
```bash
export PGPASSWORD='mypassword'
./backup_psql.sh -d my_database -u postgres -f /tmp/backup.sql
```

---

## 2. Restore Script (`restore_psql.sh`)

Restore a `.sql` backup file to a target PostgreSQL database.

### Usage
```bash
./restore_psql.sh -f <input_file> -d <db_name> -u <user> -h <host> -p <port> -l <log_file>
```
- `-f`: Input file path (Required)
- `-d`: Target database name (Required)
- `-u`: Database user (Required)
- `-h`: Database host (Default: localhost)
- `-p`: Database port (Default: 5432)
- `-l`: Log file path (Default: `restore_<db_name>.log`)

---

## 3. Migration Script (`migrate_psql.sh`)

Stream a database directly from one host to another without intermediate files.

### Usage
```bash
./migrate_psql.sh --sd <src_db> --su <src_user> --sh <src_host> --td <target_db> --tu <target_user> --th <target_host> --log <log_file>
```
- `--sd`: Source Database
- `--su`: Source User
- `--sh`: Source Host
- `--td`: Target Database
- `--tu`: Target User
- `--th`: Target Host
- `--log`: Log file path (Default: `migration_<src_db>_to_<target_db>.log`)

---

## 4. Comparison Script (`compare_psql.sh`)

Compare table lists and row counts between two PostgreSQL databases to verify data integrity after a restore or migration.

### Usage
```bash
./compare_psql.sh --sd <src_db> --su <src_user> --sh <src_host> --td <target_db> --tu <target_user> --th <target_host> --log <log_file>
```
- `--sd`: Source Database
- `--su`: Source User
- `--sh`: Source Host
- `--td`: Target Database
- `--tu`: Target User
- `--th`: Target Host
- `--log`: Log file path (Default: `compare_<src_db>_to_<target_db>.log`)

### Features
- Lists tables missing in either source or target.
- Compares row counts for all common tables.
- Provides a summary of differences and a clear "RESULT: DATA MATCHES SUCCESSFULLY!" or "RESULT: DATA MISMATCH FOUND!" status.

## Authentication

For non-interactive use, you have two primary options to provide passwords. **Never hardcode passwords directly in the script files.**

### Option 1: Using `.pgpass` (Recommended)
The `.pgpass` file allows you to store passwords securely. 

1. Create a file named `.pgpass` in your home directory (or use the provided `pgpass.sample` as a template).
2. Add entries in the format: `hostname:port:database:username:password`
   - Example: `localhost:5432:*:postgres:mypassword`
3. **Crucial:** Set strict permissions on the file or PostgreSQL will ignore it:
   ```bash
   chmod 0600 ~/.pgpass
   ```
4. If the file is not in your home directory, you can point to it using the `PGPASSFILE` environment variable:
   ```bash
   export PGPASSFILE='/path/to/your/.pgpass'
   ```

### Option 2: Environment Variable
You can export the `PGPASSWORD` variable before running the scripts:
```bash
export PGPASSWORD='your_password'
./backup_psql.sh -d my_db -u my_user
```
