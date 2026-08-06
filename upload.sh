echo "Uploading backup on rustfs..."

# rc alias set rustfs http://localhost:9000 $RUSTFS_ACCESS_KEY $RUSTFS_SECRET_KEY
# rc alias list
# rc ping rustfs
# rc ready rustfs

# rc bucket list rustfs/backup
# rc bucket create rustfs/backup

rc object copy /var/backup/postgres_backup_20260805.dump rustfs/backup
