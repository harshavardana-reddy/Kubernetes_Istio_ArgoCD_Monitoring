#!/bin/bash

# Health Check Test Script for Microservices Dashboard
# This script tests all the health endpoints that the dashboard monitors

echo "🔍 Testing Microservices Health Endpoints..."
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to test health endpoint
test_health_endpoint() {
    local service_name=$1
    local url=$2
    local timeout=${3:-10}
    
    echo -n "Testing $service_name... "
    
    response=$(curl -s -w "%{http_code}" -o /dev/null --max-time $timeout "$url" 2>/dev/null)
    
    if [ "$response" = "200" ]; then
        echo -e "${GREEN}✓ Healthy${NC}"
        return 0
    else
        echo -e "${RED}✗ Unhealthy (HTTP $response)${NC}"
        return 1
    fi
}

# Test Kubernetes Services (NodePort)
echo -e "\n${YELLOW}Kubernetes Services (NodePort):${NC}"
test_health_endpoint "API Gateway" "http://localhost:80/actuator/health"
test_health_endpoint "Admin Service" "http://localhost:80/admin/actuator/health"
test_health_endpoint "Faculty Service" "http://localhost:80/faculty/actuator/health"
test_health_endpoint "Student Service" "http://localhost:80/student/actuator/health"

# Test Eureka Server (Render Cloud)
echo -e "\n${YELLOW}Cloud Services:${NC}"
test_health_endpoint "Eureka Server" "https://microservices-eureka-registry.onrender.com/eureka/apps" 15

echo -e "\n${YELLOW}Additional Tests:${NC}"

# Test Eureka Dashboard
echo -n "Testing Eureka Dashboard... "
eureka_response=$(curl -s -w "%{http_code}" -o /dev/null --max-time 15 "https://microservices-eureka-registry.onrender.com/eureka/apps" 2>/dev/null)
if [ "$eureka_response" = "200" ]; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible (HTTP $eureka_response)${NC}"
fi

# Test Kubernetes cluster connectivity
echo -n "Testing Kubernetes cluster... "
if command -v kubectl &> /dev/null; then
    if kubectl get services -n microservices &> /dev/null; then
        echo -e "${GREEN}✓ Cluster accessible${NC}"
    else
        echo -e "${RED}✗ Cluster not accessible${NC}"
    fi
else
    echo -e "${YELLOW}⚠ kubectl not found${NC}"
fi

echo -e "\n${YELLOW}Dashboard URLs:${NC}"
# echo "• Health Dashboard: http://localhost:5173"
echo "• Eureka Dashboard: https://microservices-eureka-registry.onrender.com/"
echo "• Kubernetes Dashboard: Check your cluster configuration"

echo -e "\n${YELLOW}Troubleshooting Tips:${NC}"
echo "• Ensure Kubernetes cluster is running"
echo "• Verify NodePort services are deployed"
echo "• Check if pods are running: kubectl get pods -n microservices"
echo "• Verify services: kubectl get services -n microservices"
echo "• Check Eureka Server status on Render"

echo -e "\n✅ Health check test completed!"
