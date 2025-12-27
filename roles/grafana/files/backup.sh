#!/bin/bash

set -e

echo "Running sync script"

TIMESTAMP_RFC3339=$(date --rfc-3339=seconds)
FILENAME=$SERVICE_NAME-latest.tar.gz
TAR_FILE=/tmp/$FILENAME

rm -rf $TAR_FILE || true

echo "Backing up $SERVICE_NAME"

cd $BACKUP_FROM

trap 'echo "Backup command failed. Cleaning up..."; rm -f "$TAR_FILE" zi*; exit 1' ERR

echo "Creating tarball $TAR_FILE"

tar -czvf $TAR_FILE --warning=none .

echo "Created $TAR_FILE"

trap - ERR

echo "Uploading to s3://$BUCKET_NAME/$SERVICE_NAME/$FILENAME"

aws s3 cp $TAR_FILE s3://$BUCKET_NAME/$SERVICE_NAME/$FILENAME

echo "Backed up $SERVICE_NAME to s3://$BUCKET_NAME/$SERVICE_NAME/$FILENAME"

echo "Setting time to topic "backup/$SERVICE_NAME/time""

mosquitto_pub -h $MOSQUITTO_HOST -t "backup/$SERVICE_NAME/time" -m "$TIMESTAMP_RFC3339" -u "$MOSQUITTO_USERNAME" -P "$MOSQUITTO_PASSWORD" --retain

echo "Finished backing up $SERVICE_NAME"
