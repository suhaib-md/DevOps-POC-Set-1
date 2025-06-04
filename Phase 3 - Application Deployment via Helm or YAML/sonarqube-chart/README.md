# SonarQube Helm Chart

A comprehensive Helm chart for deploying SonarQube Community Edition on Kubernetes with support for external databases, persistent storage, RBAC, and TLS-enabled ingress.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Chart Structure](#chart-structure)
- [Configuration](#configuration)
- [Installation](#installation)
- [Upgrade](#upgrade)
- [Uninstallation](#uninstallation)
- [Configuration Examples](#configuration-examples)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Monitoring and Maintenance](#monitoring-and-maintenance)
- [Contributing](#contributing)

## Overview

This Helm chart deploys SonarQube Community Edition (version 10.3.0) on Kubernetes with the following features:

- **Flexible Database Options**: Internal PostgreSQL or external database support
- **Persistent Storage**: Configurable PVCs for data, logs, and extensions
- **Security**: RBAC integration and secret management
- **Networking**: Ingress with TLS support
- **Scalability**: Resource configuration and JVM tuning options
- **High Availability**: Support for external databases and shared storage

### Included Components

- SonarQube Application Server
- PostgreSQL Database (optional internal)
- ConfigMaps for application configuration
- Secrets for sensitive data
- RBAC (ServiceAccount, ClusterRole, ClusterRoleBinding)
- Ingress with TLS termination
- Persistent Volume Claims for data persistence

## Prerequisites

### Cluster Requirements

- Kubernetes 1.19+
- Helm 3.0+
- Ingress Controller (nginx recommended)
- Storage provisioner with dynamic PVC support

### System Requirements

- **Memory**: Minimum 2GB RAM (4GB recommended)
- **CPU**: Minimum 1 vCPU (2 vCPUs recommended)
- **Storage**: 20GB+ available space
- **Network**: Access to container registries

### Required Kubernetes Permissions

```bash
# Verify cluster permissions
kubectl auth can-i create deployment
kubectl auth can-i create service
kubectl auth can-i create ingress
kubectl auth can-i create pvc
```

## Quick Start

### 1. Clone and Prepare

```bash
# Clone the repository
git clone <repository-url>
cd sonarqube-chart

# Verify chart structure
helm lint .
```

### 2. Create Namespace and TLS Certificate

```bash
# Create namespace
kubectl create namespace sonarqube

# Generate TLS certificate (for development)
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout sonarqube-tls.key \
  -out sonarqube-tls.crt \
  -subj "/CN=sonarqube.local/O=sonarqube.local"

# Create TLS secret
kubectl create secret tls sonarqube-tls \
  --key sonarqube-tls.key \
  --cert sonarqube-tls.crt \
  --namespace sonarqube
```

### 3. Deploy SonarQube

```bash
# Install with default configuration
helm install sonarqube-release . \
  --namespace sonarqube \
  --create-namespace

# Verify deployment
kubectl get pods -n sonarqube -w
```

### 4. Access SonarQube

```bash
# Port forward for local access
kubectl port-forward -n sonarqube \
  service/sonarqube-release-sonarqube-service 9000:80

# Access at http://localhost:9000
# Default credentials: admin/admin123
```

## Chart Structure

```
sonarqube-chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── templates/
│   ├── configmap.yaml        # SonarQube configuration
│   ├── secret.yaml           # Sensitive data storage
│   ├── deployment.yaml       # SonarQube deployment
│   ├── service.yaml          # Service definition
│   ├── ingress.yaml          # Ingress configuration
│   ├── pvc.yaml              # Persistent volume claims
│   ├── postgresql.yaml       # Internal PostgreSQL (optional)
│   └── rbac.yaml             # RBAC resources
└── README.md                 # This file
```

## Configuration

### Core Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sonarqube.namespace` | Target namespace | `sonarqube` |
| `sonarqube.image.repository` | SonarQube image repository | `sonarqube` |
| `sonarqube.image.tag` | SonarQube image tag | `10.3.0-community` |
| `sonarqube.server.replicas` | Number of replicas | `1` |
| `sonarqube.server.port` | SonarQube port | `9000` |

### Resource Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sonarqube.resources.requests.memory` | Memory request | `2Gi` |
| `sonarqube.resources.requests.cpu` | CPU request | `500m` |
| `sonarqube.resources.limits.memory` | Memory limit | `4Gi` |
| `sonarqube.resources.limits.cpu` | CPU limit | `2000m` |

### Storage Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sonarqube.persistence.enabled` | Enable persistent storage | `true` |
| `sonarqube.persistence.storageClass` | Storage class name | `standard` |
| `sonarqube.persistence.dataSize` | Data volume size | `10Gi` |
| `sonarqube.persistence.logsSize` | Logs volume size | `5Gi` |
| `sonarqube.persistence.extensionsSize` | Extensions volume size | `5Gi` |

### Database Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sonarqube.database.external` | Use external database | `false` |
| `sonarqube.database.host` | External DB host | `""` |
| `sonarqube.database.port` | External DB port | `5432` |
| `sonarqube.database.postgresql.enabled` | Enable internal PostgreSQL | `true` |
| `sonarqube.database.postgresql.storage` | PostgreSQL storage size | `10Gi` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sonarqube.ingress.enabled` | Enable ingress | `true` |
| `sonarqube.ingress.hostname` | Ingress hostname | `sonarqube.yourdomain.com` |
| `sonarqube.ingress.tls.enabled` | Enable TLS | `true` |
| `sonarqube.ingress.tls.secretName` | TLS secret name | `sonarqube-tls` |

## Installation

### Standard Installation

```bash
# Install with default values
helm install sonarqube-release . \
  --namespace sonarqube \
  --create-namespace
```

### Custom Installation

```bash
# Install with custom values
helm install sonarqube-release . \
  --namespace sonarqube \
  --create-namespace \
  --set sonarqube.ingress.hostname=sonarqube.example.com \
  --set sonarqube.resources.limits.memory=8Gi
```

### Installation with Custom Values File

```bash
# Create custom values file
cat > custom-values.yaml <<EOF
sonarqube:
  ingress:
    hostname: sonarqube.production.com
  resources:
    limits:
      memory: 8Gi
      cpu: 4000m
  database:
    external: true
    host: postgres.production.com
    name: sonarqube_prod
EOF

# Install with custom values
helm install sonarqube-release . \
  --namespace sonarqube \
  --create-namespace \
  --values custom-values.yaml
```

### Verify Installation

```bash
# Check all resources
kubectl get all -n sonarqube

# Check pod logs
kubectl logs -n sonarqube deployment/sonarqube-release-sonarqube -f

# Check ingress
kubectl get ingress -n sonarqube

# Check persistent volumes
kubectl get pvc -n sonarqube
```

## Upgrade

### Preparation

```bash
# Check current release
helm list -n sonarqube

# Check current values
helm get values sonarqube-release -n sonarqube

# Backup current configuration
helm get values sonarqube-release -n sonarqube > current-values.yaml
```

### Upgrade Process

```bash
# Update chart dependencies (if any)
helm dependency update

# Perform dry run
helm upgrade sonarqube-release . \
  --namespace sonarqube \
  --dry-run --debug

# Execute upgrade
helm upgrade sonarqube-release . \
  --namespace sonarqube \
  --timeout 10m
```

### Upgrade with New Configuration

```bash
# Upgrade with modified values
helm upgrade sonarqube-release . \
  --namespace sonarqube \
  --set sonarqube.image.tag=10.4.0-community \
  --set sonarqube.resources.limits.memory=6Gi
```

### Post-Upgrade Verification

```bash
# Check upgrade status
helm status sonarqube-release -n sonarqube

# View upgrade history
helm history sonarqube-release -n sonarqube

# Monitor pod rollout
kubectl rollout status deployment/sonarqube-release-sonarqube -n sonarqube
```

### Rollback

```bash
# List revisions
helm history sonarqube-release -n sonarqube

# Rollback to previous version
helm rollback sonarqube-release -n sonarqube

# Rollback to specific revision
helm rollback sonarqube-release 1 -n sonarqube
```

## Uninstallation

### Standard Uninstall

```bash
# Uninstall release
helm uninstall sonarqube-release -n sonarqube

# Verify removal
helm list -n sonarqube
kubectl get all -n sonarqube
```

### Complete Cleanup

```bash
# Remove persistent volumes (CAUTION: Data will be lost)
kubectl delete pvc -n sonarqube --all

# Remove TLS secrets
kubectl delete secret sonarqube-tls -n sonarqube

# Remove namespace
kubectl delete namespace sonarqube
```

## Configuration Examples

### External PostgreSQL Database

```yaml
sonarqube:
  database:
    external: true
    host: "postgres.example.com"
    port: 5432
    name: "sonarqube"
    username: "sonarqube"
    password: "secure-password"
  # Disable internal PostgreSQL
  database:
    postgresql:
      enabled: false
```

### High-Performance Configuration

```yaml
sonarqube:
  server:
    replicas: 1
    jvmOpts: "-Xmx6g -Xms2g -XX:HeapDumpOnOutOfMemoryError"
  resources:
    requests:
      memory: "4Gi"
      cpu: "2000m"
    limits:
      memory: "8Gi"
      cpu: "4000m"
  persistence:
    dataSize: "50Gi"
    logsSize: "10Gi"
    extensionsSize: "10Gi"
```

### Production-Ready Configuration

```yaml
sonarqube:
  namespace: sonarqube-prod
  ingress:
    hostname: sonarqube.company.com
    tls:
      enabled: true
      secretName: sonarqube-prod-tls
  database:
    external: true
    host: "postgres-ha.company.com"
    port: 5432
    name: "sonarqube_production"
    username: "sonarqube_user"
    password: "very-secure-password"
  persistence:
    storageClass: "ssd-retain"
    dataSize: "100Gi"
    logsSize: "20Gi"
  admin:
    username: "admin"
    password: "production-admin-password"
  config:
    sonarJdbcMaxActive: 100
    sonarJdbcMaxIdle: 10
```

### Minimal Development Configuration

```yaml
sonarqube:
  resources:
    requests:
      memory: "1Gi"
      cpu: "250m"
    limits:
      memory: "2Gi"
      cpu: "1000m"
  persistence:
    dataSize: "5Gi"
    logsSize: "2Gi"
    extensionsSize: "2Gi"
  database:
    postgresql:
      storage: "5Gi"
```

## Troubleshooting

### Common Issues and Solutions

#### Pod Startup Issues

```bash
# Check pod status
kubectl describe pod -n sonarqube -l app=sonarqube

# Check init container logs
kubectl logs -n sonarqube -l app=sonarqube -c init-sysctl

# Verify system requirements
kubectl exec -n sonarqube deployment/sonarqube-release-sonarqube -- \
  sh -c "cat /proc/sys/vm/max_map_count && cat /proc/sys/fs/file-max"
```

#### Database Connection Issues

```bash
# Test database connectivity
kubectl exec -n sonarqube deployment/sonarqube-release-sonarqube -- \
  pg_isready -h sonarqube-release-postgresql -p 5432

# Check database credentials
kubectl get secret sonarqube-release-sonarqube-secret -n sonarqube -o yaml
```

#### Memory Issues

```bash
# Check resource usage
kubectl top pods -n sonarqube

# Review OOM events
kubectl get events -n sonarqube --field-selector reason=OOMKilling
```

#### Storage Issues

```bash
# Check PVC status
kubectl get pvc -n sonarqube

# Check storage class
kubectl get storageclass

# Verify volume mounts
kubectl describe pod -n sonarqube -l app=sonarqube
```

### Performance Tuning

#### JVM Optimization

```yaml
sonarqube:
  server:
    jvmOpts: >-
      -Xmx4g
      -Xms1g
      -XX:+HeapDumpOnOutOfMemoryError
      -XX:HeapDumpPath=/opt/sonarqube/logs/
      -Dfile.encoding=UTF-8
      -Djava.security.egd=file:/dev/./urandom
```

#### Database Tuning

```yaml
sonarqube:
  config:
    sonarJdbcMaxActive: 60
    sonarJdbcMaxIdle: 5
    sonarJdbcMinIdle: 2
    sonarJdbcMaxWait: 5000
```

### Monitoring Commands

```bash
# Monitor deployment
kubectl get events -n sonarqube --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods -n sonarqube
kubectl top nodes

# Application logs
kubectl logs -n sonarqube deployment/sonarqube-release-sonarqube --tail=100 -f

# Database logs (if internal)
kubectl logs -n sonarqube deployment/sonarqube-release-postgresql --tail=100 -f
```

## Security Considerations

### Default Security Measures

- RBAC enabled by default
- Secrets for sensitive data
- Non-root container execution
- TLS encryption for web traffic

### Production Security Recommendations

1. **Change Default Passwords**
   ```yaml
   sonarqube:
     admin:
       username: "admin"
       password: "strong-unique-password"
   ```

2. **Use External Secret Management**
   ```bash
   # Create secret externally
   kubectl create secret generic sonarqube-db-secret \
     --from-literal=username=sonarqube \
     --from-literal=password=secure-password \
     -n sonarqube
   ```

3. **Enable Network Policies**
   ```yaml
   # Add to values.yaml
   networkPolicies:
     enabled: true
   ```

4. **Use Proper TLS Certificates**
   ```bash
   # Use cert-manager or external CA
   kubectl create secret tls sonarqube-tls \
     --cert=path/to/cert.pem \
     --key=path/to/private-key.pem \
     -n sonarqube
   ```

## Monitoring and Maintenance

### Health Checks

```bash
# Application health
curl -f http://sonarqube.example.com/api/system/status

# Database health
kubectl exec -n sonarqube deployment/sonarqube-release-postgresql -- \
  pg_isready
```

### Backup Procedures

```bash
# Backup SonarQube data
kubectl exec -n sonarqube deployment/sonarqube-release-sonarqube -- \
  tar -czf /tmp/sonarqube-backup.tar.gz /opt/sonarqube/data

# Backup database
kubectl exec -n sonarqube deployment/sonarqube-release-postgresql -- \
  pg_dump -U sonarqube sonarqube > sonarqube-db-backup.sql
```

### Maintenance Tasks

```bash
# Update Helm chart
helm repo update
helm search repo sonarqube

# Check for security updates
kubectl get pods -n sonarqube -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u

# Cleanup old revisions
helm history sonarqube-release -n sonarqube
helm delete --purge sonarqube-release-old-revision
```

## Contributing

### Development Setup

```bash
# Clone repository
git clone <repository-url>
cd sonarqube-chart

# Install development dependencies
helm plugin install https://github.com/helm-unittest/helm-unittest

# Run tests
helm unittest .

# Validate chart
helm lint .
```

### Chart Validation

```bash
# Template validation
helm template sonarqube-release . \
  --values values.yaml \
  --debug > rendered-templates.yaml

# Dry run test
helm install sonarqube-test . \
  --namespace sonarqube-test \
  --create-namespace \
  --dry-run --debug
```

### Contribution Guidelines

1. Follow Helm best practices
2. Update documentation for configuration changes
3. Test with multiple Kubernetes versions
4. Validate security configurations
5. Update version in Chart.yaml

---

## Support

For support and questions:

- Create an issue in the repository
- Check existing documentation
- Review troubleshooting section
- Consult SonarQube official documentation

## License

This Helm chart is licensed under [LICENSE]. SonarQube is licensed under LGPL v3.