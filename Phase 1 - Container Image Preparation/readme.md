# DevOps Containers - Phase 1: Container Image Preparation

**Author:** Vadakathi Muhammed Suhaib  
**Role:** Technical Apprentice  
**Employee ID:** X48GRSTML  
**Email:** muhammed.suhaib@cprime.com

## Overview

This project provides step-by-step instructions for creating secure and production-ready Docker images for Jenkins, Nexus, and SonarQube, then pushing them to Azure Container Registry (ACR).

## Table of Contents

- [Prerequisites](#prerequisites)
- [Environment Setup](#environment-setup)
- [Jenkins Container](#jenkins-container)
- [Nexus Container](#nexus-container)
- [SonarQube Container](#sonarqube-container)
- [ACR Push Steps](#acr-push-steps)
- [Verification](#verification)
- [Security Considerations](#security-considerations)
- [Optimization Notes](#optimization-notes)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before starting, ensure you have:

- Docker installed and running
- Azure CLI installed and configured
- Access to Azure Container Registry
- Basic knowledge of Docker and containerization

## Environment Setup

### 1. Create Project Directory Structure

```bash
mkdir devops-containers
cd devops-containers
mkdir jenkins nexus sonarqube
```

### 2. Install Required Tools

#### Install Azure CLI (Ubuntu/Debian)
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

#### Install Docker (Ubuntu/Debian)
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

### 3. Azure Container Registry Setup

1. Create a Container Registry in Azure Portal and note the name
2. Login to Azure and ACR:

```bash
az login
az acr login --name <your-acr-name>
```

### 4. Set Environment Variables

```bash
export ACR_NAME="acr786"
export ACR_LOGIN_SERVER="$ACR_NAME.azurecr.io"
export RESOURCE_GROUP="acr"
```

## Jenkins Container

### Build Instructions

1. **Navigate to Jenkins directory:**
   ```bash
   cd jenkins
   ```

2. **Create Dockerfile:**
   ```dockerfile
   # Jenkins Dockerfile - Production Ready
   FROM jenkins/jenkins:lts-jdk17
   
   # Switch to root to install packages
   USER root
   
   # Install additional tools and clean up in single layer
   RUN apt-get update && apt-get install -y git curl && \
       apt-get clean && rm -rf /var/lib/apt/lists/*
   
   # Switch back to jenkins user
   USER jenkins
   
   # Copy plugins list and install plugins
   COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
   RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt
   
   # Health check
   HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
       CMD curl -f http://localhost:8080/login || exit 1
   
   # Expose port
   EXPOSE 8080 50000
   ```

3. **Create plugins.txt file:**
   ```txt
   # Jenkins Essential Plugins List
   # Build Tools
   gradle:latest
   maven-plugin:latest
   # SCM
   git:latest
   github:latest
   github-branch-source:latest
   bitbucket:latest
   # Pipeline
   workflow-aggregator:latest
   pipeline-stage-view:latest
   ```

4. **Build Jenkins image:**
   ```bash
   docker build -t jenkins-custom:latest .
   ```

## Nexus Container

### Build Instructions

1. **Navigate to Nexus directory:**
   ```bash
   cd ../nexus
   ```

2. **Create Dockerfile:**
   ```dockerfile
   # Nexus Repository Manager Dockerfile - Production Ready
   FROM sonatype/nexus3:3.45.0
   
   # Switch to root for setup
   USER root
   
   # Create nexus data directory with proper permissions
   RUN mkdir -p /nexus-data/etc && \
       chown -R nexus:nexus /nexus-data
   
   # Switch back to nexus user
   USER nexus
   
   # Configure Nexus properties
   ENV NEXUS_SECURITY_RANDOMPASSWORD=false
   
   # Health check
   HEALTHCHECK --interval=30s --timeout=15s --start-period=10m --retries=3 \
       CMD curl -f http://localhost:8081/service/rest/v1/status || exit 1
   
   # Expose ports
   EXPOSE 8081
   
   # Volume for data persistence
   VOLUME ["/nexus-data"]
   ```

3. **Build Nexus image:**
   ```bash
   docker build -t nexus-custom:latest .
   ```

## SonarQube Container

### Build Instructions

1. **Navigate to SonarQube directory:**
   ```bash
   cd ../sonarqube
   ```

2. **Create Dockerfile:**
   ```dockerfile
   # SonarQube Dockerfile - Production Ready
   FROM sonarqube:10.3-community
   
   # Switch to root for setup
   USER root
   
   # Create necessary directories
   RUN mkdir -p /opt/sonarqube/conf && \
       mkdir -p /opt/sonarqube/data && \
       mkdir -p /opt/sonarqube/logs && \
       mkdir -p /opt/sonarqube/extensions/plugins && \
       chown -R sonarqube:sonarqube /opt/sonarqube
   
   # Switch back to sonarqube user
   USER sonarqube
   
   # Configure SonarQube
   ENV SONAR_WEB_HOST="0.0.0.0"
   ENV SONAR_WEB_PORT="9000"
   ENV SONAR_WEB_CONTEXT=""
   
   # Health check
   HEALTHCHECK --interval=30s --timeout=15s --start-period=5m --retries=3 \
       CMD curl -f http://localhost:9000/api/system/status | grep -q '"status":"UP"'
   
   # Expose port
   EXPOSE 9000
   
   # Volume for data persistence
   VOLUME ["/opt/sonarqube/data", "/opt/sonarqube/logs", "/opt/sonarqube/extensions"]
   ```

3. **Build SonarQube image:**
   ```bash
   docker build -t sonarqube-custom:latest .
   ```

## ACR Push Steps

### Tag and Push Images to Azure Container Registry

1. **Jenkins:**
   ```bash
   docker tag jenkins-custom:latest $ACR_LOGIN_SERVER/jenkins-custom:latest
   docker push $ACR_LOGIN_SERVER/jenkins-custom:latest
   ```

2. **Nexus:**
   ```bash
   docker tag nexus-custom:latest $ACR_LOGIN_SERVER/nexus-custom:latest
   docker push $ACR_LOGIN_SERVER/nexus-custom:latest
   ```

3. **SonarQube:**
   ```bash
   docker tag sonarqube-custom:latest $ACR_LOGIN_SERVER/sonarqube-custom:latest
   docker push $ACR_LOGIN_SERVER/sonarqube-custom:latest
   ```

![alt text](<Screenshot 2025-06-02 124843.png>)
![alt text](<Screenshot 2025-06-02 130123.png>)
![alt text](<Screenshot 2025-06-02 131206.png>)
![alt text](<Screenshot 2025-06-02 131228.png>)

## Verification

### Verify Images in ACR

1. **List all repositories:**
   ```bash
   az acr repository list --name $ACR_NAME --output table
   ```

![alt text](<Screenshot 2025-06-02 131300.png>)

2. **Check image tags:**
   ```bash
   az acr repository show-tags --name $ACR_NAME --repository jenkins-custom --output table
   az acr repository show-tags --name $ACR_NAME --repository nexus-custom --output table
   az acr repository show-tags --name $ACR_NAME --repository sonarqube-custom --output table
   ```

![alt text](<Screenshot 2025-06-02 131410.png>)

## Security Considerations

### Image Security Best Practices Applied

- **Non-root users:** All containers run with dedicated non-root users
- **Minimal base images:** Using official slim variants where possible
- **Layer optimization:** Commands combined to reduce layers
- **Secret management:** No hardcoded secrets in images
- **Vulnerability scanning:** Regular base image updates

### Security Scanning Commands

```bash
# Scan images for vulnerabilities
docker scout cves jenkins-custom:latest
docker scout cves nexus-custom:latest
docker scout cves sonarqube-custom:latest
```

## Optimization Notes

### Size Optimization

- Multi-stage builds used where applicable
- Package cache cleanup in same RUN layer
- Only essential packages installed
- Unused files and directories removed

### Performance Optimization

- Pre-configured with optimal JVM settings
- Essential plugins/repositories pre-installed
- Proper health checks implemented

## Troubleshooting

### Common Issues and Solutions

#### Build failures due to network timeouts:
```bash
docker build --network=host -t image-name .
```

#### Permission issues:
```bash
# Ensure proper user permissions in Dockerfile
# Use --chown flag in COPY commands
```

#### ACR authentication issues:
```bash
az acr login --name $ACR_NAME
# Or use service principal authentication
```

#### Large image sizes:
```bash
# Use docker system prune to clean up
docker system prune -a

# Analyze image layers
docker history image-name:latest
```

## Project Structure

```
devops-containers/
├── README.md
├── jenkins/
│   ├── Dockerfile
│   └── plugins.txt
├── nexus/
│   └── Dockerfile
└── sonarqube/
    └── Dockerfile
```

## Notes

- Ensure all environment variables are properly set before running commands
- Regular updates of base images are recommended for security
- Monitor container resource usage in production environments
- Implement proper backup strategies for persistent data volumes

---

**Created by:** Vadakathi Muhammed Suhaib  
**Last Updated:** Phase 1 Container Image Preparation