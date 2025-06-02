# DevOps Containers - Production-Ready Docker Images

This repository contains production-ready Docker images for Jenkins, Nexus Repository Manager, and SonarQube, optimized for deployment in Azure Container Registry (ACR).

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Environment Setup](#environment-setup)
- [Build Instructions](#build-instructions)
- [ACR Push Steps](#acr-push-steps)
- [Image Details](#image-details)
- [Security & Optimization Notes](#security--optimization-notes)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This project provides secure, production-ready Docker images for:
- **Jenkins**: CI/CD automation server with essential plugins and Configuration as Code
- **Nexus**: Artifact repository manager with Maven and Docker repositories
- **SonarQube**: Code quality and security analysis platform

All images are optimized for production use with proper security configurations, performance tuning, and health checks.

## 📋 Prerequisites

- Docker installed and running
- Azure CLI installed and configured
- Access to Azure Container Registry
- Basic knowledge of Docker and containerization

### Installation Commands (Ubuntu/Debian)

```bash
# Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

## 📁 Project Structure

```
devops-containers/
├── jenkins/
│   ├── Dockerfile
│   ├── plugins.txt
│   └── jenkins.yaml
├── nexus/
│   ├── Dockerfile
│   ├── nexus.properties
│   └── scripts/
│       └── nexus-init.groovy
├── sonarqube/
│   ├── Dockerfile
│   └── sonar.properties
└── README.md
```

## 🚀 Environment Setup

1. **Create project directory structure:**
```bash
mkdir devops-containers
cd devops-containers
mkdir jenkins nexus sonarqube
```

2. **Create Azure Container Registry** in Azure Portal and note the name

3. **Login to Azure and ACR:**
```bash
az login
az acr login --name <your-acr-name>
```

4. **Set environment variables:**
```bash
export ACR_NAME="acr786"
export ACR_LOGIN_SERVER="$ACR_NAME.azurecr.io"
export RESOURCE_GROUP="acr"
```

## 🔨 Build Instructions

### Jenkins Image Build

1. **Navigate to Jenkins directory:**
```bash
cd jenkins
```

2. **Create required files:**
   - `Dockerfile` (production-ready with JDK 17)
   - `plugins.txt` (essential Jenkins plugins)
   - `jenkins.yaml` (Configuration as Code)

3. **Build Jenkins image:**
```bash
docker build -t jenkins-custom:latest .
```

**Key Features:**
- Based on `jenkins/jenkins:lts-jdk17`
- Includes Docker CLI, kubectl, Azure CLI
- Pre-installed essential plugins
- Configuration as Code setup
- Production JVM settings
- Health checks implemented

### Nexus Image Build

1. **Navigate to Nexus directory:**
```bash
cd ../nexus
```

2. **Create required files:**
   - `Dockerfile` (based on sonatype/nexus3)
   - `nexus.properties` (production configuration)
   - `scripts/nexus-init.groovy` (repository setup)

3. **Build Nexus image:**
```bash
docker build -t nexus-custom:latest .
```

**Key Features:**
- Based on `sonatype/nexus3:3.45.0`
- Pre-configured Maven and Docker repositories
- Production JVM settings
- Automated repository initialization
- Proper volume configuration

### SonarQube Image Build

1. **Navigate to SonarQube directory:**
```bash
cd ../sonarqube
```

2. **Create required files:**
   - `Dockerfile` (based on sonarqube:10.3-community)
   - `sonar.properties` (production configuration)

3. **Build SonarQube image:**
```bash
docker build -t sonarqube-custom:latest .
```

**Key Features:**
- Based on `sonarqube:10.3-community`
- Production-ready configuration
- Optimized JVM settings
- Multiple language support
- Quality gate configurations

## 📤 ACR Push Steps

### Tag and Push Jenkins
```bash
docker tag jenkins-custom:latest $ACR_LOGIN_SERVER/jenkins-custom:latest
docker push $ACR_LOGIN_SERVER/jenkins-custom:latest
```
![alt text](<Screenshot 2025-06-02 124843.png>)
### Tag and Push Nexus
```bash
docker tag nexus-custom:latest $ACR_LOGIN_SERVER/nexus-custom:latest
docker push $ACR_LOGIN_SERVER/nexus-custom:latest
```
![alt text](<Screenshot 2025-06-02 130123.png>)

### Tag and Push SonarQube
```bash
docker tag sonarqube-custom:latest $ACR_LOGIN_SERVER/sonarqube-custom:latest
docker push $ACR_LOGIN_SERVER/sonarqube-custom:latest
```
![alt text](<Screenshot 2025-06-02 131206.png>)


![alt text](<Screenshot 2025-06-02 131228.png>)
![alt text](<Screenshot 2025-06-02 131300.png>)
![alt text](<Screenshot 2025-06-02 131410.png>)

## 📊 Image Details

| Image | Base Image | Size Optimization | Key Components |
|-------|------------|-------------------|----------------|
| Jenkins | jenkins/jenkins:lts-jdk17 | Multi-layer optimization | Docker CLI, kubectl, Azure CLI, 30+ plugins |
| Nexus | sonatype/nexus3:3.45.0 | Minimal layer approach | Maven/Docker repos, init scripts |
| SonarQube | sonarqube:10.3-community | Layer consolidation | Multi-language support, quality gates |

## 🔐 Security & Optimization Notes

### Security Best Practices Applied

#### ✅ Non-Root Users
- All containers run with dedicated non-root users
- Jenkins: `jenkins` user
- Nexus: `nexus` user  
- SonarQube: `sonarqube` user

#### ✅ Minimal Base Images
- Using official, maintained base images
- Only essential packages installed
- Regular security updates applied

#### ✅ Layer Optimization
- Commands combined to reduce layers
- Package cache cleanup in same RUN layer
- Unused files and directories removed

#### ✅ Secret Management
- No hardcoded secrets in images
- Environment variable support for credentials
- Configuration externalization

#### ✅ Health Checks
```dockerfile
# Jenkins Health Check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
CMD curl -f http://localhost:8080/login || exit 1

# Nexus Health Check  
HEALTHCHECK --interval=30s --timeout=15s --start-period=10m --retries=3 \
CMD curl -f http://localhost:8081/service/rest/v1/status || exit 1

# SonarQube Health Check
HEALTHCHECK --interval=30s --timeout=15s --start-period=5m --retries=3 \
CMD curl -f http://localhost:9000/api/system/status | grep -q '"status":"UP"'
```

### Performance Optimizations

#### 🚀 JVM Tuning
```bash
# Jenkins
JAVA_OPTS="-Xmx2g -Xms1g -XX:+UseG1GC -XX:+UseContainerSupport"

# Nexus
INSTALL4J_ADD_VM_PARAMS="-Xms2g -Xmx2g -XX:MaxDirectMemorySize=3g"

# SonarQube
SQ_JAVA_OPTS="-Xmx2g -Xms1g -XX:+UseG1GC -XX:+UseContainerSupport"
```

#### 🚀 Pre-Configuration
- Essential plugins/repositories pre-installed
- Optimized default configurations
- Ready-to-use setup with minimal post-deployment configuration

#### 🚀 Size Optimization
- Multi-stage builds where applicable
- Package manager cache cleanup
- Layer consolidation techniques

### Security Scanning

Run vulnerability scans on built images:
```bash
# Scan images for vulnerabilities
docker scout cves jenkins-custom:latest
docker scout cves nexus-custom:latest  
docker scout cves sonarqube-custom:latest
```

## ✅ Verification

### Verify Images in ACR
```bash
# List all repositories
az acr repository list --name $ACR_NAME --output table

# Check specific image tags
az acr repository show-tags --name $ACR_NAME --repository jenkins-custom --output table
az acr repository show-tags --name $ACR_NAME --repository nexus-custom --output table
az acr repository show-tags --name $ACR_NAME --repository sonarqube-custom --output table
```

### Local Testing
```bash
# Test Jenkins locally
docker run -d -p 8080:8080 -p 50000:50000 --name jenkins-test jenkins-custom:latest

# Test Nexus locally  
docker run -d -p 8081:8081 --name nexus-test nexus-custom:latest

# Test SonarQube locally
docker run -d -p 9000:9000 --name sonarqube-test sonarqube-custom:latest
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### Build Failures Due to Network Timeouts
```bash
docker build --network=host -t image-name .
```

#### Permission Issues
```bash
# Ensure proper user permissions in Dockerfile
# Use --chown flag in COPY commands
COPY --chown=jenkins:jenkins jenkins.yaml /var/jenkins_home/casc_configs/
```

#### ACR Authentication Issues
```bash
# Re-authenticate with ACR
az acr login --name $ACR_NAME

# Or use service principal authentication
az login --service-principal --username $SP_ID --password $SP_PASSWORD --tenant $TENANT_ID
```

#### Large Image Sizes
```bash
# Clean up Docker system
docker system prune -a

# Analyze image layers
docker history image-name:latest

# Check image size
docker images | grep custom
```

#### Container Startup Issues
```bash
# Check container logs
docker logs container-name

# Inspect container configuration
docker inspect container-name

# Check health status
docker ps --format "table {{.Names}}\t{{.Status}}"
```

## 📝 Configuration Files

### Default Credentials
- **Jenkins**: admin/admin123 (configurable via environment variables)
- **Nexus**: admin/admin123 (change on first login)
- **SonarQube**: admin/admin (change on first login)

### Ports
- **Jenkins**: 8080 (web), 50000 (agent)
- **Nexus**: 8081 (web), 8082 (Docker registry)
- **SonarQube**: 9000 (web)

### Volumes
- **Jenkins**: `/var/jenkins_home`
- **Nexus**: `/nexus-data`
- **SonarQube**: `/opt/sonarqube/data`, `/opt/sonarqube/logs`, `/opt/sonarqube/extensions`

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For issues and questions:
- Create an issue in this repository
- Contact: muhammed.suhaib@cprime.com

---

**Author**: Vadakathi Muhammed Suhaib  
**Role**: Technical Apprentice  
**Emp ID**: X48GRSTML