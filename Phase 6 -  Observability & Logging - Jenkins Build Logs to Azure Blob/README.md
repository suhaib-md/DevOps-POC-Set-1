# Jenkins Build Log Backup to Azure Blob Storage

## Overview

This project provides an automated solution for backing up Jenkins build logs to Azure Blob Storage for long-term storage, analysis, and compliance. The solution supports both manual execution and automated scheduling, making it ideal for DevOps teams who need reliable log archival and retention.

## Features

✅ **Jenkins API Integration** - Secure authentication with Jenkins API  
✅ **Azure Blob Storage Upload** - Robust error handling and retry mechanisms  
✅ **Configurable Retention Policies** - Flexible log retention management  
✅ **Batch Processing** - Efficient handling of multiple builds  
✅ **Comprehensive Logging** - Detailed monitoring and audit trails  
✅ **Multiple Log Format Support** - Console logs, test results, and artifacts  
✅ **Automated Scheduling** - Cron job and systemd service integration  
✅ **Cost Optimization** - Storage tier management and compression  

## Architecture

```
Jenkins Server → Python Script → Azure Blob Storage
     ↓               ↓                    ↓
  API Token    Authentication      Organized Storage
  Build Logs    Error Handling     Metadata & Retention
```

## Prerequisites

### System Requirements
- Python 3.8 or higher
- Jenkins server with API enabled
- Azure subscription and storage account
- Network connectivity to both Jenkins and Azure

### Jenkins Requirements
- Jenkins API enabled
- User account with appropriate permissions
- Build jobs with logs to backup

### Azure Requirements
- Azure Storage Account
- Blob container for log storage
- Appropriate access permissions

## Installation & Setup

### 1. Azure Setup

#### Create Azure Storage Account
```bash
# Login to Azure
az login

# Create resource group (if not exists)
az group create --name jenkins-logs-rg --location eastus

# Create storage account
az storage account create \
  --name jenkinslogsstorage \
  --resource-group jenkins-logs-rg \
  --location eastus \
  --sku Standard_LRS \
  --kind StorageV2

# Create container for logs
az storage container create \
  --name jenkins-build-logs \
  --account-name jenkinslogsstorage \
  --public-access off
```

#### Get Azure Storage Credentials
```bash
# Get storage account connection string
az storage account show-connection-string \
  --name jenkinslogsstorage \
  --resource-group jenkins-logs-rg

# Get storage account key
az storage account keys list \
  --account-name jenkinslogsstorage \
  --resource-group jenkins-logs-rg
```

#### Create Service Principal (Recommended for Production)
```bash
# Create service principal
az ad sp create-for-rbac \
  --name jenkins-logs-uploader \
  --role "Storage Blob Data Contributor" \
  --scopes /subscriptions/{subscription-id}/resourceGroups/jenkins-logs-rg

# Note down the output: appId, password, tenant
```

### 2. Jenkins API Configuration

#### Create Jenkins API Token
1. Login to Jenkins web interface
2. Go to **Manage Jenkins** → **Manage Users**
3. Click your username
4. Click **Security** → **API Token** → **Add new Token**
5. Copy the generated token

#### Test Jenkins API Access
```bash
# Test Jenkins API connection
curl -u admin:your_api_token http://localhost:8080/api/json

# Test specific job access
curl -u admin:your_api_token \
  http://localhost:8080/job/your-job-name/api/json
```

### 3. Project Setup

#### Quick Setup Script
```bash
# Make setup script executable
chmod +x setup.sh

# Run setup script
./setup.sh
```

#### Manual Setup
```bash
# Create project directory
mkdir ~/jenkins-backup
cd ~/jenkins-backup

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Make script executable
chmod +x jenkins_log_backup.py
```

## Configuration

### Configuration File (config.json)
```json
{
  "jenkins": {
    "url": "http://localhost:8080",
    "username": "your_jenkins_username",
    "api_token": "your_jenkins_api_token"
  },
  "azure": {
    "connection_string": "DefaultEndpointsProtocol=https;AccountName=...",
    "container_name": "jenkins-build-logs"
  }
}
```

### Environment Variables (Alternative)
```bash
export JENKINS_URL="http://localhost:8080"
export JENKINS_USERNAME="admin"
export JENKINS_API_TOKEN="your_api_token"
export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=https;..."
export AZURE_CONTAINER_NAME="jenkins-build-logs"
```

## Usage

### Activate Virtual Environment
```bash
cd ~/jenkins-backup
source venv/bin/activate
```

### Basic Usage

#### Backup All Jobs (Last 7 Days)
```bash
python3 jenkins_log_backup.py
```

#### Backup Specific Job
```bash
python3 jenkins_log_backup.py --job "my-project"
```

#### Backup with Custom Time Range
```bash
# Backup last 30 days
python3 jenkins_log_backup.py --days 30

# Backup last day only
python3 jenkins_log_backup.py --days 1
```

#### Filter Jobs by Name Pattern
```bash
python3 jenkins_log_backup.py --filter "frontend"
```

#### Use Custom Configuration File
```bash
python3 jenkins_log_backup.py --config /path/to/config.json
```

### Advanced Usage

#### Test Script
```bash
# Display help
python3 jenkins_log_backup.py --help

# Test with specific job
python3 jenkins_log_backup.py --job "your-job-name" --days 1
```

#### Multiple Log Types
```bash
# Console logs only
python3 jenkins_log_backup.py --job "my-job" --log-types console

# Include test results and artifacts
python3 jenkins_log_backup.py --job "my-job" --log-types console,test-results,artifacts
```

### Command Line Options

| Option | Description | Default |
|--------|-------------|---------|
| `--job` | Specific job name to backup | All jobs |
| `--days` | Number of days back to backup | 7 |
| `--filter` | Filter jobs by name pattern | None |
| `--config` | Path to configuration file | config.json |
| `--help` | Display help message | - |

## Azure Blob Storage Structure

Logs are organized hierarchically in Azure Blob Storage:

```
jenkins-build-logs/
├── job-name-1/
│   ├── 2024/
│   │   ├── 01/
│   │   │   ├── 15/
│   │   │   │   ├── job-name-1_123_20240115143022.log
│   │   │   │   └── job-name-1_124_20240115150145.log
│   │   │   └── 16/
│   │   └── 02/
│   └── 2025/
└── job-name-2/
    └── 2024/
```

### Blob Metadata

Each uploaded log includes comprehensive metadata:
- `job_name` - Jenkins job name
- `build_number` - Build number
- `build_result` - Build result (SUCCESS, FAILURE, etc.)
- `build_timestamp` - Original build timestamp
- `upload_timestamp` - Upload timestamp

## Automation

### 1. Cron Job Setup

```bash
# Edit crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * cd /home/ubuntu/jenkins-backup && ./venv/bin/python jenkins_log_backup.py >> /var/log/jenkins-backup.log 2>&1

# Weekly cleanup (older than 30 days)
0 3 * * 0 cd /home/ubuntu/jenkins-backup && ./venv/bin/python jenkins_log_backup.py --cleanup --older-than 30
```

### 2. Systemd Service (Alternative)

```bash
# Create service file
sudo nano /etc/systemd/system/jenkins-log-backup.service

# Enable and start service
sudo systemctl enable jenkins-log-backup.service
sudo systemctl start jenkins-log-backup.service
```

### 3. Jenkins Pipeline Integration

Add post-build steps to automatically upload logs after each build.

## Monitoring & Troubleshooting

### Log Monitoring
```bash
# View recent logs
tail -f jenkins_backup.log

# Check for errors
grep ERROR jenkins_backup.log

# Monitor upload statistics
python3 jenkins_log_backup.py --stats
```

### Health Checks
```bash
# Check service status
python3 jenkins_log_backup.py --health-check

# Verify Azure connectivity
python3 jenkins_log_backup.py --test-azure

# Check storage usage
python3 jenkins_log_backup.py --storage-info
```

### Common Issues & Solutions

#### Jenkins API Authentication Failed
```bash
# Verify credentials
curl -u username:token http://localhost:8080/api/json
```

#### Azure Blob Upload Failed
```bash
# Check network connectivity
az storage blob list --container-name jenkins-build-logs --account-name jenkinslogsstorage
```

#### Large Log Files
```bash
# Enable compression
python3 jenkins_log_backup.py --job "job-name" --compress --chunk-size 10MB
```

## Best Practices

### Security
- Use environment variables for sensitive data
- Implement proper access controls
- Regular credential rotation
- Enable Azure Storage encryption

### Performance
- Use compression for large logs
- Implement chunked uploads
- Batch processing for multiple files
- Connection pooling

### Monitoring
- Set up alerts for failed uploads
- Monitor storage costs
- Track upload statistics
- Regular health checks

### Maintenance
- Implement log retention policies
- Regular cleanup of old logs
- Monitor storage usage
- Update dependencies regularly

## Cost Optimization

### Azure Storage Tiers
- **Hot tier** - Recent logs (last 30 days)
- **Cool tier** - Older logs (30-90 days)
- **Archive tier** - Long-term retention (90+ days)

### Compression
- Enable gzip compression to reduce storage costs
- Compress logs older than 7 days
- Use efficient compression algorithms

## Compliance & Governance

### Retention Policies
- Implement automated retention policies
- Support for legal hold requirements
- Audit trail for log access
- Data classification and tagging

### Access Control
- Role-based access to logs
- Integration with Azure AD
- Audit logging for access
- Encryption in transit and at rest

## Project Structure

```
jenkins-backup/
├── jenkins_log_backup.py     # Main backup script
├── requirements.txt          # Python dependencies
├── config.json              # Configuration file
├── setup.sh                 # Environment setup script
├── README.md                # This file
├── logs/                    # Local log files
└── venv/                    # Python virtual environment
```

## Dependencies

The project uses the following Python packages (see `requirements.txt`):
- `requests==2.31.0` - HTTP requests for Jenkins API
- `azure-storage-blob==12.19.0` - Azure Blob Storage client
- `python-dateutil==2.8.2` - Date/time utilities

## Deliverables

This project includes all required deliverables:

1. **✅ Script File** - `jenkins_log_backup.py` (Python-based)
2. **✅ Requirements File** - `requirements.txt` with all dependencies
3. **✅ Setup Script** - `setup.sh` for automated environment setup
4. **✅ Configuration** - `config.json` with Jenkins API authentication and Azure Blob upload settings
5. **✅ Documentation** - This comprehensive README.md with:
   - Complete setup instructions
   - Usage examples
   - Troubleshooting guide
   - Best practices
   - Project information

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License. See LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Review the logs for error messages
3. Verify configuration settings
4. Test connectivity to Jenkins and Azure
5. Create an issue with detailed error information

---

**Note**: This solution is designed for production use with proper error handling, logging, and security considerations. Always test in a development environment before deploying to production.
