#!/bin/bash

set -euo pipefail

TIMESTAMP=$(date +'%Y%m%d%H%M%S')
BACKUP_FILE="/tmp/postgres_backup_${TIMESTAMP}.dump.gpg"

log() {
    local LEVEL="$1"
    shift
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$LEVEL] $*"
}

fail() {
    log "ERROR" "$*"
    exit 1
}

cleanup() {
    if [[ -f "$BACKUP_FILE" ]]; then
        rm -f "$BACKUP_FILE"
        log "INFO" "Temporary backup file removed."
    fi
}

trap cleanup EXIT


# --------------------------------------------------
# Validate environment
# --------------------------------------------------

log "INFO" "Validating environment variables..."

REQUIRED_VARS=(
    RUSTFS_HOST
    RUSTFS_ACCESS_KEY
    RUSTFS_SECRET_KEY
    POSTGRES_HOST
    POSTGRES_USER
    POSTGRES_PASSWORD
    POSTGRES_DB
    GPG_PASSPHRASE
)

for VAR in "${REQUIRED_VARS[@]}"; do
    if [[ -z "${!VAR:-}" ]]; then
        fail "Missing required environment variable: $VAR"
    fi
done

log "INFO" "Environment validation completed successfully."


# --------------------------------------------------
# Initialize RustFS client
# --------------------------------------------------

log "INFO" "Configuring RustFS alias..."

if /usr/local/bin/rc alias set \
    rustfs \
    "http://${RUSTFS_HOST}:9000" \
    "$RUSTFS_ACCESS_KEY" \
    "$RUSTFS_SECRET_KEY"; then

    log "INFO" "RustFS alias configured successfully."

else
    fail "Failed to configure RustFS alias."
fi


log "INFO" "Checking RustFS availability..."

if /usr/local/bin/rc ready rustfs; then
    log "INFO" "RustFS is ready."
else
    fail "RustFS is not ready."
fi


log "INFO" "Checking backup bucket..."

if /usr/local/bin/rc ls rustfs/backup >/dev/null 2>&1; then
    # log "INFO" "Backup bucket already exists."
else
    log "INFO" "Creating backup bucket..."

    if /usr/local/bin/rc bucket create rustfs/backup; then
        log "INFO" "Backup bucket created successfully."
    else
        fail "Failed to create backup bucket."
    fi
fi


# --------------------------------------------------
# PostgreSQL backup
# --------------------------------------------------

log "INFO" "Starting PostgreSQL backup..."

if PGPASSWORD="$POSTGRES_PASSWORD" \
pg_dump \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -F c \
    -Z 9 \
| gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$GPG_PASSPHRASE" \
    --symmetric \
    --cipher-algo AES256 \
> "$BACKUP_FILE"; then

    log "INFO" "PostgreSQL dump encrypted successfully."

else
    fail "PostgreSQL backup or encryption failed."
fi


if [[ ! -s "$BACKUP_FILE" ]]; then
    fail "Encrypted backup file is empty."
fi

BACKUP_SIZE=$(du -h "$BACKUP_FILE" | awk '{print $1}')
log "INFO" "Backup file created. Size: $BACKUP_SIZE"


# --------------------------------------------------
# Upload backup
# --------------------------------------------------

log "INFO" "Uploading backup to RustFS..."

if /usr/local/bin/rc object copy \
    "$BACKUP_FILE" \
    "rustfs/backup/postgres_backup_${TIMESTAMP}.dump.gpg"; then

    log "INFO" "Backup uploaded successfully."

else
    fail "Failed to upload backup."
fi


# --------------------------------------------------
# Verify upload
# --------------------------------------------------

log "INFO" "Verifying uploaded object..."

if /usr/local/bin/rc stat \
    "rustfs/backup/postgres_backup_${TIMESTAMP}.dump.gpg" >/dev/null; then

    log "INFO" "Backup verification successful."

else
    fail "Backup verification failed."
fi


log "INFO" "PostgreSQL backup process completed successfully."