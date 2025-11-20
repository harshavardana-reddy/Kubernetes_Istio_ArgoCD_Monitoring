#!/bin/bash

set -e

echo "=========================================="
echo "Cleaning up Kubernetes with Istio, ArgoCD, and Autoscaler"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Confirmation prompt
read -p "Are you sure you want to delete all resources? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cleanup cancelled.${NC}"
    exit 0
fi

# Step 1: Delete ArgoCD Applications
echo -e "\n${YELLOW}Step 1: Deleting ArgoCD Applications...${NC}"
if kubectl get namespace argocd &> /dev/null; then
    kubectl delete -f argocd/application-microservices.yaml 2>/dev/null || true
    kubectl delete -f argocd/application-istio.yaml 2>/dev/null || true
    kubectl delete -f argocd/application-monitoring.yaml 2>/dev/null || true
    echo -e "${GREEN}✓ ArgoCD Applications deleted${NC}"
else
    echo -e "${YELLOW}⚠ ArgoCD namespace not found, skipping...${NC}"
fi

# Step 2: Delete Istio configurations
echo -e "\n${YELLOW}Step 2: Deleting Istio configurations...${NC}"
kubectl delete -f istio/peerauthentication.yaml 2>/dev/null || true
kubectl delete -f istio/destinationrule.yaml 2>/dev/null || true
kubectl delete -f istio/virtualservice.yaml 2>/dev/null || true
kubectl delete -f istio/gateway.yaml 2>/dev/null || true
echo -e "${GREEN}✓ Istio configurations deleted${NC}"

# Step 3: Delete Autoscaler
echo -e "\n${YELLOW}Step 3: Deleting Autoscaler...${NC}"
kubectl delete -f k8s-deployment-autoscaler.yaml 2>/dev/null || true
kubectl delete -f k8s-serviceaccount-autoscaler.yaml 2>/dev/null || true
echo -e "${GREEN}✓ Autoscaler deleted${NC}"

# Step 4: Delete NodePort Services
echo -e "\n${YELLOW}Step 4: Deleting NodePort Services...${NC}"
kubectl delete -f k8s-service-admin-nodeport.yaml 2>/dev/null || true
kubectl delete -f k8s-service-faculty-nodeport.yaml 2>/dev/null || true
kubectl delete -f k8s-service-student-nodeport.yaml 2>/dev/null || true
kubectl delete -f k8s-service-gateway-nodeport.yaml 2>/dev/null || true
echo -e "${GREEN}✓ NodePort Services deleted${NC}"

# Step 5: Delete ClusterIP Services
echo -e "\n${YELLOW}Step 5: Deleting ClusterIP Services...${NC}"
kubectl delete -f k8s-service-admin.yaml 2>/dev/null || true
kubectl delete -f k8s-service-faculty.yaml 2>/dev/null || true
kubectl delete -f k8s-service-student.yaml 2>/dev/null || true
kubectl delete -f k8s-service-gateway.yaml 2>/dev/null || true
echo -e "${GREEN}✓ ClusterIP Services deleted${NC}"

# Step 6: Delete Deployments
echo -e "\n${YELLOW}Step 6: Deleting Deployments...${NC}"
kubectl delete -f k8s-deployment-admin.yaml 2>/dev/null || true
kubectl delete -f k8s-deployment-faculty.yaml 2>/dev/null || true
kubectl delete -f k8s-deployment-student.yaml 2>/dev/null || true
kubectl delete -f k8s-deployment-gateway.yaml 2>/dev/null || true
echo -e "${GREEN}✓ Deployments deleted${NC}"

# Step 7: Delete ConfigMaps
echo -e "\n${YELLOW}Step 7: Deleting ConfigMaps...${NC}"
kubectl delete -f k8s-configmap-admin.yaml 2>/dev/null || true
kubectl delete -f k8s-configmap-faculty.yaml 2>/dev/null || true
kubectl delete -f k8s-configmap-student.yaml 2>/dev/null || true
kubectl delete -f k8s-configmap-gateway.yaml 2>/dev/null || true
echo -e "${GREEN}✓ ConfigMaps deleted${NC}"

# Step 8: Remove Istio injection label from namespace
echo -e "\n${YELLOW}Step 8: Removing Istio injection label...${NC}"
kubectl label namespace microservices istio-injection- 2>/dev/null || true
echo -e "${GREEN}✓ Istio injection label removed${NC}"

# Step 9: Delete namespace (this will remove all remaining resources)
echo -e "\n${YELLOW}Step 9: Deleting microservices namespace...${NC}"
kubectl delete -f k8s-namespace.yaml 2>/dev/null || true
echo -e "${GREEN}✓ Namespace deleted${NC}"

# Wait for namespace to be fully deleted
echo -e "\n${YELLOW}Waiting for namespace to be fully deleted...${NC}"
timeout=60
counter=0
while kubectl get namespace microservices &> /dev/null && [ $counter -lt $timeout ]; do
    sleep 2
    counter=$((counter + 2))
    echo -n "."
done
echo

if kubectl get namespace microservices &> /dev/null; then
    echo -e "${YELLOW}⚠ Namespace still exists. You may need to force delete it.${NC}"
    echo "  kubectl delete namespace microservices --force --grace-period=0"
else
    echo -e "${GREEN}✓ Namespace fully deleted${NC}"
fi

echo -e "\n${GREEN}=========================================="
echo "Cleanup Complete!"
echo "==========================================${NC}"

# Step 10: Delete Monitoring (optional)
echo -e "\n${YELLOW}Step 10: Deleting Monitoring Stack...${NC}"
read -p "Do you want to delete Prometheus and Grafana? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl delete -f monitoring/grafana-service-nodeport.yaml 2>/dev/null || true
    kubectl delete -f monitoring/grafana-service.yaml 2>/dev/null || true
    kubectl delete -f monitoring/grafana-deployment.yaml 2>/dev/null || true
    kubectl delete -f monitoring/prometheus-service-nodeport.yaml 2>/dev/null || true
    kubectl delete -f monitoring/prometheus-service.yaml 2>/dev/null || true
    kubectl delete -f monitoring/prometheus-deployment.yaml 2>/dev/null || true
    kubectl delete -f monitoring/prometheus-configmap.yaml 2>/dev/null || true
    kubectl delete -f monitoring/prometheus-serviceaccount.yaml 2>/dev/null || true
    kubectl delete -f monitoring/prometheus-namespace.yaml 2>/dev/null || true
    echo -e "${GREEN}✓ Monitoring stack deleted${NC}"
else
    echo -e "${YELLOW}⚠ Monitoring stack kept${NC}"
fi

echo -e "\n${YELLOW}Note:${NC}"
echo "  - Istio Service Mesh is still installed (if you want to remove it, run: istioctl uninstall --purge)"
echo "  - ArgoCD is still installed (if you want to remove it, delete the argocd namespace)"

