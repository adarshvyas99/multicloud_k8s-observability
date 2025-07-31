#!/bin/bash

# Multi-Cloud Migration Script
# Supports migration between AKS, GKE, and EKS

set -e

echo "☁️ Multi-Cloud Kubernetes Observability Stack Migration"

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

# Get storage class for cloud provider
get_storage_class() {
    case $1 in
        "aks") echo "managed-premium" ;;
        "gke") echo "standard-rwo" ;;
        "eks") echo "gp2" ;;
        *) echo "default" ;;
    esac
}

# Main migration logic
echo "🔍 Detecting target cloud provider..."
CLOUD_PROVIDER=$(detect_cloud)
STORAGE_CLASS=$(get_storage_class $CLOUD_PROVIDER)

echo "📋 Target: $CLOUD_PROVIDER (Storage: $STORAGE_CLASS)"

# Confirm migration
read -p "🤔 Proceed with migration to $CLOUD_PROVIDER? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Migration cancelled."
    exit 1
fi

# Update storage classes
echo "🔧 Updating storage classes for $CLOUD_PROVIDER..."
find ../manifests -name "*.yaml" -exec sed -i "s/storageClassName: .*/storageClassName: $STORAGE_CLASS/g" {} \;

# Deploy based on cloud provider
case $CLOUD_PROVIDER in
    "aks")
        echo "🚀 Deploying to AKS..."
        ./deploy-aks.sh
        ;;
    "gke")
        echo "🚀 Deploying to GKE..."
        ./deploy-gke.sh
        ;;
    "eks")
        echo "🚀 Deploying to EKS..."
        ./deploy-eks.sh
        ;;
    *)
        echo "❌ Unknown cloud provider. Manual deployment required."
        exit 1
        ;;
esac

echo "✅ Migration to $CLOUD_PROVIDER completed!"