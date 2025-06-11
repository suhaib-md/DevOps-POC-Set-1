# DevOps POC Set-1: End-to-End DevOps Implementation

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Azure](https://img.shields.io/badge/Cloud-Azure-blue)](https://azure.microsoft.com/)
[![Kubernetes](https://img.shields.io/badge/Container-Kubernetes-326CE5)](https://kubernetes.io/)
[![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4)](https://terraform.io/)

## 📋 Project Overview

This repository contains a comprehensive DevOps Proof of Concept (POC) implementation that demonstrates enterprise-grade DevOps practices using modern cloud-native technologies. The project is structured in 6 phases, progressing from basic containerization to advanced automation and observability.

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Cloud Platform                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │ Azure Container │    │   Azure Blob    │                 │
│  │    Registry     │    │    Storage      │                 │
│  └─────────────────┘    └─────────────────┘                 │
├─────────────────────────────────────────────────────────────┤
│              AKS Cluster (Multi-AZ, 3 Nodes)                │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │   ArgoCD    │ │   Jenkins   │ │   Nexus     │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
│  ┌─────────────┐ ┌─────────────┐                            │
│  │  SonarQube  │ │ Spring Boot │                            │ 
│  │             │ │    Apps     │                            │
│  └─────────────┘ └─────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Project Structure



## 🚀 Quick Start Guide

### Prerequisites

Before starting, ensure you have the following tools installed:

- **Azure CLI** (v2.30+)
- **Docker** (v20.10+)
- **Terraform** (v1.0+)
- **kubectl** (v1.21+)
- **Helm** (v3.6+)
- **Packer** (v1.7+)
- **Git**

### Authentication Setup

```bash
# Login to Azure
az login

# Set your subscription
az account set --subscription "your-subscription-id"

# Create service principal for Terraform
az ad sp create-for-rbac --role="Contributor" --scopes="/subscriptions/your-subscription-id"
```

## 📚 Phase-by-Phase Implementation Guide

### Phase 1: Container Image Preparation 🐳

**Objective**: Create optimized Docker images for Jenkins, Nexus, and SonarQube

**Key Features**:
- Multi-stage builds for minimal image size
- Non-root user implementation
- Security best practices
- Custom plugin configurations

**Quick Commands**:
```bash
cd phase-1-containers/
docker build -t jenkins-custom ./jenkins/
docker build -t nexus-custom ./nexus/
docker build -t sonarqube-custom ./sonarqube/
```
---

### Phase 2: Terraform Infrastructure Modules 🏗️

**Objective**: Build reusable Terraform modules for Azure infrastructure

**Components**:
- Virtual Network & Subnets
- Network Security Groups
- Application Gateway
- Load Balancers
- NAT Gateway

**Quick Commands**:
```bash
cd phase-2-terraform-modules/
terraform init
terraform plan
terraform apply
```
---


### Phase 3: Helm Charts Development ⚙️

**Objective**: Create parameterized Helm charts for DevOps tools

**Applications**:
- ArgoCD
- Jenkins
- Nexus Repository
- SonarQube

**Quick Commands**:
```bash
cd phase-4-helm-charts/
helm install argocd ./argocd/
helm install jenkins ./jenkins/
helm install nexus ./nexus/
```
---

### Phase 4: CI/CD Pipeline Implementation 🔄

**Objective**: Implement automated CI/CD for Spring Boot applications

**Pipeline Features**:
- Automated testing
- Code quality analysis
- Artifact management
- Automated deployments

**Quick Commands**:
```bash
cd phase-4-cicd-pipeline/
# Check Jenkins dashboard for pipeline status
```
---

### Phase 5: Image Automation with Packer 📦

**Objective**: Create Windows 10 golden images using Packer

**Features**:
- Automated Windows updates
- Pre-installed applications
- PowerShell-based provisioning
- Azure image gallery integration

**Quick Commands**:
```bash
cd phase-5-image-automation/
packer build windows-10/windows.pkr.hcl
```
---

### Phase 6: Observability & Logging 📊

**Objective**: Implement logging and monitoring solutions

**Components**:
- Jenkins log automation
- Azure Blob storage integration
- Log analysis and retention
- Monitoring dashboards

**Quick Commands**:
```bash
cd phase-6-observability/
python3 jenkins_log_backup.py --job "your-job-name" --days 1
```

## 🛠️ Common Operations

### Environment Setup
```bash
# Clone the repository
git clone https://github.com/suhaib-md/DevOps-POC-Set-1.git
cd DevOps-POC-Set-1

# Set up environment variables
export AZURE_SUBSCRIPTION_ID="your-subscription-id"
export AZURE_TENANT_ID="your-tenant-id"
export AZURE_CLIENT_ID="your-client-id"
export AZURE_CLIENT_SECRET="your-client-secret"
```

### Cleanup Resources
```bash
# Destroy Terraform resources
cd phase-3-aks-deployment/
terraform destroy

# Remove Helm releases
helm uninstall jenkins nexus sonarqube argocd

# Delete Docker images
docker system prune -a
```

## 🔧 Troubleshooting

### Common Issues

1. **AKS Authentication Issues**
   ```bash
   az aks get-credentials --resource-group myRG --name myAKS
   ```

2. **Terraform State Lock**
   ```bash
   terraform force-unlock <lock-id>
   ```

3. **Docker Build Failures**
   ```bash
   docker system prune
   docker builder prune
   ```

4. **Helm Chart Deployment Issues**
   ```bash
   helm list --all-namespaces
   helm rollback <release-name> <revision>
   ```

## 📈 Monitoring and Validation

### Health Checks
```bash
# Check AKS cluster health
kubectl get nodes
kubectl get pods --all-namespaces

# Verify deployments
kubectl get deployments
kubectl get services

# Check Helm releases
helm list --all-namespaces
```

### Performance Metrics
- Monitor resource utilization through Azure Monitor
- Check application logs via kubectl logs
- Validate CI/CD pipeline metrics in Jenkins

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

## 📝 Documentation

- **[Architecture Guide](./docs/architecture.md)**: Detailed system architecture
- **[Best Practices](./docs/best-practices.md)**: DevOps best practices implemented
- **[Troubleshooting Guide](./docs/troubleshooting.md)**: Common issues and solutions

## 🔒 Security Considerations

- All secrets are managed through Kubernetes secrets
- RBAC is implemented across all components
- Network policies restrict inter-pod communication
- Images are scanned for vulnerabilities
- Regular security updates are applied

## 📊 Cost Optimization

- Use Azure Spot instances where appropriate
- Implement auto-scaling for cost efficiency
- Regular cleanup of unused resources
- Monitor and optimize resource allocation

## 🏷️ Version History

- **v1.0.0** - Initial POC implementation
- **v1.1.0** - Added advanced monitoring
- **v1.2.0** - Enhanced security features

## 📞 Support

For questions, issues, or contributions:

- **GitHub Issues**: [Create an issue](https://github.com/suhaib-md/DevOps-POC-Set-1/issues)
- **Email**: suhaib.md@example.com
- **LinkedIn**: [Suhaib MD](https://linkedin.com/in/suhaib-md)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**⭐ If this project helped you, please give it a star on GitHub!**

---

*Last Updated: June 2025*
