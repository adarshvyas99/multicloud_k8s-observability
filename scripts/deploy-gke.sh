#!/bin/bash

# Kubernetes Observability Stack Deployment Script for GKE
# This script deploys Prometheus, Grafana, and AlertManager to Google Kubernetes Engine

set -e

echo "🚀 Starting Kubernetes Observability Stack deployment for GKE..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Not connected to a Kubernetes cluster. Please configure kubectl."
    exit 1
fi

# Get current context
CURRENT_CONTEXT=$(kubectl config current-context)
echo "📋 Current Kubernetes context: $CURRENT_CONTEXT"

# Confirm deployment
read -p "🤔 Do you want to deploy to this cluster? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Deployment cancelled."
    exit 1
fi

# Update storage class for GKE
echo "🔧 Configuring storage class for GKE..."
sed -i 's/storageClassName: managed-premium/storageClassName: standard-rwo/g' ../manifests/prometheus/prometheus-deployment.yaml
sed -i 's/storageClassName: managed-premium/storageClassName: standard-rwo/g' ../manifests/alertmanager/alertmanager-deployment.yaml
sed -i 's/storageClassName: managed-premium/storageClassName: standard-rwo/g' ../manifests/grafana/grafana-deployment.yaml

# Deploy namespace and RBAC
echo "📦 Creating monitoring namespace and RBAC..."
kubectl apply -f ../manifests/namespace/monitoring-namespace.yaml

# Deploy exporters
echo "📊 Deploying exporters..."
kubectl apply -f ../manifests/exporters/node-exporter.yaml
kubectl apply -f ../manifests/exporters/kube-state-metrics.yaml

# Deploy Prometheus
echo "🔍 Deploying Prometheus..."
kubectl apply -f ../manifests/prometheus/prometheus-deployment.yaml

# Deploy AlertManager
echo "🚨 Deploying AlertManager..."
kubectl apply -f ../manifests/alertmanager/alertmanager-deployment.yaml

# Deploy Grafana
echo "📈 Deploying Grafana..."
kubectl apply -f ../manifests/grafana/grafana-deployment.yaml

# Wait for deployments to be ready
echo "⏳ Waiting for deployments to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/alertmanager -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/kube-state-metrics -n monitoring

# Get service information
echo "🌐 Getting service information..."
echo ""
echo "📊 Grafana:"
kubectl get svc grafana -n monitoring
echo ""
echo "🔍 Prometheus:"
kubectl get svc prometheus -n monitoring
echo ""
echo "🚨 AlertManager:"
kubectl get svc alertmanager -n monitoring

# Port forwarding instructions
echo ""
echo "🔗 To access the services locally, run:"
echo "   Grafana:     kubectl port-forward svc/grafana 3000:3000 -n monitoring"
echo "   Prometheus:  kubectl port-forward svc/prometheus 9090:9090 -n monitoring"
echo "   AlertManager: kubectl port-forward svc/alertmanager 9093:9093 -n monitoring"
echo ""
echo "🔑 Grafana credentials: admin/admin123"
echo ""
echo "✅ Deployment completed successfully!"
echo "🎯 Your observability stack is now monitoring all pods across all namespaces."
echo "📧 Configure email/Slack notifications in AlertManager ConfigMap as needed."