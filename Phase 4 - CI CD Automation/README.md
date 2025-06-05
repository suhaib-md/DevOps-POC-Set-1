# Jenkins CI/CD Pipeline for Spring Boot Application

## Overview
This project demonstrates a complete CI/CD automation setup using Jenkins, Maven, and Nexus Repository for a Hello World Spring Boot application. The pipeline automates build, test, and artifact deployment processes.

## 🎯 Objectives
- Set up a complete CI/CD environment with Jenkins and Nexus
- Create a Jenkins pipeline for automated build, test, and deployment
- Implement artifact management using Nexus Repository
- Demonstrate best practices for Spring Boot CI/CD automation

## 📋 Prerequisites
- Ubuntu/Debian-based Linux system (or compatible)
- Sudo access
- Internet connection for downloading packages
- Basic knowledge of Jenkins, Maven, and Spring Boot

## 🛠️ Environment Setup

### 1. System Preparation
```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install required dependencies
sudo apt install -y curl wget gnupg2 software-properties-common apt-transport-https ca-certificates lsb-release
```

### 2. Java Installation
```bash
# Install OpenJDK 17
sudo apt install -y openjdk-17-jdk openjdk-17-jre

# Verify installation
java -version
javac -version

# Set JAVA_HOME environment variable
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> ~/.bashrc
source ~/.bashrc
```

### 3. Maven Installation
```bash
# Install Maven
sudo apt install -y maven

# Verify installation
mvn -version
```

## 🔧 Jenkins Installation & Configuration

### 1. Install Jenkins
```bash
# Add Jenkins repository key
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Add Jenkins repository
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list and install Jenkins
sudo apt-get update
sudo apt-get install jenkins

# Start Jenkins service
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

### 2. Initial Jenkins Setup
```bash
# Get initial admin password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

Access Jenkins at `http://localhost:8080` and complete the setup wizard.

### 3. Required Jenkins Plugins
Install the following plugins via **Manage Jenkins → Manage Plugins**:
- Maven Integration Plugin
- Nexus Artifact Uploader
- Pipeline Plugin
- Git Plugin
- Email Extension Plugin
- JUnit Plugin
- Pipeline Utility Steps

### 4. Configure Global Tools
Navigate to **Manage Jenkins → Global Tool Configuration**:

**JDK Configuration:**
- Name: `OpenJDK17`
- JAVA_HOME: `/usr/lib/jvm/java-17-openjdk-amd64`

**Maven Configuration:**
- Name: `Maven-3.9.0`
- Install automatically or set MAVEN_HOME

## 📦 Nexus Repository Installation

### 1. Create Nexus User
```bash
sudo useradd -m -d /opt/nexus -s /bin/bash nexus
sudo passwd nexus  # Set password (e.g., 'root')
```

### 2. Download and Install Nexus
```bash
cd /tmp
wget https://download.sonatype.com/nexus/3/nexus-3.80.0-06-linux-x86_64.tar.gz
sudo tar -xzf nexus-3.80.0-06-linux-x86_64.tar.gz -C /opt/
sudo mv /opt/nexus-3* /opt/nexus
sudo chown -R nexus:nexus /opt/nexus
sudo chown -R nexus:nexus /opt/sonatype-work
```

### 3. Configure Nexus as Service
```bash
sudo nano /etc/systemd/system/nexus.service
```

Add the following content:
```ini
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort
TimeoutSec=600

[Install]
WantedBy=multi-user.target
```

### 4. Start Nexus Service
```bash
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus
sudo systemctl status nexus
```

### 5. Access Nexus
- URL: `http://localhost:8081`
- Username: `admin`
- Password: Check `/opt/sonatype-work/nexus3/admin.password`

```bash
sudo cat /opt/sonatype-work/nexus3/admin.password
```

## 🚀 Spring Boot Application Setup

### 1. Create Project Structure
```bash
mkdir -p ~/jenkins-projects/hello-world-spring-boot
cd ~/jenkins-projects/hello-world-spring-boot
```

### 2. Initialize Maven Project
```bash
mvn archetype:generate \
  -DgroupId=com.example \
  -DartifactId=hello-world-spring-boot \
  -DarchetypeArtifactId=maven-archetype-quickstart \
  -DinteractiveMode=false

cd hello-world-spring-boot
```

### 3. Project Files

#### pom.xml
```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>
    
    <parent>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-parent</artifactId>
        <version>3.2.0</version>
        <relativePath/>
    </parent>
    
    <groupId>com.example</groupId>
    <artifactId>hello-world-spring-boot</artifactId>
    <version>1.0.0-SNAPSHOT</version>
    <packaging>jar</packaging>
    <name>hello-world-spring-boot</name>
    <description>Hello World Spring Boot Application</description>
    
    <properties>
        <java.version>17</java.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
    </properties>
    
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
        </dependency>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-test</artifactId>
            <scope>test</scope>
        </dependency>
        <dependency>
            <groupId>org.junit.jupiter</groupId>
            <artifactId>junit-jupiter</artifactId>
            <scope>test</scope>
        </dependency>
    </dependencies>
    
    <build>
        <plugins>
            <plugin>
                <groupId>org.springframework.boot</groupId>
                <artifactId>spring-boot-maven-plugin</artifactId>
            </plugin>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-surefire-plugin</artifactId>
                <version>3.0.0-M9</version>
            </plugin>
        </plugins>
    </build>
    
    <distributionManagement>
        <repository>
            <id>nexus-releases</id>
            <name>Nexus Release Repository</name>
            <url>http://localhost:8081/repository/maven-releases/</url>
        </repository>
        <snapshotRepository>
            <id>nexus-snapshots</id>
            <name>Nexus Snapshot Repository</name>
            <url>http://localhost:8081/repository/maven-snapshots/</url>
        </snapshotRepository>
    </distributionManagement>
</project>
```

#### Main Application Class
Create `src/main/java/com/example/helloworldspringboot/HelloWorldApplication.java`:
```java
package com.example.helloworldspringboot;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@SpringBootApplication
@RestController
public class HelloWorldApplication {

    public static void main(String[] args) {
        SpringApplication.run(HelloWorldApplication.class, args);
    }

    @GetMapping("/")
    public String hello() {
        return "Hello World from Spring Boot!";
    }

    @GetMapping("/health")
    public String health() {
        return "Application is running!";
    }
}
```

#### Test Class
Create `src/test/java/com/example/helloworldspringboot/HelloWorldApplicationTest.java`:
```java
package com.example.helloworldspringboot;

import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

@SpringBootTest
@SpringJUnitConfig
class HelloWorldApplicationTest {

    @Test
    void contextLoads() {
        // Test that Spring context loads successfully
    }
}
```

## 🔄 Jenkins Pipeline Configuration

### 1. Jenkinsfile
Create `Jenkinsfile` in the project root:

```groovy
pipeline {
    agent any
    
    tools {
        maven 'Maven-3.9.0'
        jdk 'OpenJDK17'
    }
    
    environment {
        // Nexus configuration
        NEXUS_VERSION = "nexus3"
        NEXUS_PROTOCOL = "http"
        NEXUS_URL = "localhost:8081"
        NEXUS_REPOSITORY = "maven-snapshots"
        NEXUS_CREDENTIAL_ID = "nexus-credentials"
        GITHUB_REPO = "https://github.com/yourusername/jenkins_springboot_nexus.git"
        
        // POM details
        ARTIFACT_ID = "hello-world-spring-boot"
        GROUP_ID = "com.example"
        VERSION = "1.0.0-SNAPSHOT"
        PACKAGING = "jar"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code from GitHub...'
                git branch: 'main', url: "${GITHUB_REPO}"
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building the application...'
                sh 'mvn clean compile'
            }
        }
        
        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'mvn test'
            }
            post {
                always {
                    junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }
        
        stage('Package') {
            steps {
                echo 'Packaging the application...'
                sh 'mvn package -DskipTests'
            }
            post {
                success {
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Deploy to Nexus') {
            steps {
                echo 'Deploying artifacts to Nexus...'
                script {
                    def repositoryName = VERSION.endsWith("SNAPSHOT") ? "maven-snapshots" : "maven-releases"
                    def artifactPath = "target/${ARTIFACT_ID}-${VERSION}.${PACKAGING}"
                    
                    if (!fileExists(artifactPath)) {
                        error "Artifact file not found: ${artifactPath}"
                    }
                    
                    nexusArtifactUploader(
                        nexusVersion: NEXUS_VERSION,
                        protocol: NEXUS_PROTOCOL,
                        nexusUrl: NEXUS_URL,
                        groupId: GROUP_ID,
                        version: VERSION,
                        repository: repositoryName,
                        credentialsId: NEXUS_CREDENTIAL_ID,
                        artifacts: [
                            [
                                artifactId: ARTIFACT_ID,
                                classifier: '',
                                file: artifactPath,
                                type: PACKAGING
                            ],
                            [
                                artifactId: ARTIFACT_ID,
                                classifier: '',
                                file: "pom.xml",
                                type: "pom"
                            ]
                        ]
                    )
                    echo "Artifact deployed successfully to Nexus"
                }
            }
        }
        
        stage('Integration Tests') {
            steps {
                echo 'Running integration tests...'
                sh 'mvn verify -DskipUTs'
            }
        }
    }
    
    post {
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
        success {
            echo 'Pipeline executed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### 2. Configure Jenkins Credentials
1. Go to **Manage Jenkins → Manage Credentials → Global**
2. Add new credentials:
   - **Kind**: Username with password
   - **ID**: `nexus-credentials`
   - **Username**: `admin`
   - **Password**: [Nexus admin password]

### 3. Configure Maven Settings
Create `~/.m2/settings.xml`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
          http://maven.apache.org/xsd/settings-1.0.0.xsd">
    
    <servers>
        <server>
            <id>nexus-releases</id>
            <username>admin</username>
            <password>your-nexus-password</password>
        </server>
        <server>
            <id>nexus-snapshots</id>
            <username>admin</username>
            <password>your-nexus-password</password>
        </server>
    </servers>
    
    <mirrors>
        <mirror>
            <id>nexus-public</id>
            <mirrorOf>*</mirrorOf>
            <url>http://localhost:8081/repository/maven-public/</url>
        </mirror>
    </mirrors>
</settings>
```

## 🎯 Creating and Running the Pipeline

### 1. Create Jenkins Pipeline Job
1. Go to Jenkins Dashboard
2. Click **New Item**
3. Enter name: `hello-world-spring-boot-pipeline`
4. Select **Pipeline**
5. Click **OK**

### 2. Configure Pipeline
**Option A: Pipeline from SCM**
- Under Pipeline section, select **Pipeline script from SCM**
- Choose **Git** as SCM
- Enter repository URL: `https://github.com/yourusername/jenkins_springboot_nexus.git`
- Set branch to `/main`
- Script Path: `Jenkinsfile`

**Option B: Direct Script**
- Select **Pipeline script**
- Paste the Jenkinsfile content directly

### 3. Initialize Git Repository
```bash
git init
git add .
git commit -m "Initial commit with Spring Boot Hello World application"
git branch -M main
git remote add origin https://github.com/yourusername/jenkins_springboot_nexus.git
git push -u origin main
```

## 🧪 Testing and Verification

### 1. Test Spring Boot Application Locally
```bash
cd ~/jenkins-projects/hello-world-spring-boot

# Run tests
mvn clean test

# Start application
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8087

# Test endpoints
curl http://localhost:8087/
curl http://localhost:8087/health
```

### 2. Test Maven Deploy to Nexus
```bash
mvn clean deploy
```

### 3. Run Jenkins Pipeline
1. Go to Jenkins dashboard
2. Click on your pipeline job
3. Click **Build Now**
4. Monitor build progress in **Console Output**

### 4. Verify Artifacts in Nexus
1. Go to Nexus web interface (`http://localhost:8081`)
2. Navigate to **Browse → maven-snapshots**
3. Look for `com/example/hello-world-spring-boot`

## 🔧 Troubleshooting

### Common Issues and Solutions

#### 1. Jenkins Permission Issues
```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

#### 2. Maven Not Found
- Ensure Maven is properly configured in Jenkins Global Tools
- Check MAVEN_HOME environment variable

#### 3. Nexus Connection Issues
```bash
# Check if Nexus is running
sudo systemctl status nexus
sudo netstat -tlnp | grep 8081
```

#### 4. Java Version Issues
```bash
# Ensure consistent Java versions
update-alternatives --config java
```

#### 5. Port Conflicts
- **Jenkins**: Edit `/etc/default/jenkins` and change `HTTP_PORT`
- **Nexus**: Edit `/opt/nexus/etc/nexus-default.properties`

### Verification Commands
```bash
# Check services status
sudo systemctl status jenkins
sudo systemctl status nexus

# Check ports
sudo netstat -tlnp | grep 8080  # Jenkins
sudo netstat -tlnp | grep 8081  # Nexus

# Check logs
sudo journalctl -u jenkins -f
sudo journalctl -u nexus -f
```

## 📁 Deliverables

### 1. Jenkinsfile ✅
- Located in project root
- Implements complete CI/CD pipeline
- Includes build, test, package, and deploy stages

### 2. Spring Boot Application ✅
- Hello World REST API
- Maven-based project structure
- Unit tests included
- Health check endpoint

### 3. Nexus Repository Configuration ✅
- Automated artifact deployment
- Snapshot and release repositories
- Proper authentication setup

## 🏆 Best Practices

- **Security**: Use proper credentials management
- **Backup**: Regular backup of Jenkins and Nexus data
- **Monitoring**: Set up monitoring for services
- **Updates**: Keep Jenkins and plugins updated
- **Testing**: Always test pipeline changes in staging first

## 📝 Additional Resources

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Spring Boot Documentation](https://spring.io/projects/spring-boot)
- [Nexus Repository Documentation](https://help.sonatype.com/repomanager3)
- [Maven Documentation](https://maven.apache.org/guides/)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

**Note**: Replace `yourusername` with your actual GitHub username and adjust URLs accordingly. Ensure all services are properly configured and running before executing the pipeline.