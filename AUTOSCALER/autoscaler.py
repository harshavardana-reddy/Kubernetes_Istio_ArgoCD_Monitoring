import os
import math
import time
from kubernetes import client, config
from prometheus_api_client import PrometheusConnect
from typing import Tuple

class MicroserviceAutoscaler:
    def __init__(self):
        # Configuration from environment variables
        self.latency_threshold_ms = int(os.getenv("LATENCY_THRESHOLD_MS", 300))
        self.cpu_threshold = float(os.getenv("CPU_THRESHOLD", 0.7))
        self.rps_threshold = int(os.getenv("RPS_THRESHOLD", 200))
        self.scale_out_factor = float(os.getenv("SCALE_OUT_FACTOR", 0.2))
        self.scale_in_factor = float(os.getenv("SCALE_IN_FACTOR", 0.15))
        self.min_replicas = int(os.getenv("MIN_REPLICAS", 2))
        
        # Initialize Kubernetes client
        config.load_incluster_config()
        self.apps_v1 = client.AppsV1Api()
        
        # Initialize Prometheus client
        self.prom = PrometheusConnect(url="http://prometheus-server.monitoring.svc.cluster.local:9090")
    
    def get_metrics_from_prometheus(self, service_name: str) -> Tuple[float, float, float]:
        """Get current latency, CPU usage, and RPS from Prometheus"""
        try:
            # Get p95 latency
            latency_query = f'histogram_quantile(0.95, sum(rate(istio_request_duration_milliseconds_bucket{{destination_service=~"{service_name}.*"}}[1m])) by (le))'
            latency_result = self.prom.custom_query(latency_query)
            current_latency = float(latency_result[0]['value'][1]) if latency_result else 0
            
            # Get CPU usage
            cpu_query = f'sum(rate(container_cpu_usage_seconds_total{{container="{service_name}"}}[1m])) / sum(kube_pod_container_resource_limits{{resource="cpu", container="{service_name}"}})'
            cpu_result = self.prom.custom_query(cpu_query)
            current_cpu = float(cpu_result[0]['value'][1]) if cpu_result else 0
            
            # Get requests per second
            rps_query = f'sum(rate(istio_requests_total{{destination_service=~"{service_name}.*"}}[1m]))'
            rps_result = self.prom.custom_query(rps_query)
            current_rps = float(rps_result[0]['value'][1]) if rps_result else 0
            
            return current_latency, current_cpu, current_rps
            
        except Exception as e:
            print(f"Error getting metrics from Prometheus: {e}")
            return 0, 0, 0
    
    def get_current_replicas(self, deployment_name: str, namespace: str = "default") -> int:
        """Get current replica count for a deployment"""
        try:
            deployment = self.apps_v1.read_namespaced_deployment(
                name=deployment_name,
                namespace=namespace
            )
            return deployment.status.replicas if deployment.status.replicas else 0
        except Exception as e:
            print(f"Error getting current replicas: {e}")
            return 0
    
    def scale_deployment(self, deployment_name: str, replicas: int, namespace: str = "default") -> bool:
        """Scale a deployment to the specified number of replicas"""
        try:
            # Get current deployment
            deployment = self.apps_v1.read_namespaced_deployment(
                name=deployment_name,
                namespace=namespace
            )
            
            # Ensure we don't scale below min_replicas or above max_replicas
            replicas = max(self.min_replicas, replicas)
            replicas = min(int(os.getenv("MAX_REPLICAS", 50)), replicas)
            
            # Update replica count
            deployment.spec.replicas = replicas
            
            # Patch the deployment
            self.apps_v1.patch_namespaced_deployment(
                name=deployment_name,
                namespace=namespace,
                body=deployment
            )
            
            print(f"Scaled {deployment_name} to {replicas} replicas")
            return True
            
        except Exception as e:
            print(f"Error scaling deployment: {e}")
            return False
    
    def adjust_replicas(self, service_name: str, deployment_name: str):
        """Main autoscaling logic based on the paper's algorithm"""
        # Get current metrics
        current_latency, current_cpu, current_rps = self.get_metrics_from_prometheus(service_name)
        current_replicas = self.get_current_replicas(deployment_name)
        
        print(f"Current metrics for {service_name}: Latency={current_latency}ms, CPU={current_cpu*100:.1f}%, RPS={current_rps:.1f}, Replicas={current_replicas}")
        
        # Implement the paper's algorithm
        if (current_latency > self.latency_threshold_ms or 
            current_cpu > self.cpu_threshold or 
            current_rps > self.rps_threshold):
            
            new_replicas = math.ceil(current_replicas * (1 + self.scale_out_factor))
            print(f"Scaling out: {current_replicas} -> {new_replicas}")
            self.scale_deployment(deployment_name, new_replicas)
            
        elif (current_latency < 0.69 * self.latency_threshold_ms and 
              current_cpu < 0.69 * self.cpu_threshold):
            
            new_replicas = max(self.min_replicas, math.floor(current_replicas * (1 - self.scale_in_factor)))
            print(f"Scaling in: {current_replicas} -> {new_replicas}")
            self.scale_deployment(deployment_name, new_replicas)
        
        else:
            print("No scaling needed - metrics within thresholds")

def main():
    autoscaler = MicroserviceAutoscaler()
    
    # List of services to monitor and their corresponding deployments
    services = [
        {"service_name": "admin-service", "deployment_name": "admin-service"},
        {"service_name": "faculty-service", "deployment_name": "faculty-service"},
        {"service_name": "student-service", "deployment_name": "student-service"}
    ]
    
    while True:
        for service in services:
            autoscaler.adjust_replicas(
                service["service_name"],
                service["deployment_name"]
            )
        
        # Sleep for 30 seconds before next check
        time.sleep(30)

if __name__ == "__main__":
    main()