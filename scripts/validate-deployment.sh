#!/bin/bash

# Kubernetes Observability Stack Validation Script
# This script validates the deployment and functionality of the monitoring stack

set -e

echo "🔍 Starting Kubernetes Observability Stack validation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

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

# 1. Check namespace
echo "🔍 Checking monitoring namespace..."
kubectl get namespace monitoring &> /dev/null
print_status $? "Monitoring namespace exists"

# 2. Check all deployments
echo ""
echo "🔍 Checking deployments..."

deployments=("prometheus" "grafana" "alertmanager" "kube-state-metrics")
for deployment in "${deployments[@]}"; do
    kubectl get deployment $deployment -n monitoring &> /dev/null
    print_status $? "Deployment $deployment exists"
    
    # Check if deployment is ready
    ready=$(kubectl get deployment $deployment -n monitoring -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
    desired=$(kubectl get deployment $deployment -n monitoring -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "1")
    
    if [ "$ready" = "$desired" ]; then
        print_status 0 "Deployment $deployment is ready ($ready/$desired)"
    else
        print_status 1 "Deployment $deployment is not ready ($ready/$desired)"
    fi
done

# 3. Check DaemonSet
echo ""
echo "🔍 Checking DaemonSet..."
kubectl get daemonset node-exporter -n monitoring &> /dev/null
print_status $? "DaemonSet node-exporter exists"

# Check if all nodes have node-exporter
desired=$(kubectl get daemonset node-exporter -n monitoring -o jsonpath='{.status.desiredNumberScheduled}' 2>/dev/null || echo "0")
ready=$(kubectl get daemonset node-exporter -n monitoring -o jsonpath='{.status.numberReady}' 2>/dev/null || echo "0")

if [ "$ready" = "$desired" ]; then
    print_status 0 "DaemonSet node-exporter is ready on all nodes ($ready/$desired)"
else
    print_status 1 "DaemonSet node-exporter is not ready on all nodes ($ready/$desired)"
fi

# 4. Check services
echo ""
echo "🔍 Checking services..."
services=("prometheus" "grafana" "alertmanager" "node-exporter" "kube-state-metrics")
for service in "${services[@]}"; do
    kubectl get service $service -n monitoring &> /dev/null
    print_status $? "Service $service exists"
done

# 5. Check PVCs
echo ""
echo "🔍 Checking persistent volume claims..."
pvcs=("prometheus-storage" "grafana-storage" "alertmanager-storage")
for pvc in "${pvcs[@]}"; do
    status=$(kubectl get pvc $pvc -n monitoring -o jsonpath='{.status.phase}' 2>/dev/null || echo "NotFound")
    if [ "$status" = "Bound" ]; then
        print_status 0 "PVC $pvc is bound"
    else
        print_status 1 "PVC $pvc is not bound (status: $status)"
    fi
done

# 6. Test Prometheus connectivity
echo ""
echo "🔍 Testing Prometheus connectivity..."
kubectl port-forward svc/prometheus 9090:9090 -n monitoring &> /dev/null &
PF_PID=$!
sleep 5

if curl -s http://localhost:9090/api/v1/query?query=up &> /dev/null; then
    print_status 0 "Prometheus API is accessible"
else
    print_status 1 "Prometheus API is not accessible"
fi

kill $PF_PID 2>/dev/null || true

# 7. Test Grafana connectivity
echo ""
echo "🔍 Testing Grafana connectivity..."
kubectl port-forward svc/grafana 3000:3000 -n monitoring &> /dev/null &
PF_PID=$!
sleep 5

if curl -s http://localhost:3000/api/health &> /dev/null; then
    print_status 0 "Grafana API is accessible"
else
    print_status 1 "Grafana API is not accessible"
fi

kill $PF_PID 2>/dev/null || true

# 8. Test AlertManager connectivity
echo ""
echo "🔍 Testing AlertManager connectivity..."
kubectl port-forward svc/alertmanager 9093:9093 -n monitoring &> /dev/null &
PF_PID=$!
sleep 5

if curl -s http://localhost:9093/api/v1/status &> /dev/null; then
    print_status 0 "AlertManager API is accessible"
else
    print_status 1 "AlertManager API is not accessible"
fi

kill $PF_PID 2>/dev/null || true

# 9. Check if Prometheus is scraping targets
echo ""
echo "🔍 Checking Prometheus targets..."
kubectl port-forward svc/prometheus 9090:9090 -n monitoring &> /dev/null &
PF_PID=$!
sleep 5

# Check if we can query for up metric
if curl -s "http://localhost:9090/api/v1/query?query=up" | grep -q '"status":"success"'; then
    print_status 0 "Prometheus is collecting metrics"
    
    # Count healthy targets
    healthy_targets=$(curl -s "http://localhost:9090/api/v1/query?query=up" | jq -r '.data.result | length' 2>/dev/null || echo "0")
    echo -e "${GREEN}📊 Found $healthy_targets active targets${NC}"
else
    print_status 1 "Prometheus is not collecting metrics properly"
fi

kill $PF_PID 2>/dev/null || true

# 10. Check for any pod errors
echo ""
echo "🔍 Checking for pod errors..."
error_pods=$(kubectl get pods -n monitoring --field-selector=status.phase!=Running,status.phase!=Succeeded 2>/dev/null | wc -l)
if [ $error_pods -eq 0 ]; then
    print_status 0 "No pods in error state"
else
    print_warning "Found $error_pods pods in error state"
    kubectl get pods -n monitoring --field-selector=status.phase!=Running,status.phase!=Succeeded
fi

# 11. Resource usage check
echo ""
echo "🔍 Checking resource usage..."
echo "📊 Current resource usage:"
kubectl top pods -n monitoring 2>/dev/null || print_warning "Metrics server not available for resource usage"

# 12. Final summary
echo ""
echo "🎯 Validation Summary:"
echo "===================="
kubectl get all -n monitoring

echo ""
echo "🔗 Access URLs (use port-forward):"
echo "   Grafana:     kubectl port-forward svc/grafana 3000:3000 -n monitoring"
echo "   Prometheus:  kubectl port-forward svc/prometheus 9090:9090 -n monitoring"
echo "   AlertManager: kubectl port-forward svc/alertmanager 9093:9093 -n monitoring"
echo ""
echo "🔑 Default Grafana credentials: admin/admin123"
echo ""
echo -e "${GREEN}✅ Validation completed successfully!${NC}"
echo -e "${GREEN}🎉 Your observability stack is ready to monitor all pods across all namespaces!${NC}"