#!/bin/bash

set -Eeuo pipefail

ALIAS="rustfs"
BUCKET="backup"

TIMESTAMP=$(date +'%Y%m%d%H%M%S')
BACKUP_FILE="/tmp/postgres_backup_${TIMESTAMP}.dump.gpg"

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$1] $2"
}

fail() {
    log "ERROR" "$1"
    exit 1
}

cleanup_tmp() {
    if [[ -f "$BACKUP_FILE" ]]; then
        rm -f "$BACKUP_FILE"
        log "INFO" "Temporary file removed."
    fi
}
trap cleanup_tmp EXIT

initialize() {

    log "INFO" "Initializing RustFS client..."
    /usr/local/bin/rc alias set \
        "$ALIAS" \
        "http://${RUSTFS_HOST}:9000" \
        "$RUSTFS_ACCESS_KEY" \
        "$RUSTFS_SECRET_KEY" \
        || fail "RustFS alias configuration failed"

    /usr/local/bin/rc ready "$ALIAS" \
        || fail "RustFS is not ready"

    if ! /usr/local/bin/rc ls "$ALIAS/$BUCKET" >/dev/null 2>&1; then
        log "INFO" "Bucket does not exist, creating..."
        /usr/local/bin/rc bucket create "$ALIAS/$BUCKET" \
            || fail "Bucket creation failed"
    fi
    log "INFO" "Initialization completed."
}



backup() {

    log "INFO" "Starting PostgreSQL backup."
    PGPASSWORD="$POSTGRES_PASSWORD" \
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
    > "$BACKUP_FILE"

    [[ -s "$BACKUP_FILE" ]] \
        || fail "Backup file is empty"

    log "INFO" "Backup encrypted successfully."

    /usr/local/bin/rc object copy \
        "$BACKUP_FILE" \
        "$ALIAS/$BUCKET/postgres_backup_${TIMESTAMP}.dump.gpg" \
        || fail "Upload failed"

    log "INFO" "Backup uploaded successfully."
}

retention_cleanup() {
    RETENTION_SECONDS="${RETENTION_SECONDS:-600}"
    log "INFO" "Starting retention cleanup."
    log "INFO" "Retention policy: ${RETENTION_SECONDS}s"
    NOW=$(date +%s)

    /usr/local/bin/rc ls --json "$ALIAS/$BUCKET" \
    | jq -r '.items[] | "\(.key) \(.last_modified)"' \
    | while read -r OBJECT DATE; do
        OBJECT_TIME=$(date -d "$DATE" +%s)
        AGE=$((NOW - OBJECT_TIME))
        if [[ "$AGE" -ge "$RETENTION_SECONDS" ]]; then
            log "INFO" \
            "Deleting object: $OBJECT (age ${AGE}s)"
            /usr/local/bin/rc rm \
                "$ALIAS/$BUCKET/$OBJECT" \
                || log "ERROR" "Failed deleting $OBJECT"
        fi
    done
    log "INFO" "Retention cleanup completed."
}

main() {

    MODE="${1:-}"

    case "$MODE" in

        backup)
            initialize
            backup
            ;;
        cleanup)
            initialize
            retention_cleanup
            ;;
        all)
            initialize
            backup
            retention_cleanup
            ;;
        *)
            echo "Usage:"
            echo "$0 {backup|cleanup|all}"
            exit 1
            ;;

    esac

}

main "$@"