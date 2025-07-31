#!/bin/bash

# Kubernetes Observability Stack Cleanup Script
# This script removes all monitoring components from the cluster

set -e

echo "🧹 Starting Kubernetes Observability Stack cleanup..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed${NC}"
    exit 1
fi

# Check if connected to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Not connected to a Kubernetes cluster${NC}"
    exit 1
fi

echo "📋 Current cluster: $(kubectl config current-context)"
echo ""

# Confirm cleanup
read -p "🤔 Are you sure you want to remove the monitoring stack? This will delete all data! (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled."
    exit 1
fi

echo "🗑️  Starting cleanup process..."

# Remove Grafana
echo "📈 Removing Grafana..."
kubectl delete -f ../manifests/grafana/grafana-deployment.yaml --ignore-not-found=true

# Remove AlertManager
echo "🚨 Removing AlertManager..."
kubectl delete -f ../manifests/alertmanager/alertmanager-deployment.yaml --ignore-not-found=true

# Remove Prometheus
echo "🔍 Removing Prometheus..."
kubectl delete -f ../manifests/prometheus/prometheus-deployment.yaml --ignore-not-found=true

# Remove exporters
echo "📊 Removing exporters..."
kubectl delete -f ../manifests/exporters/kube-state-metrics.yaml --ignore-not-found=true
kubectl delete -f ../manifests/exporters/node-exporter.yaml --ignore-not-found=true

# Remove namespace and RBAC (this will also remove any remaining resources)
echo "📦 Removing namespace and RBAC..."
kubectl delete -f ../manifests/namespace/monitoring-namespace.yaml --ignore-not-found=true

# Wait for namespace deletion
echo "⏳ Waiting for namespace deletion..."
while kubectl get namespace monitoring &> /dev/null; do
    echo "   Still deleting..."
    sleep 5
done

echo ""
echo -e "${GREEN}✅ Cleanup completed successfully!${NC}"
echo -e "${GREEN}🎉 All monitoring components have been removed from the cluster.${NC}"