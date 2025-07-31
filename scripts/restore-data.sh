#!/bin/bash

# Restore Prometheus and Grafana data after migration
set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <backup-directory>"
    exit 1
fi

BACKUP_DIR=$1
echo "🔄 Restoring from $BACKUP_DIR"

# Wait for deployments to be ready
echo "⏳ Waiting for deployments..."
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring

# Restore Prometheus data
echo "📊 Restoring Prometheus data..."
kubectl cp $BACKUP_DIR/prometheus-data.tar.gz monitoring/prometheus-$(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}'):/tmp/prometheus-backup.tar.gz
kubectl exec deployment/prometheus -n monitoring -- sh -c "cd / && tar xzf /tmp/prometheus-backup.tar.gz --strip-components=1"
kubectl rollout restart deployment/prometheus -n monitoring

# Restore Grafana data
echo "📈 Restoring Grafana data..."
kubectl cp $BACKUP_DIR/grafana-data.tar.gz monitoring/grafana-$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}'):/tmp/grafana-backup.tar.gz
kubectl exec deployment/grafana -n monitoring -- sh -c "cd / && tar xzf /tmp/grafana-backup.tar.gz --strip-components=1"
kubectl rollout restart deployment/grafana -n monitoring

# Wait for services to be ready
kubectl wait --for=condition=available --timeout=300s deployment/prometheus -n monitoring
kubectl wait --for=condition=available --timeout=300s deployment/grafana -n monitoring

# Import Grafana dashboards
echo "📋 Importing Grafana dashboards..."
kubectl port-forward svc/grafana 3000:3000 -n monitoring &
PF_PID=$!
sleep 10

for dashboard in $BACKUP_DIR/dashboard-*.json; do
    if [ -f "$dashboard" ]; then
        curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer admin:admin123" \
             -d @"$dashboard" http://localhost:3000/api/dashboards/db
    fi
done

kill $PF_PID 2>/dev/null || true

echo "✅ Restore completed successfully!"