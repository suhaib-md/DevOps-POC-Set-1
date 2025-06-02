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
