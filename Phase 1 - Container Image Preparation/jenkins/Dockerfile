# Jenkins Dockerfile - Production Ready
FROM jenkins/jenkins:lts-jdk17

# Switch to root to install packages
USER root

# Install additional tools and clean up in single layer
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        wget \
        git \
        unzip \
        ca-certificates \
        apt-transport-https \
        gnupg \
        lsb-release && \
    # Install Docker CLI
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update && \
    apt-get install -y docker-ce-cli && \
    # Install kubectl
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl && \
    # Clean up
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install Azure CLI
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    rm -rf /var/lib/apt/lists/*

# Switch back to jenkins user
USER jenkins

# Skip initial setup wizard
ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"
ENV JENKINS_OPTS="--httpPort=8080 --httpsPort=-1"

# Copy plugins list and install plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugin-file /usr/share/jenkins/ref/plugins.txt

# Copy custom configuration
COPY --chown=jenkins:jenkins jenkins.yaml /var/jenkins_home/casc_configs/jenkins.yaml

# Set JVM options for production
ENV JAVA_OPTS="-Xmx2g -Xms1g -XX:+UseG1GC -XX:+UseContainerSupport -Djenkins.install.runSetupWizard=false"

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
    CMD curl -f http://localhost:8080/login || exit 1

# Expose port
EXPOSE 8080 50000

# Use default entrypoint from base image
