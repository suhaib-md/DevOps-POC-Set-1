# Nexus Repository Manager Helm Chart

A comprehensive Helm chart for deploying Sonatype Nexus Repository Manager in Kubernetes with enterprise-grade configurations, security, and scalability features.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Chart Structure](#chart-structure)
- [Installation](#installation)
- [Configuration](#configuration)
- [Upgrade](#upgrade)
- [Security](#security)
- [Monitoring & Troubleshooting](#monitoring--troubleshooting)
- [Backup & Recovery](#backup--recovery)
- [Integration](#integration)
- [Production Considerations](#production-considerations)
- [Cleanup](#cleanup)
- [Contributing](#contributing)

## Overview

This Helm chart deploys Nexus Repository Manager 3.68.1 with the following features:

- **Secure Configuration**: Latest stable version with security patches
- **Persistent Storage**: Configurable PVC with dynamic provisioning
- **RBAC**: Proper service account and role-based access control
- **Ingress**: NGINX ingress with TLS termination
- **External Database**: Optional PostgreSQL integration
- **Resource Management**: Configurable CPU/memory limits and requests
- **High Availability**: Support for external blob storage and database clustering
- **DevOps Integration**: Jenkins and CI/CD pipeline ready

### Key Components

- **Nexus Repository Manager**: Central artifact repository
- **Persistent Volume**: For artifact storage and configuration
- **ConfigMap**: Runtime configuration and properties
- **Secret**: Secure credential management
- **Service Account**: Kubernetes RBAC integration
- **Ingress**: External access with TLS

## Prerequisites

### Software Requirements

- Kubernetes cluster (v1.19+)
- Helm 3.8+
- kubectl configured for your cluster
- NGINX Ingress Controller (for ingress)

### Resource Requirements

**Minimum:**
- CPU: 1 core
- Memory: 2GB
- Storage: 20GB

**Recommended (Production):**
- CPU: 2-4 cores
- Memory: 4-8GB
- Storage: 100GB+

### Cluster Permissions

Ensure your cluster has the following capabilities:
- PersistentVolume provisioning
- LoadBalancer services (if using external access)
- Ingress controller deployed

## Chart Structure

```
nexus-chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── templates/
│   ├── configmap.yaml        # Nexus configuration
│   ├── deployment.yaml       # Main deployment
│   ├── ingress.yaml         # External access
│   ├── pvc.yaml             # Persistent storage
│   ├── rbac.yaml            # Role-based access
│   ├── secret.yaml          # Secure credentials
│   ├── service.yaml         # Service definition
│   └── serviceaccount.yaml  # Service account
├── README.md                # This file
└── .helmignore             # Helm ignore patterns
```

## Installation

### Quick Start

1. **Clone the repository:**
```bash
git clone <repository-url>
cd devops-helm-charts/nexus-chart
```

2. **Create TLS certificate:**
```bash
# Generate self-signed certificate for development
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout nexus-tls.key \
  -out nexus-tls.crt \
  -subj "/CN=nexus.local/O=nexus.local"

# Create TLS secret in Kubernetes
kubectl create secret tls nexus-tls \
  --key nexus-tls.key \
  --cert nexus-tls.crt
```

3. **Deploy Nexus:**
```bash
# Validate chart
helm lint .

# Dry run (optional)
helm install nexus-release . --dry-run --debug

# Install with default values
helm install nexus-release . --namespace nexus --create-namespace

# Or install with custom values
helm install nexus-release . \
  --namespace nexus \
  --create-namespace \
  --values custom-values.yaml
```

### Verification

```bash
# Check deployment status
kubectl get pods -n nexus
kubectl get services -n nexus
kubectl get ingress -n nexus

# Check logs
kubectl logs -n nexus deployment/nexus-release-nexus-chart

# Get admin password
kubectl exec -n nexus deployment/nexus-release-nexus-chart -- \
  cat /nexus-data/admin.password
```

### Access Nexus

1. **Via Ingress (Recommended):**
```bash
# Add to /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
echo "127.0.0.1 nexus.local" | sudo tee -a /etc/hosts

# Access via browser
https://nexus.local
```

2. **Via Port Forward (Development):**
```bash
kubectl port-forward -n nexus svc/nexus-release-nexus-chart-service 8081:8081
# Access at http://localhost:8081
```

## Configuration

### Basic Configuration

The chart uses `values.yaml` for configuration. Key sections include:

#### Nexus Image Configuration
```yaml
nexus:
  image:
    repository: sonatype/nexus3
    tag: "3.68.1"
    pullPolicy: IfNotPresent
  contextPath: "/"
```

#### Resource Configuration
```yaml
nexus:
  resources:
    requests:
      memory: "2Gi"
      cpu: "1000m"
    limits:
      memory: "4Gi"
      cpu: "2000m"
```

#### Storage Configuration
```yaml
nexus:
  persistence:
    enabled: true
    storageClass: "standard"
    size: "20Gi"
    accessMode: ReadWriteOnce
```

#### Security Configuration
```yaml
nexus:
  securityContext:
    runAsUser: 997
    runAsGroup: 997
    fsGroup: 997
  admin:
    username: "admin"
    randomPassword: true
```

### Advanced Configuration

#### External Database
```yaml
database:
  external:
    enabled: true
    host: "postgres.example.com"
    port: 5432
    name: "nexus"
    username: "nexus"
    password: "your-secure-password"
```

#### Custom Ingress
```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "0"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
  hosts:
    - host: nexus.example.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: nexus-tls
      hosts:
        - nexus.example.com
```

### Environment Variables

Configure Nexus runtime behavior:

```yaml
nexus:
  env:
    - name: NEXUS_SECURITY_RANDOMPASSWORD
      value: "true"
    - name: NEXUS_JVM_HEAP_MIN
      value: "1024m"
    - name: NEXUS_JVM_HEAP_MAX
      value: "2048m"
    - name: NEXUS_CONTEXT_PATH
      value: "/"
```

## Upgrade

### Helm Upgrade Process

1. **Update configuration:**
```bash
# Edit values.yaml or create new values file
vim values.yaml
```

2. **Perform upgrade:**
```bash
# Upgrade with current values
helm upgrade nexus-release . --namespace nexus

# Upgrade with new values file
helm upgrade nexus-release . \
  --namespace nexus \
  --values production-values.yaml

# Upgrade with specific values
helm upgrade nexus-release . \
  --namespace nexus \
  --set nexus.image.tag=3.69.0
```

3. **Verify upgrade:**
```bash
# Check upgrade status
helm status nexus-release -n nexus

# Check upgrade history
helm history nexus-release -n nexus

# Check pod status
kubectl get pods -n nexus
```

### Rollback (if needed)

```bash
# List release history
helm history nexus-release -n nexus

# Rollback to previous version
helm rollback nexus-release -n nexus

# Rollback to specific revision
helm rollback nexus-release 2 -n nexus
```

## Security

### Initial Setup

1. **Access Nexus UI:**
   - URL: `https://nexus.local` (or your configured domain)
   - Username: `admin`
   - Password: Retrieved from `/nexus-data/admin.password`

2. **Change Default Password:**
```bash
# Get initial password
kubectl exec -n nexus deployment/nexus-release-nexus-chart -- \
  cat /nexus-data/admin.password
```

3. **Security Configuration:**
   - Enable anonymous access controls
   - Configure LDAP/Active Directory integration
   - Set up user roles and permissions
   - Enable audit logging

### RBAC Configuration

The chart includes comprehensive RBAC:

```yaml
rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["secrets", "configmaps"]
      verbs: ["get", "list", "watch"]
    - apiGroups: [""]
      resources: ["persistentvolumeclaims"]
      verbs: ["get", "list", "watch", "create", "update", "patch"]
```

### TLS Configuration

For production, use proper TLS certificates:

```bash
# Using cert-manager (recommended)
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: nexus-tls
  namespace: nexus
spec:
  secretName: nexus-tls
  issuerRef:
    name: letsencrypt-prod
    kind: ClusterIssuer
  dnsNames:
  - nexus.example.com
EOF
```

## Monitoring & Troubleshooting

### Health Checks

The deployment includes comprehensive health checks:

```yaml
livenessProbe:
  httpGet:
    path: /service/rest/v1/status
    port: http
  initialDelaySeconds: 300
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 6

readinessProbe:
  httpGet:
    path: /service/rest/v1/status
    port: http
  initialDelaySeconds: 180
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 3
```

### Monitoring Commands

```bash
# Monitor resource usage
kubectl top pods -n nexus

# Check pod details
kubectl describe pod -n nexus <pod-name>

# View logs
kubectl logs -n nexus deployment/nexus-release-nexus-chart -f

# Check events
kubectl get events -n nexus --sort-by=.metadata.creationTimestamp

# Debug container
kubectl exec -it -n nexus deployment/nexus-release-nexus-chart -- /bin/bash
```

### Common Issues

1. **Pod Not Starting:**
   - Check resource limits
   - Verify storage class availability
   - Review security context settings

2. **Ingress Not Working:**
   - Verify ingress controller is running
   - Check TLS certificate validity
   - Validate DNS resolution

3. **Database Connection Issues:**
   - Verify external database connectivity
   - Check database credentials
   - Review network policies

## Backup & Recovery

### Automated Backup Script

```bash
#!/bin/bash
# backup-nexus.sh
NAMESPACE="nexus"
PVC_NAME="nexus-release-nexus-chart-pvc"
BACKUP_DIR="/tmp/nexus-backup-$(date +%Y%m%d-%H%M%S)"

mkdir -p $BACKUP_DIR

# Create backup
kubectl exec -n $NAMESPACE deployment/nexus-release-nexus-chart -- \
  tar czf - /nexus-data | tar xzf - -C $BACKUP_DIR

echo "Backup completed: $BACKUP_DIR"
```

### Restore Process

```bash
#!/bin/bash
# restore-nexus.sh
NAMESPACE="nexus"
BACKUP_DIR="$1"

if [ -z "$BACKUP_DIR" ]; then
  echo "Usage: $0 <backup-directory>"
  exit 1
fi

# Scale down deployment
kubectl scale deployment -n $NAMESPACE nexus-release-nexus-chart --replicas=0

# Restore data
tar czf - -C $BACKUP_DIR nexus-data | \
  kubectl exec -i -n $NAMESPACE deployment/nexus-release-nexus-chart -- \
  tar xzf - -C /

# Scale up deployment
kubectl scale deployment -n $NAMESPACE nexus-release-nexus-chart --replicas=1
```

### Persistent Volume Snapshots

If your storage class supports snapshots:

```bash
# Create volume snapshot
kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: nexus-snapshot-$(date +%Y%m%d)
  namespace: nexus
spec:
  volumeSnapshotClassName: csi-hostpath-snapclass
  source:
    persistentVolumeClaimName: nexus-release-nexus-chart-pvc
EOF
```

## Integration

### Jenkins Integration

Update Jenkins Helm chart to use Nexus:

```yaml
# jenkins-values.yaml
jenkins:
  controller:
    jcasc:
      configScripts:
        nexus-config: |
          unclassified:
            globalNexusConfiguration:
              nxrmConfigs:
                - nxrmUrl: "http://nexus-release-nexus-chart-service.nexus.svc.cluster.local:8081"
                  credentialsId: "nexus-credentials"
```

### Maven Configuration

```xml
<!-- settings.xml -->
<settings>
  <servers>
    <server>
      <id>nexus</id>
      <username>admin</username>
      <password>your-password</password>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>nexus</id>
      <mirrorOf>*</mirrorOf>
      <url>https://nexus.local/repository/maven-public/</url>
    </mirror>
  </mirrors>
</settings>
```

### Docker Registry

Configure Docker to use Nexus registry:

```bash
# Login to Nexus Docker registry
docker login nexus.local:8082

# Tag and push image
docker tag myapp:latest nexus.local:8082/myapp:latest
docker push nexus.local:8082/myapp:latest
```

## Production Considerations

### High Availability Setup

```yaml
# Production values
nexus:
  resources:
    requests:
      memory: "4Gi"
      cpu: "2000m"
    limits:
      memory: "8Gi"
      cpu: "4000m"
  
  persistence:
    size: "500Gi"
    storageClass: "ssd"

database:
  external:
    enabled: true
    host: "postgres-ha.example.com"
    port: 5432
    name: "nexus"
    username: "nexus"
    password: "secure-password"

# External blob storage (S3)
nexus:
  env:
    - name: NEXUS_BLOB_STORE_TYPE
      value: "s3"
    - name: AWS_ACCESS_KEY_ID
      value: "your-access-key"
    - name: AWS_SECRET_ACCESS_KEY
      value: "your-secret-key"
    - name: S3_BUCKET_NAME
      value: "nexus-blobs"
```

### Scaling Considerations

1. **Vertical Scaling**: Increase CPU/memory resources
2. **Storage Scaling**: Use high-performance storage classes
3. **Network**: Configure appropriate bandwidth limits
4. **Database**: Use external managed databases for better performance

### Security Hardening

1. **Network Policies**: Restrict traffic between namespaces
2. **Pod Security Standards**: Implement restricted policies
3. **Secret Management**: Use external secret management (Vault, AWS Secrets Manager)
4. **Image Security**: Regular vulnerability scanning

## Cleanup

### Complete Removal

```bash
# Uninstall Helm release
helm uninstall nexus-release -n nexus

# Delete namespace (includes all resources)
kubectl delete namespace nexus

# Delete TLS certificate (if external)
kubectl delete secret nexus-tls

# Delete persistent volumes (if not using dynamic provisioning)
kubectl delete pv nexus-pv
```

### Selective Cleanup

```bash
# Remove only ingress
kubectl delete ingress -n nexus nexus-release-nexus-chart-ingress

# Remove only secrets
kubectl delete secret -n nexus nexus-release-nexus-chart-secret

# Scale down without deleting data
kubectl scale deployment -n nexus nexus-release-nexus-chart --replicas=0
```

## Troubleshooting Guide

### Common Issues and Solutions

| Issue | Symptoms | Solution |
|-------|----------|----------|
| Pod CrashLoopBackOff | Pod restarts continuously | Check resource limits, storage permissions |
| Ingress 404 | Cannot access via domain | Verify ingress controller, DNS settings |
| Database Connection Failed | Logs show DB errors | Check DB credentials, network connectivity |
| Storage Issues | Pod pending, PVC not bound | Verify storage class, available storage |
| Permission Denied | File system errors | Check security context, PVC permissions |

### Debug Commands

```bash
# Check all resources
kubectl get all -n nexus

# Describe problematic pod
kubectl describe pod -n nexus <pod-name>

# Check resource usage
kubectl top pod -n nexus

# View detailed logs
kubectl logs -n nexus deployment/nexus-release-nexus-chart --previous

# Access pod shell
kubectl exec -it -n nexus deployment/nexus-release-nexus-chart -- /bin/bash
```

## Contributing

### Development Setup

1. Fork the repository
2. Create feature branch
3. Make changes to chart templates
4. Test with `helm lint` and `helm template`
5. Submit pull request

### Testing

```bash
# Lint chart
helm lint .

# Template generation
helm template nexus-test . --values test-values.yaml

# Dry run installation
helm install nexus-test . --dry-run --debug

# Integration tests
helm test nexus-release -n nexus
```

### Chart Versioning

Follow semantic versioning:
- Major: Breaking changes
- Minor: New features, backward compatible
- Patch: Bug fixes

## Support

For issues and questions:

1. Check troubleshooting guide above
2. Review Nexus documentation: https://help.sonatype.com/repomanager3
3. Open issue in repository
4. Contact DevOps team: devops@cprime.com

## License

This Helm chart is licensed under the Apache License 2.0. See LICENSE file for details.

---

**Chart Version**: 0.2.0  
**App Version**: 3.68.1  
**Maintained by**: DevOps Team