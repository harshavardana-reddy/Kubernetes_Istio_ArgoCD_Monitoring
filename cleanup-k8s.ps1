# Kubernetes Microservices Cleanup Script (PowerShell)
# This script removes all microservices from Kubernetes

Write-Host "Starting Kubernetes Microservices Cleanup..." -ForegroundColor Red

# Delete Ingress
Write-Host "Deleting Ingress..." -ForegroundColor Yellow
kubectl delete -f k8s-ingress.yaml

# Delete Services
Write-Host "Deleting Services..." -ForegroundColor Yellow
kubectl delete -f k8s-service-admin.yaml
kubectl delete -f k8s-service-faculty.yaml
kubectl delete -f k8s-service-student.yaml
kubectl delete -f k8s-service-gateway.yaml

# Delete Deployments
Write-Host "Deleting Deployments..." -ForegroundColor Yellow
kubectl delete -f k8s-deployment-admin.yaml
kubectl delete -f k8s-deployment-faculty.yaml
kubectl delete -f k8s-deployment-student.yaml
kubectl delete -f k8s-deployment-gateway.yaml

# Delete ConfigMaps
Write-Host "Deleting ConfigMaps..." -ForegroundColor Yellow
kubectl delete -f k8s-configmap-admin.yaml
kubectl delete -f k8s-configmap-faculty.yaml
kubectl delete -f k8s-configmap-student.yaml
kubectl delete -f k8s-configmap-gateway.yaml

# Delete namespace (this will remove all remaining resources)
Write-Host "Deleting namespace..." -ForegroundColor Yellow
kubectl delete -f k8s-namespace.yaml

Write-Host "Cleanup completed!" -ForegroundColor Green
Write-Host "All microservices have been removed from Kubernetes." -ForegroundColor Green
