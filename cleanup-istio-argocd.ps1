# PowerShell script for cleaning up Kubernetes with Istio, ArgoCD, and Autoscaler

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cleaning up Kubernetes with Istio, ArgoCD, and Autoscaler" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Confirmation prompt
$response = Read-Host "Are you sure you want to delete all resources? (y/n)"
if ($response -ne "y" -and $response -ne "Y") {
    Write-Host "Cleanup cancelled." -ForegroundColor Yellow
    exit 0
}

# Step 1: Delete ArgoCD Applications
Write-Host "`nStep 1: Deleting ArgoCD Applications..." -ForegroundColor Yellow
$argocdNamespace = kubectl get namespace argocd 2>&1
if ($LASTEXITCODE -eq 0) {
    kubectl delete -f argocd/application-microservices.yaml 2>&1 | Out-Null
    kubectl delete -f argocd/application-istio.yaml 2>&1 | Out-Null
    kubectl delete -f argocd/application-monitoring.yaml 2>&1 | Out-Null
    Write-Host "✓ ArgoCD Applications deleted" -ForegroundColor Green
} else {
    Write-Host "⚠ ArgoCD namespace not found, skipping..." -ForegroundColor Yellow
}

# Step 2: Delete Istio configurations
Write-Host "`nStep 2: Deleting Istio configurations..." -ForegroundColor Yellow
kubectl delete -f istio/peerauthentication.yaml 2>&1 | Out-Null
kubectl delete -f istio/destinationrule.yaml 2>&1 | Out-Null
kubectl delete -f istio/virtualservice.yaml 2>&1 | Out-Null
kubectl delete -f istio/gateway.yaml 2>&1 | Out-Null
Write-Host "✓ Istio configurations deleted" -ForegroundColor Green

# Step 3: Delete Autoscaler
Write-Host "`nStep 3: Deleting Autoscaler..." -ForegroundColor Yellow
kubectl delete -f k8s-deployment-autoscaler.yaml 2>&1 | Out-Null
kubectl delete -f k8s-serviceaccount-autoscaler.yaml 2>&1 | Out-Null
Write-Host "✓ Autoscaler deleted" -ForegroundColor Green

# Step 4: Delete NodePort Services
Write-Host "`nStep 4: Deleting NodePort Services..." -ForegroundColor Yellow
kubectl delete -f k8s-service-admin-nodeport.yaml 2>&1 | Out-Null
kubectl delete -f k8s-service-faculty-nodeport.yaml 2>&1 | Out-Null
kubectl delete -f k8s-service-student-nodeport.yaml 2>&1 | Out-Null
kubectl delete -f k8s-service-gateway-nodeport.yaml 2>&1 | Out-Null
Write-Host "✓ NodePort Services deleted" -ForegroundColor Green

# Step 5: Delete ClusterIP Services
Write-Host "`nStep 5: Deleting ClusterIP Services..." -ForegroundColor Yellow
kubectl delete -f k8s-service-admin.yaml 2>&1 | Out-Null
kubectl delete -f k8s-service-faculty.yaml 2>&1 | Out-Null
kubectl delete -f k8s-service-student.yaml 2>&1 | Out-Null
kubectl delete -f k8s-service-gateway.yaml 2>&1 | Out-Null
Write-Host "✓ ClusterIP Services deleted" -ForegroundColor Green

# Step 6: Delete Deployments
Write-Host "`nStep 6: Deleting Deployments..." -ForegroundColor Yellow
kubectl delete -f k8s-deployment-admin.yaml 2>&1 | Out-Null
kubectl delete -f k8s-deployment-faculty.yaml 2>&1 | Out-Null
kubectl delete -f k8s-deployment-student.yaml 2>&1 | Out-Null
kubectl delete -f k8s-deployment-gateway.yaml 2>&1 | Out-Null
Write-Host "✓ Deployments deleted" -ForegroundColor Green

# Step 7: Delete ConfigMaps
Write-Host "`nStep 7: Deleting ConfigMaps..." -ForegroundColor Yellow
kubectl delete -f k8s-configmap-admin.yaml 2>&1 | Out-Null
kubectl delete -f k8s-configmap-faculty.yaml 2>&1 | Out-Null
kubectl delete -f k8s-configmap-student.yaml 2>&1 | Out-Null
kubectl delete -f k8s-configmap-gateway.yaml 2>&1 | Out-Null
Write-Host "✓ ConfigMaps deleted" -ForegroundColor Green

# Step 8: Remove Istio injection label from namespace
Write-Host "`nStep 8: Removing Istio injection label..." -ForegroundColor Yellow
kubectl label namespace microservices istio-injection- 2>&1 | Out-Null
Write-Host "✓ Istio injection label removed" -ForegroundColor Green

# Step 9: Delete namespace (this will remove all remaining resources)
Write-Host "`nStep 9: Deleting microservices namespace..." -ForegroundColor Yellow
kubectl delete -f k8s-namespace.yaml 2>&1 | Out-Null
Write-Host "✓ Namespace deleted" -ForegroundColor Green

# Wait for namespace to be fully deleted
Write-Host "`nWaiting for namespace to be fully deleted..." -ForegroundColor Yellow
$timeout = 60
$counter = 0
$namespaceExists = $true
while ($namespaceExists -and $counter -lt $timeout) {
    Start-Sleep -Seconds 2
    $counter += 2
    $check = kubectl get namespace microservices 2>&1
    if ($LASTEXITCODE -ne 0) {
        $namespaceExists = $false
    } else {
        Write-Host "." -NoNewline
    }
}
Write-Host ""

$finalCheck = kubectl get namespace microservices 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "⚠ Namespace still exists. You may need to force delete it." -ForegroundColor Yellow
    Write-Host "  kubectl delete namespace microservices --force --grace-period=0" -ForegroundColor White
} else {
    Write-Host "✓ Namespace fully deleted" -ForegroundColor Green
}

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "Cleanup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green

# Step 10: Delete Monitoring (optional)
Write-Host "`nStep 10: Deleting Monitoring Stack..." -ForegroundColor Yellow
$response = Read-Host "Do you want to delete Prometheus and Grafana? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    kubectl delete -f monitoring/grafana-service-nodeport.yaml 2>&1 | Out-Null
    kubectl delete -f monitoring/grafana-service.yaml 2>&1 | Out-Null
    kubectl delete -f monitoring/grafana-deployment.yaml 2>&1 | Out-Null
    kubectl delete -f monitoring/prometheus-service-nodeport.yaml 2>&1 | Out-Null
    kubectl delete -f monitoring/prometheus-service.yaml 2>&1 | Out-Null
    kubectl delete -f monitoring/prometheus-deployment.yaml 2>&1 | Out-Null
    kubectl delete -f monitoring/prometheus-configmap.yaml 2>&1 | Out-Null
    kubectl delete -f monitoring/prometheus-serviceaccount.yaml 2>&1 | Out-Null
    kubectl delete -f monitoring/prometheus-namespace.yaml 2>&1 | Out-Null
    Write-Host "✓ Monitoring stack deleted" -ForegroundColor Green
} else {
    Write-Host "⚠ Monitoring stack kept" -ForegroundColor Yellow
}

Write-Host "`nNote:" -ForegroundColor Yellow
Write-Host "  - Istio Service Mesh is still installed (if you want to remove it, run: istioctl uninstall --purge)" -ForegroundColor White
Write-Host "  - ArgoCD is still installed (if you want to remove it, delete the argocd namespace)" -ForegroundColor White

