# Data Migration Guide

## Overview
This guide covers backup and restore procedures for preserving historical monitoring data during cloud migrations.

## Backup Process

### What Gets Backed Up
- **Prometheus TSDB**: All time-series metrics data
- **Grafana Dashboards**: Dashboard configurations and settings
- **Grafana Data**: User preferences and datasource configurations
- **Configuration Files**: Prometheus rules, AlertManager config

### Backup Script Usage
```bash
./scripts/backup-data.sh
```

### Backup Contents
```
monitoring-backup-YYYYMMDD-HHMMSS/
├── prometheus-data.tar.gz      # Prometheus time-series database
├── grafana-data.tar.gz         # Grafana application data
├── dashboard-*.json            # Individual dashboard exports
├── prometheus-config.yaml      # Prometheus configuration
├── grafana-config.yaml         # Grafana configuration
└── alertmanager-config.yaml    # AlertManager configuration
```

## Restore Process

### Prerequisites
- Target cluster must have monitoring stack deployed
- All deployments must be in ready state
- Network access to Grafana API (port 3000)

### Restore Script Usage
```bash
./scripts/restore-data.sh monitoring-backup-YYYYMMDD-HHMMSS
```

### Restore Steps
1. **Wait for Readiness**: Ensures all pods are running
2. **Restore Prometheus**: Copies TSDB data and restarts deployment
3. **Restore Grafana**: Copies application data and restarts deployment
4. **Import Dashboards**: Re-imports all dashboard configurations
5. **Validation**: Verifies data accessibility

## Complete Migration

### One-Command Migration
```bash
./scripts/migrate-with-data.sh
```

This script:
1. Backs up current data
2. Detects target cloud provider
3. Deploys to new cluster
4. Restores historical data
5. Validates migration success

## Data Retention Considerations

### Prometheus Data
- **Default Retention**: 30 days
- **Storage Requirements**: ~1GB per day for typical cluster
- **Compression**: Data is compressed during backup

### Grafana Data
- **Dashboards**: Lightweight JSON configurations
- **User Data**: Minimal storage requirements
- **Datasources**: Configuration only, no data

## Troubleshooting

### Common Issues

#### Backup Fails
```bash
# Check pod status
kubectl get pods -n monitoring

# Check storage space
kubectl exec deployment/prometheus -n monitoring -- df -h /prometheus
```

#### Restore Fails
```bash
# Verify backup integrity
tar -tzf monitoring-backup-*/prometheus-data.tar.gz | head

# Check target cluster readiness
kubectl wait --for=condition=available deployment/prometheus -n monitoring
```

#### Dashboard Import Fails
```bash
# Check Grafana API access
kubectl port-forward svc/grafana 3000:3000 -n monitoring &
curl -s http://localhost:3000/api/health
```

## Best Practices

### Regular Backups
- Schedule daily backups via cron
- Store backups in cloud storage (S3, Azure Blob, GCS)
- Test restore procedures monthly

### Migration Planning
- Perform migration during maintenance windows
- Validate data integrity post-migration
- Keep source cluster running until validation complete

### Storage Management
- Monitor backup storage usage
- Implement backup retention policies
- Compress older backups for long-term storage