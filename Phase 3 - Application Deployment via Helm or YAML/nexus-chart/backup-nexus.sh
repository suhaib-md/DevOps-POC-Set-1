#!/bin/bash
NAMESPACE="nexus"
PVC_NAME="nexus-release-nexus-chart-pvc"
BACKUP_DIR="/tmp/nexus-backup-$(date +%Y%m%d-%H%M%S)"

mkdir -p $BACKUP_DIR
kubectl exec -n $NAMESPACE deployment/nexus-release-nexus-chart -- \
  tar czf - /nexus-data | tar xzf - -C $BACKUP_DIR

echo "Backup completed: $BACKUP_DIR"
