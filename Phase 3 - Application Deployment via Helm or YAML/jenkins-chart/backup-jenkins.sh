#!/bin/bash
NAMESPACE="jenkins"
PVC_NAME="jenkins-release-jenkins-chart-pvc"
BACKUP_DIR="/tmp/jenkins-backup-$(date +%Y%m%d-%H%M%S)"

kubectl exec -n $NAMESPACE deployment/jenkins-release-jenkins-chart -- tar czf - /var/jenkins_home | tar xzf - -C $BACKUP_DIR
echo "Backup completed: $BACKUP_DIR"
