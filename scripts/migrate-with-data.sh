#!/bin/bash

# Complete migration with data backup and restore
set -e

echo "🌐 Multi-Cloud Migration with Data Preservation"

# Function to detect cloud provider
detect_cloud() {
    local context=$(kubectl config current-context)
    if [[ $context == *"aks"* ]] || [[ $context == *"azure"* ]]; then
        echo "aks"
    elif [[ $context == *"gke"* ]] || [[ $context == *"google"* ]]; then
        echo "gke"
    elif [[ $context == *"eks"* ]] || [[ $context == *"aws"* ]]; then
        echo "eks"
    else
        echo "unknown"
    fi
}

# Step 1: Backup current data
echo "📦 Step 1: Backing up current data..."
./backup-data.sh
BACKUP_DIR=$(ls -td monitoring-backup-* | head -1)
echo "✅ Backup created: $BACKUP_DIR"

# Step 2: Detect target cloud and deploy
echo "🔍 Step 2: Detecting target cloud..."
TARGET_CLOUD=$(detect_cloud)
echo "📋 Target cloud: $TARGET_CLOUD"

read -p "🤔 Proceed with migration to $TARGET_CLOUD? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration cancelled."
    exit 1
fi

# Step 3: Deploy to target cloud
echo "🚀 Step 3: Deploying to $TARGET_CLOUD..."
./migrate-cloud.sh

# Step 4: Restore data
echo "📥 Step 4: Restoring historical data..."
./restore-data.sh $BACKUP_DIR

# Step 5: Validate
echo "✅ Step 5: Validating migration..."
./validate-deployment.sh

echo "🎉 Migration completed successfully with data preservation!"
echo "📊 Historical data has been restored to the new cluster."