#!/bin/sh

echo "deploy hook executed for domain: $RENEWED_LINEAGE"

docker restart grafana

echo "deploy hook completed for domain: $RENEWED_LINEAGE"