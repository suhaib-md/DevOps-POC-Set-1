#!/bin/bash

# Jenkins Log Backup Setup Script for Debian WSL
# This script sets up the environment for backing up Jenkins logs to Azure

set -e

echo "🚀 Setting up Jenkins Log Backup to Azure..."

# Update system packages
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Python3 and pip if not installed
echo "🐍 Installing Python3 and pip..."
sudo apt install -y python3 python3-pip python3-venv

# Create project directory
PROJECT_DIR="$HOME/jenkins-backup"
echo "📁 Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create virtual environment
echo "🏗️ Creating Python virtual environment..."
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
echo "📚 Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

# Make script executable
chmod +x jenkins_log_backup.py

# Create logs directory
mkdir -p logs

echo "✅ Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Edit config.json with your Jenkins and Azure credentials"
echo "2. Activate virtual environment: source $PROJECT_DIR/venv/bin/activate"
echo "3. Test the script: python3 jenkins_log_backup.py --help"
echo ""
echo "🔧 Configuration needed:"
echo "- Jenkins URL, username, and API token"
echo "- Azure Storage connection string"
echo "- Container name (optional, defaults to 'jenkins-logs')"
