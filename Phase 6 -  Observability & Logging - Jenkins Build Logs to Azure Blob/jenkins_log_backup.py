#!/usr/bin/env python3
"""
Jenkins Build Log Backup to Azure Blob Storage
Author: Auto-generated script for log backup automation
"""

import os
import sys
import json
import logging
from datetime import datetime, timedelta
import requests
from requests.auth import HTTPBasicAuth
from azure.storage.blob import BlobServiceClient
import argparse

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('jenkins_backup.log'),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)

class JenkinsLogBackup:
    def __init__(self, config_file='config.json'):
        """Initialize with configuration from file or environment variables"""
        self.config = self.load_config(config_file)
        self.jenkins_url = self.config['jenkins']['url']
        self.jenkins_user = self.config['jenkins']['username']
        self.jenkins_token = self.config['jenkins']['api_token']
        self.azure_connection_string = self.config['azure']['connection_string']
        self.container_name = self.config['azure']['container_name']
        
        # Initialize clients
        self.blob_service_client = BlobServiceClient.from_connection_string(
            self.azure_connection_string
        )
        self.ensure_container_exists()
    
    def load_config(self, config_file):
        """Load configuration from file or environment variables"""
        if os.path.exists(config_file):
            with open(config_file, 'r') as f:
                return json.load(f)
        else:
            # Fallback to environment variables
            return {
                "jenkins": {
                    "url": os.getenv('JENKINS_URL', 'http://localhost:8080'),
                    "username": os.getenv('JENKINS_USERNAME'),
                    "api_token": os.getenv('JENKINS_API_TOKEN')
                },
                "azure": {
                    "connection_string": os.getenv('AZURE_STORAGE_CONNECTION_STRING'),
                    "container_name": os.getenv('AZURE_CONTAINER_NAME', 'jenkins-logs')
                }
            }
    
    def ensure_container_exists(self):
        """Create Azure Blob container if it doesn't exist"""
        try:
            container_client = self.blob_service_client.get_container_client(
                self.container_name
            )
            container_client.create_container()
            logger.info(f"Created container: {self.container_name}")
        except Exception as e:
            if "ContainerAlreadyExists" in str(e):
                logger.info(f"Container {self.container_name} already exists")
            else:
                logger.error(f"Error creating container: {e}")
                raise
    
    def get_jenkins_jobs(self):
        """Get list of all Jenkins jobs"""
        try:
            url = f"{self.jenkins_url}/api/json?tree=jobs[name]"
            response = requests.get(
                url,
                auth=HTTPBasicAuth(self.jenkins_user, self.jenkins_token),
                timeout=30
            )
            response.raise_for_status()
            jobs_data = response.json()
            return [job['name'] for job in jobs_data['jobs']]
        except Exception as e:
            logger.error(f"Error getting Jenkins jobs: {e}")
            raise
    
    def get_job_builds(self, job_name, days_back=7):
        """Get recent builds for a specific job"""
        try:
            url = f"{self.jenkins_url}/job/{job_name}/api/json?tree=builds[number,timestamp,result]"
            response = requests.get(
                url,
                auth=HTTPBasicAuth(self.jenkins_user, self.jenkins_token),
                timeout=30
            )
            response.raise_for_status()
            builds_data = response.json()
            
            # Filter builds from last N days
            cutoff_time = datetime.now() - timedelta(days=days_back)
            cutoff_timestamp = int(cutoff_time.timestamp() * 1000)
            
            recent_builds = [
                build for build in builds_data['builds']
                if build['timestamp'] > cutoff_timestamp
            ]
            
            return recent_builds
        except Exception as e:
            logger.error(f"Error getting builds for job {job_name}: {e}")
            return []
    
    def get_build_log(self, job_name, build_number):
        """Download build log from Jenkins"""
        try:
            url = f"{self.jenkins_url}/job/{job_name}/{build_number}/consoleText"
            response = requests.get(
                url,
                auth=HTTPBasicAuth(self.jenkins_user, self.jenkins_token),
                timeout=60
            )
            response.raise_for_status()
            return response.text
        except Exception as e:
            logger.error(f"Error getting log for {job_name}#{build_number}: {e}")
            return None
    
    def upload_to_azure(self, job_name, build_number, log_content, build_info):
        """Upload log to Azure Blob Storage"""
        try:
            # Create blob name with timestamp
            timestamp = datetime.fromtimestamp(build_info['timestamp'] / 1000)
            blob_name = f"{job_name}/{timestamp.strftime('%Y/%m/%d')}/{job_name}-{build_number}-{timestamp.strftime('%Y%m%d-%H%M%S')}.log"
            
            # Add metadata
            metadata = {
                'job_name': job_name,
                'build_number': str(build_number),
                'build_result': build_info.get('result', 'UNKNOWN'),
                'build_timestamp': str(build_info['timestamp']),
                'upload_timestamp': str(int(datetime.now().timestamp() * 1000))
            }
            
            # Upload to blob
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name,
                blob=blob_name
            )
            
            blob_client.upload_blob(
                log_content,
                overwrite=True,
                metadata=metadata
            )
            
            logger.info(f"Uploaded: {blob_name}")
            return blob_name
        except Exception as e:
            logger.error(f"Error uploading {job_name}#{build_number}: {e}")
            return None
    
    def backup_job_logs(self, job_name, days_back=7):
        """Backup logs for a specific job"""
        logger.info(f"Starting backup for job: {job_name}")
        
        builds = self.get_job_builds(job_name, days_back)
        if not builds:
            logger.info(f"No recent builds found for {job_name}")
            return
        
        uploaded_count = 0
        for build in builds:
            build_number = build['number']
            
            # Check if already uploaded
            timestamp = datetime.fromtimestamp(build['timestamp'] / 1000)
            blob_name = f"{job_name}/{timestamp.strftime('%Y/%m/%d')}/{job_name}-{build_number}-{timestamp.strftime('%Y%m%d-%H%M%S')}.log"
            
            try:
                blob_client = self.blob_service_client.get_blob_client(
                    container=self.container_name,
                    blob=blob_name
                )
                if blob_client.exists():
                    logger.info(f"Skipping {job_name}#{build_number} - already exists")
                    continue
            except:
                pass  # Continue with upload if check fails
            
            # Get and upload log
            log_content = self.get_build_log(job_name, build_number)
            if log_content:
                uploaded_blob = self.upload_to_azure(job_name, build_number, log_content, build)
                if uploaded_blob:
                    uploaded_count += 1
        
        logger.info(f"Completed backup for {job_name}: {uploaded_count} logs uploaded")
    
    def backup_all_jobs(self, days_back=7, job_filter=None):
        """Backup logs for all jobs or filtered jobs"""
        try:
            jobs = self.get_jenkins_jobs()
            
            if job_filter:
                jobs = [job for job in jobs if job_filter.lower() in job.lower()]
            
            logger.info(f"Found {len(jobs)} jobs to backup")
            
            total_uploaded = 0
            for job in jobs:
                try:
                    self.backup_job_logs(job, days_back)
                except Exception as e:
                    logger.error(f"Error backing up job {job}: {e}")
                    continue
            
            logger.info("Backup process completed")
            
        except Exception as e:
            logger.error(f"Error in backup process: {e}")
            raise

def main():
    parser = argparse.ArgumentParser(description='Backup Jenkins logs to Azure Blob Storage')
    parser.add_argument('--job', help='Specific job name to backup')
    parser.add_argument('--days', type=int, default=7, help='Number of days back to backup (default: 7)')
    parser.add_argument('--filter', help='Filter jobs by name pattern')
    parser.add_argument('--config', default='config.json', help='Configuration file path')
    
    args = parser.parse_args()
    
    try:
        backup = JenkinsLogBackup(config_file=args.config)
        
        if args.job:
            backup.backup_job_logs(args.job, args.days)
        else:
            backup.backup_all_jobs(args.days, args.filter)
            
    except Exception as e:
        logger.error(f"Backup failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
