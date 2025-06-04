# Argo CD Helm Chart

A comprehensive Helm chart for deploying Argo CD in Kubernetes environments with enterprise-ready configurations, RBAC, ingress, TLS, and persistence support.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Chart Structure](#chart-structure)
- [Configuration](#configuration)
- [Installation](#installation)
- [Upgrade](#upgrade)
- [Verification](#verification)
- [Management](#management)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [Contributing](#contributing)

## Overview

This Helm chart deploys Argo CD, a declarative GitOps continuous delivery tool for Kubernetes. The chart is designed to be:

- **Modular**: Clean separation of concerns with dedicated templates
- **Configurable**: Extensive configuration options via `values.yaml`
- **Secure**: RBAC, TLS, and security best practices
- **Production-ready**: Supports persistence, resource limits, and monitoring

### Features

- ✅ GitOps continuous delivery
- ✅ Web UI and CLI access
- ✅ RBAC and security controls
- ✅ TLS/SSL termination
- ✅ Persistent storage
- ✅ Ingress configuration
- ✅ Configurable resource limits
- ✅ Multi-namespace application management

## Prerequisites

Before deploying this Helm chart, ensure you have:

### Required Tools
- Kubernetes cluster (v1.19+)
- Helm 3.x
- kubectl configured for your cluster
- OpenSSL (for TLS certificate generation)

### Required Permissions
- Cluster admin access for RBAC setup
- Ability to create namespaces
- Access to install Custom Resource Definitions (CRDs)

### Optional Components
- Ingress controller (nginx recommended)
- Cert-manager for automatic TLS certificates
- External database (PostgreSQL) for production

## Chart Structure

```
argocd-chart/
├── Chart.yaml                 # Chart metadata
├── values.yaml               # Default configuration values
├── templates/
│   ├── configmap.yaml        # Argo CD configuration
│   ├── secret.yaml           # Admin credentials and secrets
│   ├── pvc.yaml              # Persistent volume claim
│   ├── rbac.yaml             # RBAC roles and bindings
│   ├── service.yaml          # Kubernetes service
│   ├── ingress.yaml          # Ingress configuration
│   └── deployment.yaml       # Main Argo CD deployment
└── README.md                 # This file
```

## Configuration

### Chart Metadata (`Chart.yaml`)

```yaml
apiVersion: v2
name: argocd
description: A Helm chart for deploying Argo CD in Kubernetes
version: 0.1.0
appVersion: "2.12.4"
```

### Default Values (`values.yaml`)

The chart uses a comprehensive configuration structure:

#### Core Configuration
```yaml
argocd:
  namespace: argocd              # Target namespace
  image:
    repository: quay.io/argoproj/argocd
    tag: v2.12.4
    pullPolicy: IfNotPresent
```

#### Resource Management
```yaml
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "2Gi" 
      cpu: "2000m"
```

#### Server Configuration
```yaml
  server:
    replicas: 1
    extraArgs: []               # Additional server arguments
```

#### Ingress and TLS
```yaml
  ingress:
    enabled: true
    hostname: argocd.yourdomain.com
    tls:
      enabled: true
      secretName: argocd-tls
```

#### Persistence
```yaml
  persistence:
    enabled: true
    storageClass: standard
    size: 8Gi
```

#### Security
```yaml
  admin:
    password: "admin123"        # Change in production!
  rbac:
    enabled: true
```

#### Application Configuration
```yaml
  config:
    applicationNamespaces: "*"  # Manage apps in all namespaces
    url: "https://argocd.yourdomain.com"
```

### Customization Options

You can override any value by creating a custom `values.yaml` file:

```yaml
# custom-values.yaml
argocd:
  ingress:
    hostname: argocd.mycompany.com
  admin:
    password: "SecurePassword123!"
  resources:
    limits:
      memory: "4Gi"
      cpu: "4000m"
```

## Installation

### Step 1: Prepare Environment

1. **Create project directory:**
   ```bash
   mkdir -p ~/devops-helm-charts
   cd ~/devops-helm-charts
   ```

2. **Clone or create the chart:**
   ```bash
   helm create argocd-chart
   cd argocd-chart
   ```

3. **Clean up default files:**
   ```bash
   rm -rf templates/tests/
   rm templates/NOTES.txt templates/hpa.yaml templates/deployment.yaml
   rm templates/service.yaml templates/serviceaccount.yaml templates/ingress.yaml
   ```

### Step 2: Install Prerequisites

1. **Install Argo CD Custom Resource Definitions (CRDs):**
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/crds/application-crd.yaml
   kubectl apply -f https://raw.githubusercontent.com/argoproj/argo-cd/v2.8.4/manifests/crds/appproject-crd.yaml
   ```

2. **Verify CRDs installation:**
   ```bash
   kubectl get crd applications.argoproj.io appprojects.argoproj.io
   ```

### Step 3: Configure TLS (Development)

For development/testing environments:

```bash
# Generate self-signed certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout argocd-tls.key \
  -out argocd-tls.crt \
  -subj "/CN=argocd.local/O=argocd.local"

# Create TLS secret
kubectl create secret tls argocd-tls \
  --key argocd-tls.key \
  --cert argocd-tls.crt \
  --namespace argocd
```

### Step 4: Deploy Argo CD

1. **Validate the chart:**
   ```bash
   helm lint .
   ```

2. **Dry run deployment:**
   ```bash
   helm install argocd-release . --dry-run --debug --namespace argocd
   ```

3. **Install Argo CD:**
   ```bash
   helm install argocd-release . --namespace argocd --create-namespace
   ```

4. **Apply additional RBAC permissions:**
   ```bash
   kubectl apply -f - <<EOF
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRole
   metadata:
     name: argocd-release-argocd-role-patch
   rules:
   - apiGroups: ["argoproj.io"]
     resources: ["applications", "appprojects", "applicationsets"]
     verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
   - apiGroups: [""]
     resources: ["events", "namespaces"]
     verbs: ["create", "list", "get", "watch"]
   ---
   apiVersion: rbac.authorization.k8s.io/v1
   kind: ClusterRoleBinding
   metadata:
     name: argocd-release-argocd-binding-patch
   subjects:
   - kind: ServiceAccount
     name: argocd-release-argocd-sa
     namespace: argocd
   roleRef:
     kind: ClusterRole
     name: argocd-release-argocd-role-patch
     apiGroup: rbac.authorization.k8s.io
   EOF
   ```

## Upgrade

### Upgrading the Deployment

1. **Update configuration:**
   Edit your `values.yaml` or create a new configuration file.

2. **Upgrade the release:**
   ```bash
   helm upgrade argocd-release . --namespace argocd
   ```

3. **Upgrade with custom values:**
   ```bash
   helm upgrade argocd-release . --namespace argocd -f custom-values.yaml
   ```

4. **Check upgrade status:**
   ```bash
   helm status argocd-release -n argocd
   helm history argocd-release -n argocd
   ```

### Rolling Back

If needed, you can rollback to a previous version:

```bash
# List release history
helm history argocd-release -n argocd

# Rollback to previous version
helm rollback argocd-release -n argocd

# Rollback to specific revision
helm rollback argocd-release 1 -n argocd
```

## Verification

### Check Deployment Status

```bash
# Check all resources
kubectl get all -n argocd

# Check specific components
kubectl get pods -n argocd
kubectl get services -n argocd
kubectl get ingress -n argocd
kubectl get pvc -n argocd

# Check Helm release
helm list -n argocd
```

### Access Argo CD

#### Method 1: Port Forwarding (Development)
```bash
kubectl port-forward svc/argocd-release-argocd-server -n argocd 9090:80
```
Access at: http://localhost:9090

#### Method 2: Ingress (Production)
Access at: https://argocd.yourdomain.com

#### Method 3: NodePort (Testing)
```bash
kubectl patch svc argocd-release-argocd-server -n argocd -p '{"spec":{"type":"NodePort"}}'
kubectl get svc argocd-release-argocd-server -n argocd
```

### Login Credentials

- **Username:** `admin`
- **Password:** Check your `values.yaml` or retrieve from secret:
  ```bash
  kubectl get secret argocd-secret -n argocd -o jsonpath="{.data.admin-password}" | base64 -d
  ```

## Management

### Common Operations

#### Check Logs
```bash
# Server logs
kubectl logs -f deployment/argocd-release-argocd-server -n argocd

# All pods logs
kubectl logs -f -l app.kubernetes.io/part-of=argocd -n argocd
```

#### Scale Deployment
```bash
kubectl scale deployment argocd-release-argocd-server --replicas=2 -n argocd
```

#### Update Admin Password
```bash
# Create new password hash
PASSWORD_HASH=$(echo -n "newpassword" | base64)

# Update secret
kubectl patch secret argocd-secret -n argocd -p "{\"data\":{\"admin-password\":\"$PASSWORD_HASH\"}}"
```

### Monitoring and Health Checks

#### Health Check Endpoints
- Server health: `https://argocd.yourdomain.com/healthz`
- Metrics: `https://argocd.yourdomain.com/metrics`

#### Resource Monitoring
```bash
# Check resource usage
kubectl top pods -n argocd
kubectl describe pod <pod-name> -n argocd
```

## Troubleshooting

### Common Issues

#### 1. Pod Not Starting
```bash
# Check pod status and events
kubectl describe pod <pod-name> -n argocd
kubectl logs <pod-name> -n argocd
```

#### 2. Ingress Not Working
```bash
# Check ingress controller
kubectl get pods -n ingress-nginx
kubectl describe ingress argocd-release-argocd-ingress -n argocd
```

#### 3. Permission Issues
```bash
# Check RBAC
kubectl auth can-i create applications --as=system:serviceaccount:argocd:argocd-release-argocd-sa
```

#### 4. Storage Issues
```bash
# Check PVC status
kubectl describe pvc -n argocd
kubectl get storageclass
```

### Debug Commands

```bash
# General debugging
kubectl get events -n argocd --sort-by='.lastTimestamp'
helm get values argocd-release -n argocd
helm get manifest argocd-release -n argocd

# Network debugging
kubectl exec -it <pod-name> -n argocd -- nslookup kubernetes.default
kubectl port-forward <pod-name> -n argocd 8080:8080
```

## Security Considerations

### Production Security Checklist

- [ ] Change default admin password
- [ ] Enable TLS with valid certificates
- [ ] Configure proper RBAC policies
- [ ] Use secrets management (HashiCorp Vault, etc.)
- [ ] Enable audit logging
- [ ] Configure network policies
- [ ] Use non-root containers
- [ ] Regular security updates

### Recommended Security Settings

```yaml
# production-values.yaml
argocd:
  admin:
    password: "StrongPassword123!"
  rbac:
    enabled: true
  ingress:
    tls:
      enabled: true
      secretName: argocd-tls-prod
  config:
    applicationNamespaces: "production,staging"  # Limit scope
```

## Project Deliverables

This Helm chart fulfills the following project requirements:

### ✅ Task 4 Requirements Met:
- **Modular Helm chart** with parameterized configuration
- **values.yaml** for dynamic configuration
- **ConfigMaps/Secrets** for application configuration
- **RBAC** for security and access control
- **Ingress with TLS** for secure web access
- **PVC support** for persistent storage

### ✅ Additional Features:
- Comprehensive documentation
- Installation and upgrade procedures
- Configuration guide with examples
- Troubleshooting section
- Security best practices
- Production-ready configurations

### File Structure Delivered:
```
argocd-chart/
├── Chart.yaml           ✅ Chart metadata
├── values.yaml          ✅ Configuration parameters
├── templates/           ✅ Kubernetes manifests
│   ├── configmap.yaml   ✅ Application configuration
│   ├── secret.yaml      ✅ Credentials management
│   ├── pvc.yaml         ✅ Persistent storage
│   ├── rbac.yaml        ✅ Security policies
│   ├── service.yaml     ✅ Network access
│   └── ingress.yaml     ✅ External access with TLS
└── README.md            ✅ Complete documentation
```

## Contributing

### Making Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test with `helm lint` and `helm template`
5. Update documentation
6. Submit a pull request

### Testing

```bash
# Lint the chart
helm lint .

# Test template rendering
helm template test-release . --debug

# Test installation
helm install test-release . --dry-run --debug
```

---

**Chart Version:** 0.1.0  
**Argo CD Version:** 2.12.4  
**Kubernetes Compatibility:** 1.19+  
**Helm Version:** 3.x

For issues and feature requests, please create an issue in the project repository.