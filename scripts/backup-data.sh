#!/bin/bash

# Backup Prometheus and Grafana data for migration
set -e

BACKUP_DIR="./monitoring-backup-$(date +%Y%m%d-%H%M%S)"
echo "🔄 Creating backup in $BACKUP_DIR"

mkdir -p $BACKUP_DIR

# Backup Prometheus data
echo "📊 Backing up Prometheus data..."
kubectl exec deployment/prometheus -n monitoring -- tar czf /tmp/prometheus-backup.tar.gz /prometheus
kubectl cp monitoring/prometheus-$(kubectl get pods -n monitoring -l app=prometheus -o jsonpath='{.items[0].metadata.name}'):/tmp/prometheus-backup.tar.gz $BACKUP_DIR/prometheus-data.tar.gz

# Backup Grafana data
echo "📈 Backing up Grafana data..."
kubectl exec deployment/grafana -n monitoring -- tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana
kubectl cp monitoring/grafana-$(kubectl get pods -n monitoring -l app=grafana -o jsonpath='{.items[0].metadata.name}'):/tmp/grafana-backup.tar.gz $BACKUP_DIR/grafana-data.tar.gz

# Export Grafana dashboards
echo "📋 Exporting Grafana dashboards..."
kubectl port-forward svc/grafana 3000:3000 -n monitoring &
PF_PID=$!
sleep 5

# Export all dashboards (requires admin credentials)
curl -s -H "Authorization: Bearer admin:admin123" http://localhost:3000/api/search | jq -r '.[].uid' | while read uid; do
    curl -s -H "Authorization: Bearer admin:admin123" "http://localhost:3000/api/dashboards/uid/$uid" > "$BACKUP_DIR/dashboard-$uid.json"
done

kill $PF_PID 2>/dev/null || true

# Backup configurations
echo "⚙️ Backing up configurations..."
kubectl get configmap prometheus-config -n monitoring -o yaml > $BACKUP_DIR/prometheus-config.yaml
kubectl get configmap grafana-config -n monitoring -o yaml > $BACKUP_DIR/grafana-config.yaml
kubectl get configmap alertmanager-config -n monitoring -o yaml > $BACKUP_DIR/alertmanager-config.yaml

echo "✅ Backup completed: $BACKUP_DIR"