# Kubernetes Microservices with Istio Service Mesh, ArgoCD, and Autoscaler

This project demonstrates a complete microservices architecture deployed on Kubernetes with:
- **Istio Service Mesh** for traffic management, security, and observability
- **ArgoCD** for GitOps-based continuous deployment
- **Custom Autoscaler** for intelligent scaling based on metrics

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Istio Ingress Gateway                     │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                    API Gateway Service                       │
└──────────┬──────────────┬──────────────┬────────────────────┘
           │              │              │
           ▼              ▼              ▼
    ┌──────────┐   ┌──────────┐   ┌──────────┐
    │  Admin   │   │ Faculty  │   │ Student  │
    │ Service  │   │ Service  │   │ Service  │
    └──────────┘   └──────────┘   └──────────┘
           │              │              │
           └──────────────┴──────────────┘
                       │
                       ▼
            ┌──────────────────┐
            │   Prometheus      │
            │   (Monitoring)    │
            └──────────┬───────┘
                       │
                       ▼
            ┌──────────────────┐
            │   Autoscaler     │
            │   (Scaling)      │
            └──────────────────┘
```

## Prerequisites

1. **Kubernetes Cluster** (v1.24+)
   - Minikube, Kind, or a cloud provider cluster (GKE, EKS, AKS)
   
2. **kubectl** configured to access your cluster

3. **Istio** installed on your cluster

4. **ArgoCD** installed on your cluster

5. **Prometheus** for metrics collection (required by autoscaler)

6. **Docker** for building container images

## Installation Steps

### Step 1: Install Istio Service Mesh

```bash
# Download Istio
curl -L https://istio.io/downloadIstio | sh -
cd istio-*

# Add Istio to PATH (Linux/Mac)
export PATH=$PWD/bin:$PATH

# Install Istio with default profile
istioctl install --set values.defaultRevision=default

# Enable Istio sidecar injection for microservices namespace
kubectl label namespace microservices istio-injection=enabled

# Verify Istio installation
kubectl get pods -n istio-system
```

### Step 2: Install Prometheus and Grafana for Monitoring

**Option 1: Using Deployment Script (Recommended)**

The deployment script automatically installs Prometheus and Grafana. Skip to Step 3.

**Option 2: Manual Installation**

```bash
# Create monitoring namespace
kubectl apply -f monitoring/prometheus-namespace.yaml

# Deploy Prometheus
kubectl apply -f monitoring/prometheus-serviceaccount.yaml
kubectl apply -f monitoring/prometheus-configmap.yaml
kubectl apply -f monitoring/prometheus-deployment.yaml
kubectl apply -f monitoring/prometheus-service.yaml
kubectl apply -f monitoring/prometheus-service-nodeport.yaml

# Deploy Grafana
kubectl apply -f monitoring/grafana-deployment.yaml
kubectl apply -f monitoring/grafana-service.yaml
kubectl apply -f monitoring/grafana-service-nodeport.yaml

# Wait for Prometheus to be ready
kubectl wait --for=condition=ready pod -l app=prometheus -n monitoring --timeout=300s

# Wait for Grafana to be ready
kubectl wait --for=condition=ready pod -l app=grafana -n monitoring --timeout=300s
```

**Note:** The autoscaler expects Prometheus at `prometheus-server.monitoring.svc.cluster.local:9090`, which matches the service name in the manifests.

### Step 3: Install ArgoCD

```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Get ArgoCD admin password (for initial login)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# Port-forward ArgoCD server (optional, for local access)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

### Step 4: Build and Push Autoscaler Image

```bash
# Navigate to autoscaler directory
cd AUTOSCALER

# Build the Docker image
docker build -t your-registry/autoscaler:latest .

# Push to your container registry
docker push your-registry/autoscaler:latest

# Update the image in k8s-deployment-autoscaler.yaml
# Replace 'harshareddy2024/autoscaler:latest' with your image
```

### Step 5: Deploy Microservices and Infrastructure

```bash
# Create microservices namespace
kubectl apply -f k8s-namespace.yaml

# Deploy ConfigMaps
kubectl apply -f k8s-configmap-admin.yaml
kubectl apply -f k8s-configmap-faculty.yaml
kubectl apply -f k8s-configmap-student.yaml
kubectl apply -f k8s-configmap-gateway.yaml

# Deploy Services
kubectl apply -f k8s-service-admin.yaml
kubectl apply -f k8s-service-faculty.yaml
kubectl apply -f k8s-service-student.yaml
kubectl apply -f k8s-service-gateway.yaml

# Deploy Deployments (with Istio sidecar injection)
kubectl apply -f k8s-deployment-admin.yaml
kubectl apply -f k8s-deployment-faculty.yaml
kubectl apply -f k8s-deployment-student.yaml
kubectl apply -f k8s-deployment-gateway.yaml

# Deploy Autoscaler RBAC
kubectl apply -f k8s-serviceaccount-autoscaler.yaml

# Deploy Autoscaler
kubectl apply -f k8s-deployment-autoscaler.yaml

# Deploy Istio configurations
kubectl apply -f istio/gateway.yaml
kubectl apply -f istio/virtualservice.yaml
kubectl apply -f istio/destinationrule.yaml
kubectl apply -f istio/peerauthentication.yaml
```

### Step 6: Configure ArgoCD Applications

```bash
# Update ArgoCD application manifests with your Git repository URL
# Edit argocd/application-*.yaml files
# Replace repository URLs with your actual repo

# Apply ArgoCD applications
kubectl apply -f argocd/namespace.yaml
kubectl apply -f argocd/application-microservices.yaml
kubectl apply -f argocd/application-istio.yaml
kubectl apply -f argocd/application-monitoring.yaml
```

### Step 7: Access Services

#### Access via Istio Ingress Gateway

```bash
# Get Istio Ingress Gateway external IP or use port-forward
kubectl get svc istio-ingressgateway -n istio-system

# Port-forward Istio Ingress Gateway
kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80

# Access services
curl http://localhost:8080/api/admin/health
curl http://localhost:8080/api/faculty/health
curl http://localhost:8080/api/student/health
```

#### Access ArgoCD UI

```bash
# Port-forward ArgoCD server
kubectl port-forward svc/argocd-server -n argocd 8081:443

# Access ArgoCD UI at https://localhost:8081
# Username: admin
# Password: (from Step 3)
```

#### Access Prometheus

```bash
# Port-forward Prometheus
kubectl port-forward svc/prometheus-server -n monitoring 9090:9090

# Or access via NodePort
# Access Prometheus at http://<node-ip>:30090

# Access Prometheus UI at http://localhost:9090
```

#### Access Grafana

```bash
# Port-forward Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000

# Or access via NodePort
# Access Grafana at http://<node-ip>:30300

# Access Grafana UI at http://localhost:3000
# Default credentials: admin/admin
```

**Note:** After logging into Grafana, you'll need to add Prometheus as a data source:
1. Go to Configuration → Data Sources
2. Add data source → Prometheus
3. URL: `http://prometheus-server.monitoring.svc.cluster.local:9090`
4. Save & Test

## Configuration

### Autoscaler Configuration

The autoscaler can be configured via environment variables in `k8s-deployment-autoscaler.yaml`:

- `LATENCY_THRESHOLD_MS`: Latency threshold in milliseconds (default: 300)
- `CPU_THRESHOLD`: CPU usage threshold (default: 0.7)
- `RPS_THRESHOLD`: Requests per second threshold (default: 200)
- `SCALE_OUT_FACTOR`: Scale out factor (default: 0.2)
- `SCALE_IN_FACTOR`: Scale in factor (default: 0.15)
- `MIN_REPLICAS`: Minimum number of replicas (default: 2)
- `MAX_REPLICAS`: Maximum number of replicas (default: 50)

### Istio Configuration

- **Gateway**: Defines entry point for external traffic
- **VirtualService**: Routes traffic to appropriate services
- **DestinationRule**: Configures load balancing and circuit breaking
- **PeerAuthentication**: Configures mTLS (currently set to PERMISSIVE)

### ArgoCD Configuration

- **application-microservices.yaml**: Manages all microservices deployments
- **application-istio.yaml**: Manages Istio configurations
- Both applications are configured for automated sync and self-healing

## Monitoring and Observability

### Prometheus Metrics

Prometheus is configured to scrape:
- **Kubernetes API server** metrics
- **Kubernetes nodes** metrics
- **Kubernetes pods** with `prometheus.io/scrape=true` annotation
- **Istio Envoy** sidecar metrics (from all pods with istio-proxy container)
- **Istio control plane** (istiod) metrics
- **Microservices** in the microservices namespace

### Access Monitoring Dashboards

```bash
# Access Prometheus
kubectl port-forward svc/prometheus-server -n monitoring 9090:9090
# Or via NodePort: http://<node-ip>:30090

# Access Grafana
kubectl port-forward svc/grafana -n monitoring 3000:3000
# Or via NodePort: http://<node-ip>:30300
# Default credentials: admin/admin
```

### View Istio Metrics

```bash
# Access Kiali (if installed)
kubectl port-forward svc/kiali -n istio-system 20001:20001

# Query Istio metrics in Prometheus
# Example queries:
# - istio_requests_total
# - istio_request_duration_milliseconds_bucket
# - istio_request_bytes_bucket
```

### Check Autoscaler Logs

```bash
kubectl logs -f deployment/autoscaler -n microservices
```

### View Service Metrics

```bash
# Check pod metrics
kubectl top pods -n microservices

# Check service status
kubectl get pods -n microservices
kubectl get svc -n microservices
```

## Troubleshooting

### Istio Sidecar Not Injected

```bash
# Check if namespace is labeled
kubectl get namespace microservices --show-labels

# Label namespace if not labeled
kubectl label namespace microservices istio-injection=enabled --overwrite

# Restart pods to inject sidecar
kubectl rollout restart deployment -n microservices
```

### Autoscaler Not Working

```bash
# Check autoscaler logs
kubectl logs deployment/autoscaler -n microservices

# Verify Prometheus connectivity
kubectl exec -it deployment/autoscaler -n microservices -- python -c "from prometheus_api_client import PrometheusConnect; p = PrometheusConnect(url='http://prometheus-server.monitoring.svc.cluster.local:9090'); print(p.all_metrics())"

# Check RBAC permissions
kubectl auth can-i patch deployments --namespace microservices --as=system:serviceaccount:microservices:autoscaler
```

### ArgoCD Sync Issues

```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# View application details
kubectl describe application microservices-app -n argocd

# Check ArgoCD server logs
kubectl logs -f deployment/argocd-server -n argocd
```

## Cleanup

### Option 1: Using Cleanup Scripts (Recommended)

**Linux/Mac:**
```bash
chmod +x cleanup-istio-argocd.sh
./cleanup-istio-argocd.sh
```

**Windows (PowerShell):**
```powershell
.\cleanup-istio-argocd.ps1
```

The cleanup scripts will:
- Delete ArgoCD applications
- Delete Istio configurations (Gateway, VirtualService, DestinationRule, PeerAuthentication)
- Delete Autoscaler and its RBAC
- Delete all NodePort and ClusterIP services
- Delete all deployments
- Delete all ConfigMaps
- Remove Istio injection labels
- Delete the microservices namespace

### Option 2: Manual Cleanup

```bash
# Delete ArgoCD applications
kubectl delete -f argocd/application-microservices.yaml
kubectl delete -f argocd/application-istio.yaml
kubectl delete -f argocd/application-monitoring.yaml

# Delete Istio configurations
kubectl delete -f istio/peerauthentication.yaml
kubectl delete -f istio/destinationrule.yaml
kubectl delete -f istio/virtualservice.yaml
kubectl delete -f istio/gateway.yaml

# Delete Autoscaler
kubectl delete -f k8s-deployment-autoscaler.yaml
kubectl delete -f k8s-serviceaccount-autoscaler.yaml

# Delete NodePort Services
kubectl delete -f k8s-service-admin-nodeport.yaml
kubectl delete -f k8s-service-faculty-nodeport.yaml
kubectl delete -f k8s-service-student-nodeport.yaml
kubectl delete -f k8s-service-gateway-nodeport.yaml

# Delete ClusterIP Services
kubectl delete -f k8s-service-admin.yaml
kubectl delete -f k8s-service-faculty.yaml
kubectl delete -f k8s-service-student.yaml
kubectl delete -f k8s-service-gateway.yaml

# Delete Deployments
kubectl delete -f k8s-deployment-admin.yaml
kubectl delete -f k8s-deployment-faculty.yaml
kubectl delete -f k8s-deployment-student.yaml
kubectl delete -f k8s-deployment-gateway.yaml

# Delete ConfigMaps
kubectl delete -f k8s-configmap-admin.yaml
kubectl delete -f k8s-configmap-faculty.yaml
kubectl delete -f k8s-configmap-student.yaml
kubectl delete -f k8s-configmap-gateway.yaml

# Remove Istio injection label
kubectl label namespace microservices istio-injection-

# Delete namespace
kubectl delete -f k8s-namespace.yaml
```

### Uninstalling Infrastructure Components

**Uninstall Istio:**
```bash
istioctl uninstall --purge
```

**Uninstall ArgoCD:**
```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

**Uninstall Prometheus and Grafana:**
```bash
# Delete monitoring resources
kubectl delete -f monitoring/grafana-service-nodeport.yaml
kubectl delete -f monitoring/grafana-service.yaml
kubectl delete -f monitoring/grafana-deployment.yaml
kubectl delete -f monitoring/prometheus-service-nodeport.yaml
kubectl delete -f monitoring/prometheus-service.yaml
kubectl delete -f monitoring/prometheus-deployment.yaml
kubectl delete -f monitoring/prometheus-configmap.yaml
kubectl delete -f monitoring/prometheus-serviceaccount.yaml
kubectl delete -f monitoring/prometheus-namespace.yaml

# Or delete the entire namespace
kubectl delete namespace monitoring
```

## File Structure

```
.
├── AUTOSCALER/
│   ├── autoscaler.py
│   ├── Dockerfile
│   └── requirements.txt
├── istio/
│   ├── gateway.yaml
│   ├── virtualservice.yaml
│   ├── destinationrule.yaml
│   ├── peerauthentication.yaml
│   └── kustomization.yaml
├── argocd/
│   ├── namespace.yaml
│   ├── application-microservices.yaml
│   ├── application-istio.yaml
│   └── kustomization.yaml
├── monitoring/
│   └── prometheus-namespace.yaml
├── k8s-deployment-autoscaler.yaml
├── k8s-serviceaccount-autoscaler.yaml
└── README-ISTIO-ARGOCD.md
```

## Additional Resources

- [Istio Documentation](https://istio.io/latest/docs/)
- [ArgoCD Documentation](https://argo-cd.readthedocs.io/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Prometheus Documentation](https://prometheus.io/docs/)

## Notes

1. **Update Git Repository URLs**: Before deploying ArgoCD applications, update the repository URLs in `argocd/application-*.yaml` files.

2. **Container Images**: Ensure all container images are built and pushed to your container registry. Update image references in deployment manifests.

3. **Prometheus Service Name**: The autoscaler expects Prometheus at `http://prometheus-server.monitoring.svc.cluster.local:9090`. Adjust if your Prometheus installation uses a different service name.

4. **Network Policies**: Consider adding Kubernetes NetworkPolicies for additional security.

5. **TLS Certificates**: For production, configure proper TLS certificates for Istio Gateway.

