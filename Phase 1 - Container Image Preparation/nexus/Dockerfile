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

