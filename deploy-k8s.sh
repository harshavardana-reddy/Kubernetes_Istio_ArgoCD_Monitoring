#!/bin/bash

# Kubernetes Microservices Deployment Script
# This script deploys all microservices to Kubernetes

echo "Starting Kubernetes Microservices Deployment..."

# Create namespace
echo "Creating namespace..."
kubectl apply -f k8s-namespace.yaml

# Create ConfigMaps
echo "Creating ConfigMaps..."
kubectl apply -f k8s-configmap-admin.yaml
kubectl apply -f k8s-configmap-faculty.yaml
kubectl apply -f k8s-configmap-student.yaml
kubectl apply -f k8s-configmap-gateway.yaml

# Create Deployments
echo "Creating Deployments..."
kubectl apply -f k8s-deployment-admin.yaml
kubectl apply -f k8s-deployment-faculty.yaml
kubectl apply -f k8s-deployment-student.yaml
kubectl apply -f k8s-deployment-gateway.yaml

# Create Services
echo "Creating Services..."
kubectl apply -f k8s-service-admin.yaml
kubectl apply -f k8s-service-faculty.yaml
kubectl apply -f k8s-service-student.yaml
kubectl apply -f k8s-service-gateway.yaml

# Create Node Port 
echo "Creating Node Port Services..."
kubectl apply -f k8s-service-admin-nodeport.yaml
kubectl apply -f k8s-service-faculty-nodeport.yaml
kubectl apply -f k8s-service-student-nodeport.yaml
kubectl apply -f k8s-service-gateway-nodeport.yaml


# Create Ingress
echo "Creating Ingress..."
kubectl apply -f k8s-ingress.yaml

echo "Deployment completed!"
echo ""
echo "To check the status of your deployments:"
echo "kubectl get pods -n microservices"
echo "kubectl get services -n microservices"
echo "kubectl get ingress -n microservices"
echo ""
echo "To access the API Gateway externally:"
echo "kubectl port-forward -n microservices service/api-gateway 4000:4000"
echo "Then access: http://localhost:4000"
