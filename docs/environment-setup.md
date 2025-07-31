# Environment Setup Guide

## Required Environment Variables and Secrets

### GitHub Actions Secrets

#### Repository Secrets (Settings → Secrets and variables → Actions)

**Kubernetes Cluster Access:**
```bash
# Development Environment
KUBE_CONFIG_DATA_DEV=<base64-encoded-kubeconfig-for-dev-cluster>

# Production Environment  
KUBE_CONFIG_DATA_PROD=<base64-encoded-kubeconfig-for-prod-cluster>

# Multi-Cloud Migration
GKE_KUBE_CONFIG_DATA=<base64-encoded-kubeconfig-for-gke-cluster>
EKS_KUBE_CONFIG_DATA=<base64-encoded-kubeconfig-for-eks-cluster>
```

**Application Configuration:**
```bash
# Grafana Admin Credentials
GRAFANA_ADMIN_USER=<username-for-grafana-admin>
GRAFANA_ADMIN_PASSWORD=<secure-password-for-grafana-admin>

# General Kubernetes Config (fallback)
KUBE_CONFIG_DATA=<base64-encoded-kubeconfig>
```

#### How to Generate kubeconfig Base64
```bash
# For AKS
az aks get-credentials --resource-group <rg-name> --name <cluster-name>
cat ~/.kube/config | base64 -w 0

# For GKE
gcloud container clusters get-credentials <cluster-name> --zone <zone>
cat ~/.kube/config | base64 -w 0

# For EKS
aws eks update-kubeconfig --region <region> --name <cluster-name>
cat ~/.kube/config | base64 -w 0
```

### GitOps Configuration

#### ArgoCD Repository Setup
```yaml
# Update gitops/argocd/application.yaml
spec:
  source:
    repoURL: https://github.com/adarshvyas99/multicloud_k8s-observability
    targetRevision: HEAD
```

#### Flux Repository Setup
```yaml
# Update gitops/flux/kustomization.yaml
spec:
  sourceRef:
    kind: GitRepository
    name: observability-stack
---
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: observability-stack
spec:
  url: https://github.com/adarshvyas99/multicloud_k8s-observability
```

### AlertManager Email Configuration

#### Update configs/alertmanager/alertmanager.yml
```yaml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@YOUR-COMPANY.com'
  smtp_auth_username: 'alerts@YOUR-COMPANY.com'
  smtp_auth_password: 'YOUR-APP-PASSWORD'

receivers:
- name: 'critical-alerts'
  email_configs:
  - to: 'devops-team@YOUR-COMPANY.com'
    
- name: 'pod-alerts'
  email_configs:
  - to: 'dev-team@YOUR-COMPANY.com'
    
- name: 'infrastructure-alerts'
  email_configs:
  - to: 'infrastructure-team@YOUR-COMPANY.com'
```

### Slack Integration (Optional)

#### Slack Webhook Configuration
```yaml
# Add to AlertManager configuration
receivers:
- name: 'critical-alerts'
  slack_configs:
  - api_url: 'YOUR_SLACK_WEBHOOK_URL'
    channel: '#alerts-critical'
    title: 'Critical Alert'
```

#### Get Slack Webhook URL
1. Go to https://api.slack.com/apps
2. Create new app → From scratch
3. Add Incoming Webhooks feature
4. Create webhook for your channel
5. Copy webhook URL

### Environment-Specific Configurations

#### Development Environment
```bash
# GitHub Environment: development
# Required secrets:
KUBE_CONFIG_DATA_DEV=<dev-cluster-kubeconfig-base64>

# Storage class: managed-premium (AKS default)
# Namespace: monitoring
```

#### Production Environment
```bash
# GitHub Environment: production  
# Required secrets:
KUBE_CONFIG_DATA_PROD=<prod-cluster-kubeconfig-base64>

# Storage class: managed-premium (AKS default)
# Namespace: monitoring
```

#### GitOps Environment
```bash
# GitHub Environment: gitops
# Required secrets:
KUBE_CONFIG_DATA_PROD=<cluster-kubeconfig-base64>

# Used for deploying ArgoCD/Flux applications
```

### Cloud-Specific Storage Classes

#### Update for Target Cloud
```bash
# AKS (default)
storageClassName: managed-premium

# GKE  
storageClassName: standard-rwo

# EKS
storageClassName: gp2
```

### Security Considerations

#### Secret Management
- Use GitHub/Azure DevOps secret management
- Never commit secrets to repository
- Rotate secrets regularly
- Use least privilege access

#### RBAC Configuration
```bash
# Ensure service accounts have minimal required permissions
# Monitor access logs regularly
# Use namespace-scoped permissions where possible
```

### Validation Commands

#### Test Cluster Access
```bash
# Decode and test kubeconfig
echo $KUBE_CONFIG_DATA | base64 -d > test-kubeconfig
export KUBECONFIG=test-kubeconfig
kubectl cluster-info
kubectl get nodes
```

#### Test Email Configuration
```bash
# Port forward to AlertManager
kubectl port-forward svc/alertmanager 9093:9093 -n monitoring

# Test email configuration via AlertManager UI
# Visit http://localhost:9093
```

### Quick Setup Checklist

- [ ] Create GitHub repository secrets
- [ ] Configure Azure DevOps variable groups
- [ ] Update GitOps repository URLs
- [ ] Configure AlertManager email settings
- [ ] Set up Slack webhooks (optional)
- [ ] Test cluster connectivity
- [ ] Validate secret access in pipelines
- [ ] Test alert notifications