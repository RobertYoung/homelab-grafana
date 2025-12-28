#!/bin/bash

set -eo pipefail

echo "Starting Grafana backup"

TIMESTAMP_RFC3339=$(date --rfc-3339=seconds)
BACKUP_DIR=/tmp/backup-$$
ARCHIVE_FILE=/tmp/${SERVICE_NAME}-latest.tar.gz

mkdir -p "$BACKUP_DIR"
trap 'echo "Backup failed. Cleaning up..."; rm -rf "$BACKUP_DIR" "$ARCHIVE_FILE"; exit 1' ERR

# 1. Dump MySQL database
echo "Dumping MySQL database..."
if ! mysqldump -h "$MYSQL_HOST" -u "$MYSQL_USER" -p"$MYSQL_PASSWORD" \
  --single-transaction --routines --triggers --no-tablespaces \
  "$MYSQL_DATABASE" > "$BACKUP_DIR/database.sql"; then
  echo "ERROR: mysqldump failed"
  exit 1
fi

# 2. Copy Grafana config
echo "Copying Grafana config..."
cp /backup/config/grafana.ini "$BACKUP_DIR/"

# 3. Copy plugins if they exist
if [ -d "/backup/grafana-data/plugins" ] && [ "$(ls -A /backup/grafana-data/plugins 2>/dev/null)" ]; then
  echo "Copying plugins..."
  cp -r /backup/grafana-data/plugins "$BACKUP_DIR/"
fi

# 4. Create archive
echo "Creating archive..."
tar -czvf "$ARCHIVE_FILE" -C "$BACKUP_DIR" .

# 5. Upload to S3
echo "Uploading to s3://$BUCKET_NAME/$SERVICE_NAME/${SERVICE_NAME}-latest.tar.gz"
aws s3 cp "$ARCHIVE_FILE" "s3://$BUCKET_NAME/$SERVICE_NAME/${SERVICE_NAME}-latest.tar.gz"

# 6. Publish MQTT timestamp
echo "Setting time to topic backup/$SERVICE_NAME/time"
mosquitto_pub -h "$MOSQUITTO_HOST" -t "backup/$SERVICE_NAME/time" \
  -m "$TIMESTAMP_RFC3339" -u "$MOSQUITTO_USERNAME" -P "$MOSQUITTO_PASSWORD" --retain

# Cleanup
rm -rf "$BACKUP_DIR" "$ARCHIVE_FILE"
trap - ERR

echo "Finished backing up $SERVICE_NAME"
