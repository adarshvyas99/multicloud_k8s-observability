# GitOps Implementation Guide

## Overview
This guide covers GitOps implementation using ArgoCD and Flux for declarative, automated deployment of the observability stack.

## GitOps Principles Applied

### 1. Declarative Configuration
- All Kubernetes manifests stored in Git
- Infrastructure as Code approach
- Version-controlled configurations

### 2. Git as Single Source of Truth
- All changes go through Git workflow
- Pull request reviews for changes
- Audit trail via Git history

### 3. Automated Deployment
- ArgoCD/Flux monitors Git repository
- Automatic sync on configuration changes
- Self-healing capabilities

## ArgoCD Implementation

### Setup ArgoCD Application
```bash
kubectl apply -f gitops/argocd/application.yaml
```

### Application Configuration
- **Repository**: Your Git repository URL
- **Path**: `manifests/` directory
- **Sync Policy**: Automated with pruning
- **Self-Heal**: Enabled for drift correction

### ArgoCD Features
- **Automated Sync**: Deploys changes automatically
- **Health Checks**: Monitors deployment status
- **Rollback**: Easy rollback to previous versions
- **Multi-Environment**: Separate applications per environment

## Flux Implementation

### Setup Flux GitRepository and Kustomization
```bash
kubectl apply -f gitops/flux/kustomization.yaml
```

### Flux Features
- **GitRepository**: Monitors Git repository for changes
- **Kustomization**: Applies manifests with health checks
- **Validation**: Client-side validation before apply
- **Pruning**: Removes deleted resources

## Kustomize Integration

### Base Configuration
```yaml
# manifests/kustomization.yaml
resources:
  - namespace/monitoring-namespace.yaml
  - exporters/
  - prometheus/prometheus-deployment.yaml
  - alertmanager/alertmanager-deployment.yaml
  - grafana/grafana-deployment.yaml
```

### Environment Overlays
Create environment-specific overlays:
```
overlays/
├── development/
├── production/
├── aks/
├── gke/
└── eks/
```

## Workflow Integration

### GitHub Actions + GitOps
1. **PR Validation**: Validate manifests on pull requests
2. **Merge to Main**: Triggers GitOps deployment
3. **Manual Dispatch**: For migration scenarios
4. **Environment Promotion**: Dev → Staging → Production

### GitOps Deployment Flow
```
Developer → Git Push → GitHub Actions → Git Repository → ArgoCD/Flux → Kubernetes
```

## Multi-Cloud GitOps

### Environment-Specific Applications
```yaml
# ArgoCD Application per environment
- observability-stack-aks
- observability-stack-gke  
- observability-stack-eks
```

### Cloud-Specific Overlays
```yaml
# overlays/aks/kustomization.yaml
patchesStrategicMerge:
- storage-class-patch.yaml  # managed-premium

# overlays/gke/kustomization.yaml  
patchesStrategicMerge:
- storage-class-patch.yaml  # standard-rwo

# overlays/eks/kustomization.yaml
patchesStrategicMerge:
- storage-class-patch.yaml  # gp2
```

## Security Best Practices

### Repository Access
- Private repository for sensitive configurations
- Branch protection rules
- Required PR reviews
- Signed commits

### RBAC Integration
- ArgoCD/Flux service accounts with minimal permissions
- Namespace-scoped deployments
- Secret management via external secret operators

## Monitoring GitOps

### ArgoCD Metrics
- Application sync status
- Deployment success/failure rates
- Drift detection alerts

### Flux Metrics
- Kustomization reconciliation status
- GitRepository polling metrics
- Health check results

## Troubleshooting

### Common Issues
```bash
# Check ArgoCD application status
kubectl get application observability-stack -n argocd

# Check Flux kustomization status
kubectl get kustomization observability-stack -n flux-system

# View sync logs
kubectl logs -n argocd deployment/argocd-application-controller
```

### Drift Detection
- ArgoCD automatically detects configuration drift
- Self-healing corrects manual changes
- Alerts on persistent drift issues