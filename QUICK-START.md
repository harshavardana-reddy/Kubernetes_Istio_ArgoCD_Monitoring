# Quick Start Guide

This guide provides a quick way to get started with the Kubernetes microservices setup including Istio, ArgoCD, and Autoscaler.

## Prerequisites Checklist

- [ ] Kubernetes cluster (v1.24+) running and accessible via kubectl
- [ ] Istio installed on the cluster
- [ ] ArgoCD installed on the cluster (optional but recommended)
- [ ] Prometheus installed for monitoring (required for autoscaler)
- [ ] Docker installed for building images
- [ ] Container registry access for pushing images

## Quick Deployment

### Option 1: Using Deployment Script (Recommended)

**Linux/Mac:**
```bash
chmod +x deploy-istio-argocd.sh
./deploy-istio-argocd.sh
```

**Windows (PowerShell):**
```powershell
.\deploy-istio-argocd.ps1
```

### Option 2: Manual Deployment

Follow the step-by-step instructions in [README-ISTIO-ARGOCD.md](./README-ISTIO-ARGOCD.md)

## Before You Start

1. **Update Container Images**: 
   - Build and push your microservice images
   - Update image references in deployment manifests
   - Build and push autoscaler image:
     ```bash
     cd AUTOSCALER
     docker build -t your-registry/autoscaler:latest .
     docker push your-registry/autoscaler:latest
     ```
   - Update `k8s-deployment-autoscaler.yaml` with your image

2. **Update ArgoCD Git Repository URLs**:
   - Edit `argocd/application-microservices.yaml`
   - Edit `argocd/application-istio.yaml`
   - Replace `https://github.com/your-username/your-repo.git` with your actual repository URL

3. **Verify Prometheus Service Name**:
   - The autoscaler expects Prometheus at `prometheus-server.monitoring.svc.cluster.local:9090`
   - If your Prometheus uses a different service name, update `autoscaler.py` line 23

## Installation Order

1. **Install Istio** (if not already installed)
2. **Install Prometheus** (required for autoscaler)
3. **Install ArgoCD** (optional, for GitOps)
4. **Deploy Microservices** (using script or manually)
5. **Deploy Istio Configurations**
6. **Deploy Autoscaler**
7. **Configure ArgoCD Applications**

## Verification

After deployment, verify everything is working:

```bash
# Check all pods are running
kubectl get pods -n microservices

# Check services
kubectl get svc -n microservices

# Check Istio gateway
kubectl get gateway -n microservices

# Check autoscaler logs
kubectl logs -f deployment/autoscaler -n microservices

# Test service access
kubectl port-forward -n istio-system svc/istio-ingressgateway 8081:80
curl http://localhost:8080/api/admin/health
```

## Common Issues

### Issue: Pods stuck in Pending
- Check node resources: `kubectl describe nodes`
- Check pod events: `kubectl describe pod <pod-name> -n microservices`

### Issue: Istio sidecar not injected
- Verify namespace label: `kubectl get namespace microservices --show-labels`
- Label namespace: `kubectl label namespace microservices istio-injection=enabled --overwrite`
- Restart pods: `kubectl rollout restart deployment -n microservices`

### Issue: Autoscaler not connecting to Prometheus
- Check Prometheus service: `kubectl get svc -n monitoring`
- Verify service name matches in `autoscaler.py`
- Check autoscaler logs: `kubectl logs deployment/autoscaler -n microservices`

### Issue: ArgoCD sync failing
- Check application status: `kubectl get applications -n argocd`
- Verify Git repository URL and credentials
- Check ArgoCD logs: `kubectl logs deployment/argocd-server -n argocd`

## Cleanup

To remove all deployed resources:

**Linux/Mac:**
```bash
chmod +x cleanup-istio-argocd.sh
./cleanup-istio-argocd.sh
```

**Windows (PowerShell):**
```powershell
.\cleanup-istio-argocd.ps1
```

The cleanup script will remove all microservices, Istio configurations, ArgoCD applications, and the autoscaler. It will prompt for confirmation before proceeding.

## Next Steps

- Review [README-ISTIO-ARGOCD.md](./README-ISTIO-ARGOCD.md) for detailed documentation
- Configure monitoring dashboards in Grafana
- Set up CI/CD pipelines
- Configure TLS certificates for production
- Review and adjust autoscaler thresholds

## Getting Help

- Check logs: `kubectl logs -f <pod-name> -n <namespace>`
- Describe resources: `kubectl describe <resource> <name> -n <namespace>`
- Check events: `kubectl get events -n <namespace> --sort-by='.lastTimestamp'`

