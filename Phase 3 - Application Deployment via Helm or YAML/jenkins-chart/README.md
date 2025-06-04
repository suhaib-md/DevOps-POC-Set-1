# Jenkins Helm Chart

A comprehensive Helm chart for deploying Jenkins CI/CD server on Kubernetes with advanced configuration options, security features, and production-ready settings.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Chart Structure](#chart-structure)
- [Configuration](#configuration)
- [Installation](#installation)
- [Upgrading](#upgrading)
- [Security](#security)
- [Monitoring](#monitoring)
- [Backup & Recovery](#backup--recovery)
- [Troubleshooting](#troubleshooting)
- [Advanced Configuration](#advanced-configuration)
- [Contributing](#contributing)

## Overview

This Helm chart deploys Jenkins with the following features:

- **Jenkins LTS**: Latest Long Term Support version (2.426.1-lts)
- **Configuration as Code (JCasC)**: Automated Jenkins configuration
- **Kubernetes Integration**: Native Kubernetes plugin support
- **Persistent Storage**: Configurable data persistence
- **RBAC**: Role-based access control
- **Ingress**: TLS-enabled external access
- **Security**: Hardened security configuration
- **Monitoring**: Optional Prometheus integration
- **Scalability**: Resource management and auto-scaling support

### Key Features

- ✅ Production-ready Jenkins deployment
- ✅ Automated plugin installation
- ✅ Configuration as Code (JCasC) support
- ✅ Kubernetes-native CI/CD pipelines
- ✅ Persistent volume claims for data retention
- ✅ NGINX Ingress with TLS termination
- ✅ RBAC for secure Kubernetes integration
- ✅ Monitoring and observability
- ✅ Backup and disaster recovery support

## Prerequisites

### Environment Requirements

- **Kubernetes**: v1.19+ 
- **Helm**: v3.0+
- **kubectl**: Compatible with your cluster version
- **Storage**: Default storage class or custom PVC support

### Local Development Setup

For local development using Kind (Kubernetes in Docker):

```bash
# Install Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io

# Install Kind
curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.20.0/kind-linux-amd64
chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && sudo mv kubectl /usr/local/bin/

# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update && sudo apt install helm
```

### Create Development Cluster

```bash
# Create Kind cluster with port mappings
cat <<EOF > kind-config.yaml
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 8081
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
  - containerPort: 8080
    hostPort: 8082
    protocol: TCP
- role: worker
- role: worker
EOF

kind create cluster --config=kind-config.yaml --name=devops-cluster

# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=90s
```

## Quick Start

```bash
# Clone the chart
git clone <repository-url>
cd jenkins-chart

# Create namespace
kubectl create namespace jenkins

# Install with default values
helm install jenkins-release . --namespace jenkins

# Access Jenkins
kubectl port-forward -n jenkins svc/jenkins-release-jenkins-chart-service 8080:8080
```

Default credentials: `admin/admin123`

## Chart Structure

```
jenkins-chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── templates/
│   ├── _helpers.tpl          # Template helpers
│   ├── configmap.yaml        # Jenkins configuration
│   ├── deployment.yaml       # Jenkins deployment
│   ├── ingress.yaml          # Ingress configuration
│   ├── pvc.yaml              # Persistent volume claim
│   ├── rbac.yaml             # RBAC resources
│   ├── secret.yaml           # Secrets management
│   ├── service.yaml          # Kubernetes service
│   └── serviceaccount.yaml   # Service account
├── README.md                 # This file
└── examples/
    ├── production-values.yaml
    ├── development-values.yaml
    └── external-db-values.yaml
```

## Configuration

### Core Configuration Options

| Parameter | Description | Default |
|-----------|-------------|---------|
| `jenkins.image.repository` | Jenkins Docker image | `jenkins/jenkins` |
| `jenkins.image.tag` | Jenkins image tag | `2.426.1-lts` |
| `jenkins.admin.username` | Jenkins admin username | `admin` |
| `jenkins.admin.password` | Jenkins admin password | `admin123` |
| `jenkins.persistence.enabled` | Enable persistent storage | `true` |
| `jenkins.persistence.size` | PVC size | `10Gi` |
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.hosts[0].host` | Ingress hostname | `jenkins.local` |

### Resource Configuration

```yaml
jenkins:
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "2000m"
```

### Plugin Configuration

```yaml
jenkins:
  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - configuration-as-code:latest
    - blueocean:latest
    - pipeline-stage-view:latest
    - docker-workflow:latest
    - github:latest
```

### JCasC Configuration

```yaml
jenkins:
  jcasc:
    enabled: true
    configScripts:
      welcome-message: |
        jenkins:
          systemMessage: "Welcome to Jenkins - Deployed via Helm!"
      security-realm: |
        jenkins:
          securityRealm:
            local:
              allowsSignup: false
```

## Installation

### Basic Installation

```bash
# Install with default values
helm install jenkins-release . --namespace jenkins --create-namespace

# Install with custom values
helm install jenkins-release . \
  --namespace jenkins \
  --create-namespace \
  --set jenkins.admin.password=mySecurePassword \
  --set jenkins.persistence.size=20Gi
```

### Production Installation

```bash
# Create production values file
cat <<EOF > production-values.yaml
jenkins:
  image:
    tag: "2.426.1-lts"
  admin:
    username: "admin"
    password: "MySecureProductionPassword!"
  
  resources:
    requests:
      memory: "1Gi"
      cpu: "1000m"
    limits:
      memory: "4Gi"
      cpu: "4000m"
  
  persistence:
    enabled: true
    size: "50Gi"
    storageClass: "fast-ssd"

ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
  hosts:
    - host: jenkins.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: jenkins-tls-prod
      hosts:
        - jenkins.yourdomain.com

monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
EOF

# Install with production values
helm install jenkins-release . \
  --namespace jenkins \
  --create-namespace \
  --values production-values.yaml
```

### Installation with External Database

```bash
cat <<EOF > external-db-values.yaml
jenkins:
  persistence:
    enabled: true
    size: "20Gi"

database:
  external:
    enabled: true
    host: "postgres.example.com"
    port: 5432
    name: "jenkins"
    username: "jenkins"
    password: "your-secure-password"
EOF

helm install jenkins-release . \
  --namespace jenkins \
  --create-namespace \
  --values external-db-values.yaml
```

## Upgrading

### Standard Upgrade Process

```bash
# Check current release
helm list -n jenkins

# Update chart values
# Edit values.yaml or create new values file

# Upgrade the release
helm upgrade jenkins-release . --namespace jenkins

# Check upgrade status
helm status jenkins-release -n jenkins
helm history jenkins-release -n jenkins
```

### Rolling Back

```bash
# View release history
helm history jenkins-release -n jenkins

# Rollback to previous version
helm rollback jenkins-release -n jenkins

# Rollback to specific revision
helm rollback jenkins-release 2 -n jenkins
```

### Zero-Downtime Upgrades

```bash
# Create backup before upgrade
./scripts/backup-jenkins.sh

# Upgrade with wait for pods to be ready
helm upgrade jenkins-release . \
  --namespace jenkins \
  --wait \
  --timeout=600s

# Verify upgrade
kubectl get pods -n jenkins
kubectl logs -n jenkins deployment/jenkins-release-jenkins-chart
```

## Security

### TLS Configuration

#### Self-Signed Certificates (Development)

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout jenkins-tls.key \
  -out jenkins-tls.crt \
  -subj "/CN=jenkins.local/O=jenkins.local"

# Create TLS secret
kubectl create secret tls jenkins-tls \
  --key jenkins-tls.key \
  --cert jenkins-tls.crt \
  --namespace jenkins
```

#### Production TLS with cert-manager

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

### RBAC Configuration

The chart creates minimal RBAC permissions:

```yaml
rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["pods", "pods/exec", "pods/log"]
      verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
    - apiGroups: [""]
      resources: ["secrets", "configmaps"]
      verbs: ["get", "list", "watch"]
```

### Security Best Practices

1. **Change Default Passwords**: Always change default admin credentials
2. **Enable HTTPS**: Use TLS for all communications
3. **Restrict RBAC**: Use minimal required permissions
4. **Network Policies**: Implement network segmentation
5. **Regular Updates**: Keep Jenkins and plugins updated

## Monitoring

### Prometheus Integration

```yaml
monitoring:
  enabled: true
  serviceMonitor:
    enabled: true
    interval: "30s"
    path: "/prometheus"
    labels:
      release: prometheus
```

### Health Checks

The deployment includes comprehensive health checks:

```yaml
livenessProbe:
  httpGet:
    path: /login
    port: 8080
  initialDelaySeconds: 180
  periodSeconds: 30
  timeoutSeconds: 10
  failureThreshold: 5

readinessProbe:
  httpGet:
    path: /login
    port: 8080
  initialDelaySeconds: 120
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

### Monitoring Commands

```bash
# Check resource usage
kubectl top pods -n jenkins

# Monitor logs
kubectl logs -f -n jenkins deployment/jenkins-release-jenkins-chart

# Get detailed pod information
kubectl describe pod -n jenkins <pod-name>

# Check events
kubectl get events -n jenkins --sort-by=.metadata.creationTimestamp
```

## Backup & Recovery

### Automated Backup Script

```bash
#!/bin/bash
# backup-jenkins.sh

NAMESPACE="jenkins"
DEPLOYMENT_NAME="jenkins-release-jenkins-chart"
BACKUP_DIR="/tmp/jenkins-backup-$(date +%Y%m%d-%H%M%S)"
JENKINS_HOME="/var/jenkins_home"

echo "Creating backup directory: $BACKUP_DIR"
mkdir -p $BACKUP_DIR

echo "Backing up Jenkins data..."
kubectl exec -n $NAMESPACE deployment/$DEPLOYMENT_NAME -- \
  tar czf - $JENKINS_HOME | tar xzf - -C $BACKUP_DIR

echo "Backup completed: $BACKUP_DIR"
echo "Backup size: $(du -sh $BACKUP_DIR)"

# Optional: Upload to cloud storage
# aws s3 cp $BACKUP_DIR s3://your-backup-bucket/jenkins-backups/
```

### Restore Process

```bash
#!/bin/bash
# restore-jenkins.sh

NAMESPACE="jenkins"
DEPLOYMENT_NAME="jenkins-release-jenkins-chart"
BACKUP_PATH="/path/to/backup"

echo "Scaling down Jenkins..."
kubectl scale deployment -n $NAMESPACE $DEPLOYMENT_NAME --replicas=0

echo "Waiting for pod termination..."
kubectl wait --for=delete pod -n $NAMESPACE -l app.kubernetes.io/name=jenkins-chart

echo "Restoring from backup..."
kubectl exec -n $NAMESPACE deployment/$DEPLOYMENT_NAME -- \
  rm -rf /var/jenkins_home/*

tar czf - -C $BACKUP_PATH var/jenkins_home | \
  kubectl exec -i -n $NAMESPACE deployment/$DEPLOYMENT_NAME -- \
  tar xzf - -C /

echo "Scaling up Jenkins..."
kubectl scale deployment -n $NAMESPACE $DEPLOYMENT_NAME --replicas=1
```

### Scheduled Backups with CronJob

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: jenkins-backup
  namespace: jenkins
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: alpine:latest
            command:
            - /bin/sh
            - -c
            - |
              apk add --no-cache tar kubectl
              kubectl exec deployment/jenkins-release-jenkins-chart -- \
                tar czf - /var/jenkins_home > /backup/jenkins-$(date +%Y%m%d).tar.gz
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: jenkins-backup-pvc
          restartPolicy: OnFailure
```

## Troubleshooting

### Common Issues

#### 1. Pod Stuck in Pending State

```bash
# Check node resources
kubectl describe nodes

# Check PVC status
kubectl get pvc -n jenkins

# Check storage class
kubectl get storageclass
```

#### 2. Jenkins Won't Start

```bash
# Check logs
kubectl logs -n jenkins deployment/jenkins-release-jenkins-chart

# Check resource limits
kubectl describe pod -n jenkins <pod-name>

# Verify configuration
kubectl get configmap -n jenkins jenkins-release-jenkins-chart-config -o yaml
```

#### 3. Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Verify ingress resource
kubectl describe ingress -n jenkins

# Check DNS resolution
nslookup jenkins.local

# Test connectivity
curl -k https://jenkins.local
```

#### 4. Plugin Installation Failures

```bash
# Check plugin list
kubectl exec -n jenkins deployment/jenkins-release-jenkins-chart -- \
  ls /usr/share/jenkins/ref/plugins/

# Verify plugin configuration
kubectl get configmap -n jenkins jenkins-release-jenkins-chart-config -o yaml

# Check Jenkins logs for plugin errors
kubectl logs -n jenkins deployment/jenkins-release-jenkins-chart | grep -i plugin
```

### Debug Commands

```bash
# Get all resources
kubectl get all -n jenkins

# Describe deployment
kubectl describe deployment -n jenkins jenkins-release-jenkins-chart

# Check configuration
kubectl get secret -n jenkins jenkins-release-jenkins-chart-secret -o yaml

# Access pod shell
kubectl exec -it -n jenkins deployment/jenkins-release-jenkins-chart -- /bin/bash

# Port forward for direct access
kubectl port-forward -n jenkins svc/jenkins-release-jenkins-chart-service 8080:8080
```

## Advanced Configuration

### Custom Docker Image

```yaml
jenkins:
  image:
    repository: "your-registry/custom-jenkins"
    tag: "latest"
    pullPolicy: Always
    pullSecrets:
      - name: your-registry-secret
```

### Multiple Jenkins Instances

```bash
# Install multiple instances with different names
helm install jenkins-dev . \
  --namespace jenkins-dev \
  --create-namespace \
  --set ingress.hosts[0].host=jenkins-dev.local

helm install jenkins-staging . \
  --namespace jenkins-staging \
  --create-namespace \
  --set ingress.hosts[0].host=jenkins-staging.local
```

### Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: jenkins-quota
  namespace: jenkins
spec:
  hard:
    requests.cpu: "4"
    requests.memory: 8Gi
    limits.cpu: "8"
    limits.memory: 16Gi
    persistentvolumeclaims: "1"
```

### Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: jenkins-network-policy
  namespace: jenkins
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: jenkins-chart
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - {}
```

## Project Deliverables

This Jenkins Helm Chart is part of a comprehensive DevOps toolchain deployment project. Related deliverables include:

### 1. Complete Helm Chart Package
- ✅ Jenkins Helm Chart (this repository)
- 🔄 Argo CD Helm Chart (separate repository)
- 🔄 Nexus Helm Chart (separate repository)  
- 🔄 SonarQube Helm Chart (separate repository)

### 2. Documentation Suite
- ✅ Jenkins Installation & Configuration Guide (this README)
- ✅ Environment Setup Instructions
- ✅ Security Best Practices
- ✅ Monitoring & Backup Procedures
- ✅ Troubleshooting Guide

### 3. Configuration Examples
- ✅ Development environment values
- ✅ Production environment values
- ✅ External database integration
- ✅ Custom plugin configurations
- ✅ Security hardening examples

### 4. Automation Scripts
- ✅ Backup and restore scripts
- ✅ Environment setup automation
- ✅ Health check utilities
- ✅ Migration tools

### Usage in CI/CD Pipeline

```yaml
# Example GitLab CI/CD pipeline
stages:
  - deploy

deploy-jenkins:
  stage: deploy
  script:
    - helm upgrade --install jenkins-release ./jenkins-chart
      --namespace jenkins
      --create-namespace
      --values production-values.yaml
      --wait
  only:
    - main
```

## Contributing

### Development Setup

```bash
# Clone repository
git clone <repository-url>
cd jenkins-chart

# Install pre-commit hooks
pre-commit install

# Validate chart
helm lint .
helm template jenkins-release . > /tmp/jenkins-output.yaml

# Test installation
helm install jenkins-test . --dry-run --debug
```

### Testing

```bash
# Run chart tests
helm test jenkins-release -n jenkins

# Validate with different values
helm template jenkins-release . -f examples/production-values.yaml

# Security scanning
helm template jenkins-release . | kubesec scan -
```

### Contribution Guidelines

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Make changes and test thoroughly
4. Update documentation
5. Commit changes (`git commit -m 'Add amazing feature'`)
6. Push to branch (`git push origin feature/amazing-feature`)
7. Open Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support and questions:

- 📧 Email: devops@cprime.com
- 📖 Documentation: [Link to docs]
- 🐛 Issues: [GitHub Issues]
- 💬 Discussions: [GitHub Discussions]

---

**Note**: This chart is designed for production use but should always be tested in a development environment first. Always review security settings and update default passwords before production deployment.