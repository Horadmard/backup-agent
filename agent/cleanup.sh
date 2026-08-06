#!/bin/bash

set -Eeuo pipefail

ALIAS="rustfs"
BUCKET="backup"

NOW=$(date +%s)

/usr/local/bin/rc ls --json "${ALIAS}/${BUCKET}" | \
jq -r '.items[] | "\(.key) \(.last_modified)"' | \
while read -r OBJECT DATE; do

    OBJECT_TIME=$(date -d "$DATE" +%s)
    AGE=$((NOW - OBJECT_TIME))

    echo "$NOW - $OBJECT_TIME = $AGE"

    if [ "$AGE" -ge 600 ]; then
        echo "Deleting old object: $OBJECT (age ${AGE}s)"
        /usr/local/bin/rc rm "${ALIAS}/${BUCKET}/${OBJECT}"
    fi

done

