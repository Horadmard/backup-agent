#!/bin/bash

TIMESTAMP=$(date +'%Y%m%d%H%M%S')
COMPOSE="docker compose -p container"

echo "Backing up PostgreSQL..."

$COMPOSE exec -T -e TIMESTAMP="$TIMESTAMP" postgres sh -c '
PGPASSWORD="$POSTGRES_PASSWORD" \
pg_dump \
    -h "$POSTGRES_HOST" \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -F c \
    -Z 9 \
    -f "/tmp/postgres_backup_$TIMESTAMP.dump"
'

echo "INFO-$TIMESTAMP: Backup completed."

gpg \
    --batch \
    --yes \
    --pinentry-mode loopback \
    --passphrase "$GPG_PASSPHRASE" \
    --symmetric \
    --cipher-algo AES256 \
    --output "/var/backup/postgres_backup_${TIMESTAMP}.dump.gpg" \
    "/var/backup/postgres_backup_${TIMESTAMP}.dump"

rm -f /var/backup/postgres_backup_${TIMESTAMP}.dump

/usr/local/bin/rc object copy /var/backup/postgres_backup_${TIMESTAMP}.dump.gpg rustfs/backup
rm -f /var/backup/postgres_backup_${TIMESTAMP}.dump.gpg

echo "INFO-$TIMESTAMP: Encrypted Backup uploaded into rustfs."
