# DevOps Helm Charts

A comprehensive collection of modular, parameterized Helm charts for core DevOps tools including Argo CD, Jenkins, Nexus, and SonarQube.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Helm Charts](#helm-charts)
- [Quick Start](#quick-start)
- [Individual Chart Deployment](#individual-chart-deployment)
- [Configuration Guide](#configuration-guide)
- [Management Operations](#management-operations)
- [Troubleshooting](#troubleshooting)
- [Security](#security)
- [Backup & Recovery](#backup--recovery)
- [Contributing](#contributing)

## 🎯 Overview

This repository contains production-ready Helm charts for deploying a complete DevOps toolchain on Kubernetes:

- **Argo CD**: GitOps continuous delivery tool
- **Jenkins**: Continuous Integration/Continuous Deployment platform
- **Nexus**: Artifact repository manager
- **SonarQube**: Code quality and security analysis platform

### Key Features

- ✅ Modular and parameterized charts using `values.yaml`
- ✅ ConfigMaps and Secrets management
- ✅ RBAC (Role-Based Access Control) implementation
- ✅ Ingress with TLS support
- ✅ External database support and PVC configuration
- ✅ Resource management and scaling
- ✅ Health checks and monitoring
- ✅ Backup and recovery scripts

## 📋 Prerequisites

### System Requirements

- Kubernetes cluster (v1.20+)
- Helm 3.8+
- kubectl configured with cluster access
- Docker (for local development)

### For Local Development (WSL/Linux)

- Debian/Ubuntu WSL or Linux distribution
- Docker Engine
- Kind (Kubernetes in Docker)
- NGINX Ingress Controller

## 🚀 Environment Setup

### Step 1: Update System and Install Prerequisites

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Add user to docker group
sudo usermod -aG docker $USER
newgrp docker

# Verify Docker installation
docker --version
```

### Step 2: Install Kubernetes (Kind for local development)

```bash
# Install Kind
curl -Lo ./kind https://github.com/kubernetes-sigs/kind/releases/download/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Verify Kind installation
kind --version

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Verify kubectl installation
kubectl version --client
```

### Step 3: Install Helm

```bash
# Install Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt update
sudo apt install helm

# Verify Helm installation
helm version
```

### Step 4: Create Kubernetes Cluster

```bash
# Create Kind cluster configuration
cat << EOF > kind-config.yaml
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

# Create the cluster
kind create cluster --config=kind-config.yaml --name=devops-cluster

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

### Step 5: Install NGINX Ingress Controller

```bash
# Install NGINX Ingress Controller
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

# Wait for ingress controller to be ready
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s

# Verify ingress controller
kubectl get pods -n ingress-nginx
```

## 📦 Helm Charts

### Chart Structure

```
devops-helm-charts/
├── argocd-chart/          # Argo CD Helm chart
├── jenkins-chart/         # Jenkins Helm chart
├── nexus-chart/          # Nexus Helm chart
└── sonarqube-chart/      # SonarQube Helm chart
```

Each chart contains:
- `Chart.yaml` - Chart metadata
- `values.yaml` - Default configuration values
- `templates/` - Kubernetes resource templates
- TLS certificates for local development
- Backup scripts

## 🚀 Quick Start

### Clone Repository

```bash
git clone <repository-url>
cd devops-helm-charts
```

### Deploy All Applications

```bash
# Create namespaces
kubectl create namespace argocd
kubectl create namespace jenkins
kubectl create namespace nexus
kubectl create namespace sonarqube

# Deploy all charts
helm install argocd-release ./argocd-chart --namespace argocd
helm install jenkins-release ./jenkins-chart --namespace jenkins
helm install nexus-release ./nexus-chart --namespace nexus
helm install sonarqube-release ./sonarqube-chart --namespace sonarqube
```

### Access Applications

Add to your `/etc/hosts` file:
```bash
echo "127.0.0.1 argocd.local jenkins.local nexus.local sonarqube.local" | sudo tee -a /etc/hosts
```

Access URLs:
- Argo CD: https://argocd.local
- Jenkins: http://jenkins.local
- Nexus: http://nexus.local
- SonarQube: http://sonarqube.local

## 📋 Individual Chart Deployment

### 1. Argo CD Deployment

#### Install Steps

```bash
# Create namespace
kubectl create namespace argocd

# Create TLS certificate
cd argocd-chart
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout argocd-tls.key \
  -out argocd-tls.crt \
  -subj "/CN=argocd.local/O=argocd.local"

# Create TLS secret
kubectl create secret tls argocd-tls \
  --key argocd-tls.key \
  --cert argocd-tls.crt \
  --namespace argocd

# Deploy Argo CD
helm install argocd-release . --namespace argocd

# Check deployment
kubectl get pods -n argocd
kubectl get ingress -n argocd
```

#### Configuration

Key `values.yaml` parameters:
```yaml
argocd:
  image:
    repository: argoproj/argocd
    tag: "v2.8.4"
  
  service:
    type: ClusterIP
    port: 8080
  
  admin:
    username: "admin"
    password: "admin123"

ingress:
  enabled: true
  className: "nginx"
  hosts:
    - host: argocd.local
```

### 2. Jenkins Deployment

#### Install Steps

```bash
# Create namespace
kubectl create namespace jenkins

# Deploy Jenkins
cd jenkins-chart
helm install jenkins-release . --namespace jenkins

# Get admin password
kubectl get secret -n jenkins jenkins-release-jenkins-chart-secret \
  -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode
```

#### Configuration

Key `values.yaml` parameters:
```yaml
jenkins:
  image:
    repository: jenkins/jenkins
    tag: "2.426.1-lts"
  
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "2Gi"
      cpu: "2000m"
  
  persistence:
    enabled: true
    size: "10Gi"
  
  admin:
    username: "admin"
    password: "admin123"
```

### 3. Nexus Deployment

#### Install Steps

```bash
# Create namespace
kubectl create namespace nexus

# Deploy Nexus
cd nexus-chart
helm install nexus-release . --namespace nexus

# Check deployment
kubectl get pods -n nexus
```

#### Configuration

Key `values.yaml` parameters:
```yaml
nexus:
  image:
    repository: sonatype/nexus3
    tag: "3.41.1"
  
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "4Gi"
      cpu: "2000m"
  
  persistence:
    enabled: true
    size: "20Gi"
```

### 4. SonarQube Deployment

#### Install Steps

```bash
# Create namespace
kubectl create namespace sonarqube

# Deploy SonarQube
cd sonarqube-chart
helm install sonarqube-release . --namespace sonarqube

# Check deployment
kubectl get pods -n sonarqube
```

#### Configuration

Key `values.yaml` parameters:
```yaml
sonarqube:
  image:
    repository: sonarqube
    tag: "9.9.2-community"
  
  resources:
    requests:
      memory: "1Gi"
      cpu: "500m"
    limits:
      memory: "4Gi"
      cpu: "2000m"

database:
  internal:
    enabled: true
  external:
    enabled: false
```

## ⚙️ Configuration Guide

### External Database Configuration

For production deployments, configure external databases:

#### PostgreSQL for SonarQube

```yaml
# sonarqube-chart/values.yaml
database:
  external:
    enabled: true
    host: "postgres.example.com"
    port: 5432
    name: "sonarqube"
    username: "sonarqube"
    password: "your-password"
```

### Resource Scaling

Adjust resources based on your requirements:

```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "8Gi"
    cpu: "4000m"
```

### Ingress Configuration

#### Production TLS Setup

```yaml
ingress:
  enabled: true
  className: "nginx"
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  hosts:
    - host: jenkins.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: jenkins-tls-prod
      hosts:
        - jenkins.yourdomain.com
```

### Custom Plugin Installation (Jenkins)

```yaml
jenkins:
  installPlugins:
    - kubernetes:latest
    - workflow-aggregator:latest
    - git:latest
    - blueocean:latest
    - pipeline-stage-view:latest
    - your-custom-plugin:version
```

## 🔧 Management Operations

### Install & Upgrade Steps

#### Install Application

```bash
# Validate chart
helm lint ./chart-name

# Dry run
helm install release-name ./chart-name --dry-run --debug --namespace namespace-name

# Install
helm install release-name ./chart-name --namespace namespace-name --create-namespace
```

#### Upgrade Application

```bash
# Update values.yaml with new configuration
# Then upgrade
helm upgrade release-name ./chart-name --namespace namespace-name

# Check upgrade status
helm status release-name -n namespace-name
helm history release-name -n namespace-name
```

#### Rollback

```bash
# List releases
helm history release-name -n namespace-name

# Rollback to previous version
helm rollback release-name 1 -n namespace-name
```

### Monitoring

```bash
# Check pod status
kubectl get pods -n namespace-name

# Check resource usage
kubectl top pods -n namespace-name

# View logs
kubectl logs -n namespace-name deployment/deployment-name

# Describe resources
kubectl describe pod -n namespace-name pod-name
```

## 🛠️ Troubleshooting

### Common Issues

#### 1. Pod Not Starting

```bash
# Check pod events
kubectl describe pod -n namespace-name pod-name

# Check logs
kubectl logs -n namespace-name pod-name

# Check resource constraints
kubectl top nodes
kubectl top pods -n namespace-name
```

#### 2. Ingress Not Working

```bash
# Check ingress status
kubectl get ingress -n namespace-name
kubectl describe ingress -n namespace-name ingress-name

# Check ingress controller
kubectl get pods -n ingress-nginx
```

#### 3. Persistent Volume Issues

```bash
# Check PVC status
kubectl get pvc -n namespace-name
kubectl describe pvc -n namespace-name pvc-name

# Check storage class
kubectl get storageclass
```

### Debug Commands

```bash
# Access pod shell
kubectl exec -it -n namespace-name pod-name -- /bin/bash

# Port forward for direct access
kubectl port-forward -n namespace-name svc/service-name local-port:service-port

# Check cluster events
kubectl get events --sort-by=.metadata.creationTimestamp
```

## 🔒 Security

### RBAC Configuration

Each chart includes proper RBAC configuration:

```yaml
rbac:
  create: true
  rules:
    - apiGroups: [""]
      resources: ["pods", "pods/exec", "pods/log"]
      verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
```

### Security Context

```yaml
securityContext:
  runAsUser: 1000
  runAsGroup: 1000
  fsGroup: 1000
  runAsNonRoot: true
```

### TLS Configuration

All charts support TLS termination at the ingress level:

```yaml
ingress:
  tls:
    - secretName: app-tls
      hosts:
        - app.yourdomain.com
```

## 💾 Backup & Recovery

### Automated Backup Scripts

Each chart includes backup scripts in their respective directories:

#### Jenkins Backup

```bash
# Run backup
cd jenkins-chart
./backup-jenkins.sh

# Restore from backup
kubectl exec -n jenkins deployment/jenkins-release-jenkins-chart -- \
  tar xzf - -C /var/jenkins_home < backup-file.tar.gz
```

#### Nexus Backup

```bash
# Run backup
cd nexus-chart
./backup-nexus.sh
```

### Manual Backup

```bash
# Create persistent volume backup
kubectl exec -n namespace-name deployment/deployment-name -- \
  tar czf - /data/path | gzip > backup-$(date +%Y%m%d-%H%M%S).tar.gz
```

## 📊 Monitoring & Observability

### Health Checks

All applications include proper health checks:

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 180
  periodSeconds: 30

readinessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 120
  periodSeconds: 10
```

### Resource Monitoring

```bash
# Monitor resource usage
kubectl top pods -n namespace-name
kubectl top nodes

# Check cluster resource allocation
kubectl describe nodes
```

## 🗑️ Cleanup

### Remove Individual Application

```bash
# Uninstall release
helm uninstall release-name -n namespace-name

# Delete namespace
kubectl delete namespace namespace-name
```

### Complete Cleanup

```bash
# Remove all releases
helm uninstall argocd-release -n argocd
helm uninstall jenkins-release -n jenkins
helm uninstall nexus-release -n nexus
helm uninstall sonarqube-release -n sonarqube

# Delete namespaces
kubectl delete namespace argocd jenkins nexus sonarqube

# Delete Kind cluster (if using local setup)
kind delete cluster --name=devops-cluster
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Chart Development Guidelines

- Follow Helm best practices
- Include proper documentation
- Add appropriate labels and annotations
- Implement health checks
- Use semantic versioning

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review Kubernetes and Helm documentation
3. Check application-specific documentation
4. Create an issue in the repository

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This README covers all task deliverables including:
- ✅ Modular, parameterized Helm charts for all applications
- ✅ values.yaml for dynamic configuration
- ✅ ConfigMaps/Secrets implementation
- ✅ RBAC configuration
- ✅ Ingress with TLS support
- ✅ External database and PVC support
- ✅ Complete install & upgrade steps
- ✅ Comprehensive configuration guide
- ✅ Deployment steps for all applications