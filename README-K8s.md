# Kubernetes Microservices Deployment Guide

This repository contains Kubernetes manifests for deploying a microservices architecture with the following services:

- **Admin Service** (Port 4001)
- **Faculty Service** (Port 4002)
- **Student Service** (Port 4003)
- **API Gateway** (Port 4000) - Externally accessible

## Prerequisites

### For Production Kubernetes Cluster:

1. Kubernetes cluster running
2. kubectl configured to access your cluster
3. Docker images built and available (or use a container registry)
4. NGINX Ingress Controller installed (for external access)

### For Minikube (Local Development):

1. Minikube installed and running
2. kubectl configured to access Minikube
3. Docker images built and available (or use a container registry)
4. NGINX Ingress addon enabled in Minikube

## Architecture

```
Internet → NGINX Ingress → API Gateway → Microservices
                              ↓
                    Admin Service (4001)
                    Faculty Service (4002)
                    Student Service (4003)
```

## Services Configuration

All services are configured to:

- Register with Eureka Server at `https://microservices-eureka-registry.onrender.com/`
- Use MySQL database hosted on Aiven Cloud
- Send traces to Jaeger (if Istio is installed)
- Expose health check endpoints

## Deployment Steps

### Option 1: Automated Deployment

#### For Production Kubernetes Cluster:

```bash
# Linux/Mac
chmod +x deploy-k8s.sh
./deploy-k8s.sh

# Windows PowerShell
./deploy-k8s.ps1
```

#### For Minikube (Local Development):

```bash
# Linux/Mac
chmod +x deploy-minikube.sh
./deploy-minikube.sh

# Windows PowerShell
./deploy-minikube.ps1
```

### Option 2: Manual Deployment

#### For Production Kubernetes Cluster:

```bash
# 1. Create namespace
kubectl apply -f k8s-namespace.yaml

# 2. Create ConfigMaps
kubectl apply -f k8s-configmap-admin.yaml
kubectl apply -f k8s-configmap-faculty.yaml
kubectl apply -f k8s-configmap-student.yaml
kubectl apply -f k8s-configmap-gateway.yaml

# 3. Create Deployments
kubectl apply -f k8s-deployment-admin.yaml
kubectl apply -f k8s-deployment-faculty.yaml
kubectl apply -f k8s-deployment-student.yaml
kubectl apply -f k8s-deployment-gateway.yaml

# 4. Create Services
kubectl apply -f k8s-service-admin.yaml
kubectl apply -f k8s-service-faculty.yaml
kubectl apply -f k8s-service-student.yaml
kubectl apply -f k8s-service-gateway.yaml

# 5. Create Ingress
kubectl apply -f k8s-ingress.yaml
```

#### For Minikube (Local Development):

```bash
# 1. Start Minikube and enable ingress
minikube start --driver=docker --memory=4096 --cpus=2
minikube addons enable ingress

# 2. Create namespace
kubectl apply -f k8s-namespace.yaml

# 3. Create ConfigMaps
kubectl apply -f k8s-configmap-admin.yaml
kubectl apply -f k8s-configmap-faculty.yaml
kubectl apply -f k8s-configmap-student.yaml
kubectl apply -f k8s-configmap-gateway.yaml

# 4. Create Deployments
kubectl apply -f k8s-deployment-admin.yaml
kubectl apply -f k8s-deployment-faculty.yaml
kubectl apply -f k8s-deployment-student.yaml
kubectl apply -f k8s-deployment-gateway.yaml

# 5. Create ClusterIP Services
kubectl apply -f k8s-service-admin.yaml
kubectl apply -f k8s-service-faculty.yaml
kubectl apply -f k8s-service-student.yaml
kubectl apply -f k8s-service-gateway.yaml

# 6. Create NodePort Services for external access
kubectl apply -f k8s-service-admin-nodeport.yaml
kubectl apply -f k8s-service-faculty-nodeport.yaml
kubectl apply -f k8s-service-student-nodeport.yaml
kubectl apply -f k8s-service-gateway-nodeport.yaml

# 7. Create Ingress
kubectl apply -f k8s-ingress-minikube.yaml
```

## Verification

Check deployment status:

```bash
kubectl get pods -n microservices
kubectl get services -n microservices
kubectl get ingress -n microservices
```

## Accessing Services

### Production Kubernetes Cluster

#### External Access (via Ingress)

- API Gateway: `http://microservices.local/` or `http://<ingress-ip>/`
- Admin Service: `http://microservices.local/admin/`
- Faculty Service: `http://microservices.local/faculty/`
- Student Service: `http://microservices.local/student/`

#### Port Forwarding (for testing)

```bash
# API Gateway
kubectl port-forward -n microservices service/api-gateway 4000:4000

# Admin Service
kubectl port-forward -n microservices service/admin-service 4001:4001

# Faculty Service
kubectl port-forward -n microservices service/faculty-service 4002:4002

# Student Service
kubectl port-forward -n microservices service/student-service 4003:4003
```

### Minikube (Local Development)

#### NodePort Access (Direct)

```bash
# Get Minikube IP
minikube ip

# Access services directly via NodePort
# API Gateway: http://$(minikube ip):30000
# Admin Service: http://$(minikube ip):30001
# Faculty Service: http://$(minikube ip):30002
# Student Service: http://$(minikube ip):30003
```

#### Ingress Access (Recommended)

1. Add Minikube IP to hosts file:

   ```bash
   # Get Minikube IP
   minikube ip

   # Add to /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
   # <minikube-ip> microservices.local
   ```

2. Access services via Ingress:
   - API Gateway: `http://microservices.local/`
   - Admin Service: `http://microservices.local/admin/`
   - Faculty Service: `http://microservices.local/faculty/`
   - Student Service: `http://microservices.local/student/`

#### Port Forwarding (for testing)

```bash
# API Gateway
kubectl port-forward -n microservices service/api-gateway 4000:4000

# Admin Service
kubectl port-forward -n microservices service/admin-service 4001:4001

# Faculty Service
kubectl port-forward -n microservices service/faculty-service 4002:4002

# Student Service
kubectl port-forward -n microservices service/student-service 4003:4003
```

#### Minikube Dashboard

```bash
minikube dashboard
```

## Health Checks

All services expose health check endpoints:

- Admin Service: `/admin/actuator/health`
- Faculty Service: `/faculty/actuator/health`
- Student Service: `/student/actuator/health`
- API Gateway: `/actuator/health`

## Scaling

To scale services:

```bash
kubectl scale deployment admin-service --replicas=3 -n microservices
kubectl scale deployment faculty-service --replicas=3 -n microservices
kubectl scale deployment student-service --replicas=3 -n microservices
kubectl scale deployment api-gateway --replicas=3 -n microservices
```

## Troubleshooting

### Check logs

```bash
kubectl logs -n microservices deployment/admin-service
kubectl logs -n microservices deployment/faculty-service
kubectl logs -n microservices deployment/student-service
kubectl logs -n microservices deployment/api-gateway
```

### Check service discovery

```bash
kubectl exec -n microservices deployment/api-gateway -- curl http://admin-service:4001/admin/actuator/health
```

### Restart deployments

```bash
kubectl rollout restart deployment/admin-service -n microservices
kubectl rollout restart deployment/faculty-service -n microservices
kubectl rollout restart deployment/student-service -n microservices
kubectl rollout restart deployment/api-gateway -n microservices
```

## Cleanup

### Production Kubernetes Cluster

To remove all resources:

```bash
# Linux/Mac
chmod +x cleanup-k8s.sh
./cleanup-k8s.sh

# Windows PowerShell
./cleanup-k8s.ps1

# Or manually
kubectl delete namespace microservices
```

### Minikube (Local Development)

To remove all resources:

```bash
# Linux/Mac
chmod +x cleanup-minikube.sh
./cleanup-minikube.sh

# Windows PowerShell
./cleanup-minikube.ps1

# Or manually
kubectl delete namespace microservices
```

To stop or delete Minikube:

```bash
# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## Notes

- The Eureka server is running externally at `https://microservices-eureka-registry.onrender.com/`
- All services are configured with proper health checks and resource limits
- The API Gateway is the only service exposed externally through the Ingress
- Internal service communication uses Kubernetes service discovery

### Minikube-Specific Notes

- Minikube uses NodePort services (30000-30003) for external access
- NGINX Ingress addon must be enabled: `minikube addons enable ingress`
- Minikube IP can be obtained with: `minikube ip`
- For Ingress to work, add Minikube IP to your hosts file
- Minikube dashboard provides a web UI for cluster management
- All Docker images should be available in Minikube's Docker daemon
