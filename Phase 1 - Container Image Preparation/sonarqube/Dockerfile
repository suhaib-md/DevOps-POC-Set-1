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
    CMD curl -f http://localhost:9000/api/system/status | grep -q '"status":"UP"' || exit 1

# Expose port
EXPOSE 9000

# Volume for data persistence
VOLUME ["/opt/sonarqube/data", "/opt/sonarqube/logs", "/opt/sonarqube/extensions"]
