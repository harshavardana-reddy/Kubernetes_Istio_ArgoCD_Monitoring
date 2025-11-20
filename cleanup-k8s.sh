#!/bin/bash

# Kubernetes Microservices Cleanup Script
# This script removes all microservices from Kubernetes

echo "Starting Kubernetes Microservices Cleanup..."

# Delete Ingress
echo "Deleting Ingress..."
kubectl delete -f k8s-ingress.yaml

# Delete Services
echo "Deleting Services..."
kubectl delete -f k8s-service-admin.yaml
kubectl delete -f k8s-service-faculty.yaml
kubectl delete -f k8s-service-student.yaml
kubectl delete -f k8s-service-gateway.yaml

# Delete Deployments
echo "Deleting Deployments..."
kubectl delete -f k8s-deployment-admin.yaml
kubectl delete -f k8s-deployment-faculty.yaml
kubectl delete -f k8s-deployment-student.yaml
kubectl delete -f k8s-deployment-gateway.yaml

# Delete ConfigMaps
echo "Deleting ConfigMaps..."
kubectl delete -f k8s-configmap-admin.yaml
kubectl delete -f k8s-configmap-faculty.yaml
kubectl delete -f k8s-configmap-student.yaml
kubectl delete -f k8s-configmap-gateway.yaml

# Delete namespace (this will remove all remaining resources)
echo "Deleting namespace..."
kubectl delete -f k8s-namespace.yaml

echo "Cleanup completed!"
echo "All microservices have been removed from Kubernetes."
