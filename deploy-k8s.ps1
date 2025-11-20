# Kubernetes Microservices Deployment Script (PowerShell)
# This script deploys all microservices to Kubernetes

Write-Host "Starting Kubernetes Microservices Deployment..." -ForegroundColor Green

# Create namespace
Write-Host "Creating namespace..." -ForegroundColor Yellow
kubectl apply -f k8s-namespace.yaml

# Create ConfigMaps
Write-Host "Creating ConfigMaps..." -ForegroundColor Yellow
kubectl apply -f k8s-configmap-admin.yaml
kubectl apply -f k8s-configmap-faculty.yaml
kubectl apply -f k8s-configmap-student.yaml
kubectl apply -f k8s-configmap-gateway.yaml

# Create Deployments
Write-Host "Creating Deployments..." -ForegroundColor Yellow
kubectl apply -f k8s-deployment-admin.yaml
kubectl apply -f k8s-deployment-faculty.yaml
kubectl apply -f k8s-deployment-student.yaml
kubectl apply -f k8s-deployment-gateway.yaml

# Create Services
Write-Host "Creating Services..." -ForegroundColor Yellow
kubectl apply -f k8s-service-admin.yaml
kubectl apply -f k8s-service-faculty.yaml
kubectl apply -f k8s-service-student.yaml
kubectl apply -f k8s-service-gateway.yaml

# Create Ingress
Write-Host "Creating Ingress..." -ForegroundColor Yellow
kubectl apply -f k8s-ingress.yaml

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "To check the status of your deployments:" -ForegroundColor Cyan
Write-Host "kubectl get pods -n microservices" -ForegroundColor White
Write-Host "kubectl get services -n microservices" -ForegroundColor White
Write-Host "kubectl get ingress -n microservices" -ForegroundColor White
Write-Host ""
Write-Host "To access the API Gateway externally:" -ForegroundColor Cyan
Write-Host "kubectl port-forward -n microservices service/api-gateway 4000:4000" -ForegroundColor White
Write-Host "Then access: http://localhost:4000" -ForegroundColor White
