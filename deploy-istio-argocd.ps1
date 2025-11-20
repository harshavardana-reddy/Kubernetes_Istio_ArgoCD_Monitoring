# PowerShell script for deploying Kubernetes with Istio, ArgoCD, and Autoscaler

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Deploying Kubernetes with Istio, ArgoCD, and Autoscaler" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check if kubectl is available
try {
    $null = kubectl version --client 2>&1
} catch {
    Write-Host "kubectl is not installed. Please install kubectl first." -ForegroundColor Red
    exit 1
}

# Check if cluster is accessible
try {
    $null = kubectl cluster-info 2>&1
} catch {
    Write-Host "Kubernetes cluster is not accessible. Please configure kubectl." -ForegroundColor Red
    exit 1
}

Write-Host "✓ Kubernetes cluster is accessible" -ForegroundColor Green

# Step 1: Deploy Monitoring (Prometheus and Grafana)
Write-Host "`nStep 1: Deploying Monitoring Stack..." -ForegroundColor Yellow
kubectl apply -f monitoring/prometheus-namespace.yaml
kubectl apply -f monitoring/prometheus-serviceaccount.yaml
kubectl apply -f monitoring/prometheus-configmap.yaml
kubectl apply -f monitoring/prometheus-deployment.yaml
kubectl apply -f monitoring/prometheus-service.yaml
kubectl apply -f monitoring/prometheus-service-nodeport.yaml
kubectl apply -f monitoring/grafana-deployment.yaml
kubectl apply -f monitoring/grafana-service.yaml
kubectl apply -f monitoring/grafana-service-nodeport.yaml
Write-Host "✓ Monitoring stack deployed" -ForegroundColor Green

# Step 2: Create microservices namespace
Write-Host "`nStep 2: Creating microservices namespace..." -ForegroundColor Yellow
kubectl apply -f k8s-namespace.yaml
Write-Host "✓ Namespace created" -ForegroundColor Green

# Step 3: Check if Istio is installed
Write-Host "`nStep 2: Checking Istio installation..." -ForegroundColor Yellow
$istioNamespace = kubectl get namespace istio-system 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Istio is installed" -ForegroundColor Green
    kubectl label namespace microservices istio-injection=enabled --overwrite
    Write-Host "✓ Istio sidecar injection enabled for microservices namespace" -ForegroundColor Green
} else {
    Write-Host "✗ Istio is not installed. Please install Istio first." -ForegroundColor Red
    Write-Host "Run: istioctl install --set values.defaultRevision=default" -ForegroundColor Yellow
    exit 1
}

# Step 4: Deploy ConfigMaps
Write-Host "`nStep 4: Deploying ConfigMaps..." -ForegroundColor Yellow
kubectl apply -f k8s-configmap-admin.yaml
kubectl apply -f k8s-configmap-faculty.yaml
kubectl apply -f k8s-configmap-student.yaml
kubectl apply -f k8s-configmap-gateway.yaml
Write-Host "✓ ConfigMaps deployed" -ForegroundColor Green

# Step 5: Deploy Services
Write-Host "`nStep 5: Deploying Services..." -ForegroundColor Yellow
kubectl apply -f k8s-service-admin.yaml
kubectl apply -f k8s-service-faculty.yaml
kubectl apply -f k8s-service-student.yaml
kubectl apply -f k8s-service-gateway.yaml
Write-Host "✓ Services deployed" -ForegroundColor Green

# Step 5b: Deploy NodePort Services
Write-Host "`nStep 5b: Deploying NodePort Services..." -ForegroundColor Yellow
kubectl apply -f k8s-service-admin-nodeport.yaml
kubectl apply -f k8s-service-faculty-nodeport.yaml
kubectl apply -f k8s-service-student-nodeport.yaml
kubectl apply -f k8s-service-gateway-nodeport.yaml
Write-Host "✓ NodePort Services deployed" -ForegroundColor Green

# Step 6: Deploy Deployments
Write-Host "`nStep 6: Deploying Microservices..." -ForegroundColor Yellow
kubectl apply -f k8s-deployment-admin.yaml
kubectl apply -f k8s-deployment-faculty.yaml
kubectl apply -f k8s-deployment-student.yaml
kubectl apply -f k8s-deployment-gateway.yaml
Write-Host "✓ Microservices deployed" -ForegroundColor Green

# Step 7: Deploy Autoscaler RBAC
Write-Host "`nStep 7: Deploying Autoscaler RBAC..." -ForegroundColor Yellow
kubectl apply -f k8s-serviceaccount-autoscaler.yaml
Write-Host "✓ Autoscaler RBAC deployed" -ForegroundColor Green

# Step 8: Deploy Autoscaler
Write-Host "`nStep 8: Deploying Autoscaler..." -ForegroundColor Yellow
kubectl apply -f k8s-deployment-autoscaler.yaml
Write-Host "✓ Autoscaler deployed" -ForegroundColor Green

# Step 9: Deploy Istio configurations
Write-Host "`nStep 9: Deploying Istio configurations..." -ForegroundColor Yellow
kubectl apply -f istio/gateway.yaml
kubectl apply -f istio/virtualservice.yaml
kubectl apply -f istio/destinationrule.yaml
kubectl apply -f istio/peerauthentication.yaml
Write-Host "✓ Istio configurations deployed" -ForegroundColor Green

# Step 10: Check if ArgoCD is installed
Write-Host "`nStep 10: Checking ArgoCD installation..." -ForegroundColor Yellow
$argocdNamespace = kubectl get namespace argocd 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ ArgoCD is installed" -ForegroundColor Green
    Write-Host "`n⚠ Please update Git repository URLs in argocd/application-*.yaml files before deploying" -ForegroundColor Yellow
    $response = Read-Host "Have you updated the Git repository URLs? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        kubectl apply -f argocd/namespace.yaml
        kubectl apply -f argocd/application-microservices.yaml
        kubectl apply -f argocd/application-istio.yaml
        kubectl apply -f argocd/application-monitoring.yaml
        Write-Host "✓ ArgoCD applications deployed" -ForegroundColor Green
    } else {
        Write-Host "⚠ Skipping ArgoCD application deployment. Deploy manually after updating repository URLs." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ ArgoCD is not installed. Skipping ArgoCD application deployment." -ForegroundColor Yellow
    Write-Host "To install ArgoCD, run:" -ForegroundColor Yellow
    Write-Host "  kubectl create namespace argocd" -ForegroundColor Yellow
    Write-Host "  kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml" -ForegroundColor Yellow
}

# Step 10: Wait for pods to be ready
Write-Host "`nStep 10: Waiting for pods to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=admin-service -n microservices --timeout=120s 2>&1 | Out-Null
kubectl wait --for=condition=ready pod -l app=faculty-service -n microservices --timeout=120s 2>&1 | Out-Null
kubectl wait --for=condition=ready pod -l app=student-service -n microservices --timeout=120s 2>&1 | Out-Null
kubectl wait --for=condition=ready pod -l app=api-gateway -n microservices --timeout=120s 2>&1 | Out-Null
kubectl wait --for=condition=ready pod -l app=autoscaler -n microservices --timeout=120s 2>&1 | Out-Null

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Display status
Write-Host "`nCurrent Pod Status:" -ForegroundColor Yellow
kubectl get pods -n microservices

Write-Host "`nService Status:" -ForegroundColor Yellow
kubectl get svc -n microservices

Write-Host "`nIstio Gateway Status:" -ForegroundColor Yellow
kubectl get gateway -n microservices

Write-Host "`nTo access services via Istio Gateway:" -ForegroundColor Green
Write-Host "  kubectl port-forward -n istio-system svc/istio-ingressgateway 8080:80" -ForegroundColor White
Write-Host "  curl http://localhost:8080/api/admin/health" -ForegroundColor White

Write-Host "`nTo access services via NodePort:" -ForegroundColor Green
Write-Host "  API Gateway: <node-ip>:30000" -ForegroundColor White
Write-Host "  Admin Service: <node-ip>:30001" -ForegroundColor White
Write-Host "  Faculty Service: <node-ip>:30002" -ForegroundColor White
Write-Host "  Student Service: <node-ip>:30003" -ForegroundColor White

Write-Host "`nTo access monitoring:" -ForegroundColor Green
Write-Host "  Prometheus: <node-ip>:30090 or kubectl port-forward svc/prometheus-server -n monitoring 9090:9090" -ForegroundColor White
Write-Host "  Grafana: <node-ip>:30300 or kubectl port-forward svc/grafana -n monitoring 3000:3000" -ForegroundColor White
Write-Host "  Grafana credentials: admin/admin" -ForegroundColor White

Write-Host "`nTo view autoscaler logs:" -ForegroundColor Green
Write-Host "  kubectl logs -f deployment/autoscaler -n microservices" -ForegroundColor White

