# Troubleshooting Guide

## Common Issues and Solutions

### 1. Pod Errors and Root Cause Analysis

#### Issue: Pod CrashLooping
**Symptoms**: Pod restarts frequently, alert "PodCrashLooping" triggered

**Root Cause Analysis Steps**:
```bash
# 1. Check pod status and events
kubectl describe pod <pod-name> -n <namespace>

# 2. Check pod logs
kubectl logs <pod-name> -n <namespace> --previous

# 3. Check resource constraints
kubectl top pod <pod-name> -n <namespace>

# 4. Check node resources
kubectl describe node <node-name>
```

**Common Causes**:
- Out of memory (OOMKilled)
- Application startup failures
- Missing dependencies or configuration
- Resource limits too restrictive

**Solutions**:
- Increase memory/CPU limits
- Fix application configuration
- Add health checks with appropriate timeouts
- Review application logs for specific errors

#### Issue: Pod Not Ready
**Symptoms**: Pod shows "Not Ready" status for extended period

**Root Cause Analysis**:
```bash
# Check readiness probe configuration
kubectl describe pod <pod-name> -n <namespace>

# Check service endpoints
kubectl get endpoints <service-name> -n <namespace>

# Test readiness probe manually
kubectl exec <pod-name> -n <namespace> -- curl localhost:8080/health
```

### 2. Prometheus Issues

#### Issue: Prometheus Not Scraping Targets
**Symptoms**: Missing metrics, targets showing as "down" in Prometheus UI

**Diagnosis**:
```bash
# Check Prometheus targets
kubectl port-forward svc/prometheus 9090:9090 -n monitoring
# Visit http://localhost:9090/targets

# Check service discovery
kubectl logs deployment/prometheus -n monitoring

# Verify service annotations
kubectl get svc <service-name> -o yaml
```

**Solutions**:
- Add `prometheus.io/scrape: "true"` annotation
- Verify `prometheus.io/port` annotation
- Check network policies blocking access
- Ensure metrics endpoint is accessible

#### Issue: High Memory Usage in Prometheus
**Symptoms**: Prometheus pod OOMKilled, slow query performance

**Solutions**:
```bash
# Increase memory limits
kubectl patch deployment prometheus -n monitoring -p '{"spec":{"template":{"spec":{"containers":[{"name":"prometheus","resources":{"limits":{"memory":"4Gi"}}}]}}}}'

# Reduce retention period
# Edit prometheus.yml: --storage.tsdb.retention.time=15d

# Optimize queries and recording rules
```

### 3. Grafana Issues

#### Issue: Grafana Dashboard Not Loading Data
**Symptoms**: Empty graphs, "No data" messages

**Diagnosis**:
```bash
# Check Grafana logs
kubectl logs deployment/grafana -n monitoring

# Test Prometheus connectivity from Grafana pod
kubectl exec deployment/grafana -n monitoring -- curl http://prometheus:9090/api/v1/query?query=up

# Verify datasource configuration
```

**Solutions**:
- Verify Prometheus datasource URL
- Check query syntax in dashboard panels
- Ensure time range is appropriate
- Verify metric names and labels

#### Issue: Grafana Login Issues
**Symptoms**: Cannot access Grafana dashboard

**Solutions**:
```bash
# Reset admin password
kubectl patch secret grafana-credentials -n monitoring -p '{"data":{"admin-password":"bmV3cGFzc3dvcmQ="}}'

# Check service exposure
kubectl get svc grafana -n monitoring

# Port forward for local access
kubectl port-forward svc/grafana 3000:3000 -n monitoring
```

### 4. AlertManager Issues

#### Issue: Alerts Not Being Sent
**Symptoms**: Alerts firing in Prometheus but no notifications received

**Diagnosis**:
```bash
# Check AlertManager status
kubectl port-forward svc/alertmanager 9093:9093 -n monitoring
# Visit http://localhost:9093

# Check AlertManager logs
kubectl logs deployment/alertmanager -n monitoring

# Verify alert routing
```

**Solutions**:
- Verify SMTP/Slack configuration
- Check alert routing rules
- Test notification channels manually
- Ensure AlertManager can reach external services

### 5. Storage Issues

#### Issue: Persistent Volume Claims Pending
**Symptoms**: PVCs stuck in "Pending" state

**Diagnosis**:
```bash
# Check PVC status
kubectl describe pvc <pvc-name> -n monitoring

# Check storage classes
kubectl get storageclass

# Check node capacity
kubectl describe nodes
```

**Solutions**:
- Verify storage class exists and is default
- Check node disk capacity
- For AKS: Ensure managed-premium storage class
- For GKE: Use standard-rwo storage class

### 6. Network Issues

#### Issue: Service Discovery Not Working
**Symptoms**: Prometheus cannot discover Kubernetes services

**Diagnosis**:
```bash
# Check RBAC permissions
kubectl auth can-i list pods --as=system:serviceaccount:monitoring:prometheus

# Check network policies
kubectl get networkpolicy -A

# Test DNS resolution
kubectl exec deployment/prometheus -n monitoring -- nslookup kubernetes.default.svc.cluster.local
```

### 7. Migration Issues (Multi-Cloud)

#### Issue: Storage Class Incompatibility
**Symptoms**: PVCs fail to bind after migration

**Solution**:
```bash
# AKS to GKE
sed -i 's/managed-premium/standard-rwo/g' manifests/*/deployment.yaml

# AKS to EKS
sed -i 's/managed-premium/gp2/g' manifests/*/deployment.yaml

# Or use smart migration script
./scripts/migrate-cloud.sh
```

#### Issue: Load Balancer Configuration
**Symptoms**: Services not accessible after migration

**Solution**:
- **GKE**: Google Cloud Load Balancer auto-provisioned
- **EKS**: AWS Application Load Balancer auto-provisioned
- Update DNS records to point to new external IPs
- Verify cloud-specific firewall/security group rules

## Monitoring Health Checks

### Quick Health Check Script
```bash
#!/bin/bash
echo "=== Monitoring Stack Health Check ==="

# Check namespace
kubectl get ns monitoring

# Check all pods
kubectl get pods -n monitoring

# Check services
kubectl get svc -n monitoring

# Check PVCs
kubectl get pvc -n monitoring

# Check if Prometheus is scraping targets
kubectl port-forward svc/prometheus 9090:9090 -n monitoring &
sleep 5
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.health != "up") | .labels'
pkill -f "port-forward"

echo "=== Health Check Complete ==="
```

## Performance Optimization

### Prometheus Optimization
```yaml
# Increase scrape interval for less critical metrics
scrape_configs:
  - job_name: 'low-priority'
    scrape_interval: 60s  # Instead of default 15s
```

### Grafana Optimization
- Use recording rules for complex queries
- Set appropriate refresh intervals on dashboards
- Limit time ranges for heavy queries

## Emergency Procedures

### Complete Stack Restart
```bash
# Restart all monitoring components
kubectl rollout restart deployment/prometheus -n monitoring
kubectl rollout restart deployment/grafana -n monitoring
kubectl rollout restart deployment/alertmanager -n monitoring
kubectl rollout restart daemonset/node-exporter -n monitoring
kubectl rollout restart deployment/kube-state-metrics -n monitoring
```

### Data Recovery
```bash
# Backup Prometheus data
kubectl exec deployment/prometheus -n monitoring -- tar czf /tmp/prometheus-backup.tar.gz /prometheus

# Backup Grafana dashboards
kubectl exec deployment/grafana -n monitoring -- tar czf /tmp/grafana-backup.tar.gz /var/lib/grafana
```

## Contact Information

For escalation and support:
- **DevOps Team**: devops-team@company.com
- **Infrastructure Team**: infrastructure-team@company.com
- **On-call Engineer**: +1-XXX-XXX-XXXX

## Additional Resources

- [Prometheus Troubleshooting](https://prometheus.io/docs/prometheus/latest/troubleshooting/)
- [Grafana Troubleshooting](https://grafana.com/docs/grafana/latest/troubleshooting/)
- [Kubernetes Troubleshooting](https://kubernetes.io/docs/tasks/debug-application-cluster/)