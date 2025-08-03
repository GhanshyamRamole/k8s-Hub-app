#!/bin/bash
# setup-monitoring.sh - Complete monitoring stack setup

set -e

CLUSTER_NAME="k8s-hub-cluster"
REGION="us-east-1"
NAMESPACE="monitoring"

echo "📊 Setting up monitoring stack..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Verify cluster connection
verify_cluster() {
    log "Verifying cluster connection..."
    if ! kubectl cluster-info &>/dev/null; then
        echo "❌ Cannot connect to cluster. Updating kubeconfig..."
        aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    fi
    log "✅ Connected to cluster: $(kubectl config current-context)"
}

# Create monitoring namespace
create_namespace() {
    log "Creating monitoring namespace..."
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
}

# Add Helm repositories
add_helm_repos() {
    log "Adding Helm repositories..."
    helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    helm repo add grafana https://grafana.github.io/helm-charts
    helm repo add stable https://charts.helm.sh/stable
    helm repo update
}

# Install Prometheus Stack
install_prometheus_stack() {
    log "Installing Prometheus Stack..."
    
    # Create values file for Prometheus
    cat > prometheus-values.yaml <<EOF
prometheus:
  prometheusSpec:
    retention: 30d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi

grafana:
  adminPassword: admin123
  service:
    type: LoadBalancer
  persistence:
    enabled: true
    storageClassName: gp2
    size: 10Gi
  
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default'
        orgId: 1
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default

  dashboards:
    default:
      kubernetes-cluster-monitoring:
        gnetId: 7249
        revision: 1
        datasource: Prometheus
      kubernetes-pod-monitoring:
        gnetId: 6417
        revision: 1
        datasource: Prometheus
      node-exporter:
        gnetId: 1860
        revision: 27
        datasource: Prometheus

alertmanager:
  alertmanagerSpec:
    storage:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 10Gi

nodeExporter:
  enabled: true

kubeStateMetrics:
  enabled: true
EOF

    # Install Prometheus Stack
    helm upgrade --install prometheus-stack prometheus-community/kube-prometheus-stack \
        --namespace $NAMESPACE \
        --values prometheus-values.yaml \
        --wait \
        --timeout 10m
    
    log "Prometheus Stack installed successfully"
}

# Install additional monitoring tools
install_additional_tools() {
    log "Installing additional monitoring tools..."
    
    # Install Jaeger for distributed tracing
    kubectl create namespace jaeger-system --dry-run=client -o yaml | kubectl apply -f -
    kubectl apply -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.47.0/jaeger-operator.yaml -n jaeger-system
    
    # Wait for operator to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/jaeger-operator -n jaeger-system
    
    # Create Jaeger instance
    cat > jaeger-instance.yaml <<EOF
apiVersion: jaegertracing.io/v1
kind: Jaeger
metadata:
  name: jaeger
  namespace: $NAMESPACE
spec:
  strategy: production
  storage:
    type: elasticsearch
    elasticsearch:
      nodeCount: 1
      storage:
        storageClassName: gp2
        size: 10Gi
EOF
    
    kubectl apply -f jaeger-instance.yaml
    
    log "Additional monitoring tools installed"
}

# Setup service monitors
setup_service_monitors() {
    log "Setting up service monitors..."
    
    # Create service monitor for the application
    cat > k8s-hub-servicemonitor.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: k8s-hub-monitor
  namespace: $NAMESPACE
  labels:
    app: k8s-hub
spec:
  selector:
    matchLabels:
      app: k8s-hub
  endpoints:
  - port: http
    interval: 30s
    path: /metrics
EOF
    
    kubectl apply -f k8s-hub-servicemonitor.yaml
    
    log "Service monitors configured"
}

# Configure alerting rules
configure_alerting() {
    log "Configuring alerting rules..."
    
    cat > alerting-rules.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: k8s-hub-alerts
  namespace: $NAMESPACE
  labels:
    prometheus: kube-prometheus
    role: alert-rules
spec:
  groups:
  - name: k8s-hub.rules
    rules:
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ \$labels.pod }} is crash looping"
        description: "Pod {{ \$labels.pod }} in namespace {{ \$labels.namespace }} is restarting frequently"
    
    - alert: HighMemoryUsage
      expr: (container_memory_usage_bytes / container_spec_memory_limit_bytes) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected"
        description: "Container {{ \$labels.container }} in pod {{ \$labels.pod }} is using more than 80% of its memory limit"
    
    - alert: HighCPUUsage
      expr: (rate(container_cpu_usage_seconds_total[5m]) / container_spec_cpu_quota * container_spec_cpu_period) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected"
        description: "Container {{ \$labels.container }} in pod {{ \$labels.pod }} is using more than 80% of its CPU limit"
EOF
    
    kubectl apply -f alerting-rules.yaml
    
    log "Alerting rules configured"
}

# Get access information
get_access_info() {
    log "Getting access information..."
    
    # Wait for services to be ready
    kubectl wait --for=condition=available --timeout=300s deployment/prometheus-stack-grafana -n $NAMESPACE
    
    # Get Grafana URL
    GRAFANA_URL=$(kubectl get svc prometheus-stack-grafana -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "$GRAFANA_URL" ]; then
        GRAFANA_URL=$(kubectl get svc prometheus-stack-grafana -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    # Get Prometheus URL
    kubectl port-forward svc/prometheus-stack-kube-prom-prometheus -n $NAMESPACE 9090:9090 &
    PROMETHEUS_PID=$!
    
    # Get AlertManager URL
    kubectl port-forward svc/prometheus-stack-kube-prom-alertmanager -n $NAMESPACE 9093:9093 &
    ALERTMANAGER_PID=$!
    
    echo ""
    log "🎉 Monitoring stack deployed successfully!"
    echo ""
    echo "📊 Access URLs:"
    echo "  Grafana: http://$GRAFANA_URL (admin/admin123)"
    echo "  Prometheus: http://localhost:9090 (port-forward active)"
    echo "  AlertManager: http://localhost:9093 (port-forward active)"
    echo ""
    echo "📋 Useful Commands:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl get svc -n $NAMESPACE"
    echo "  kubectl logs -f deployment/prometheus-stack-grafana -n $NAMESPACE"
    echo ""
    echo "🔧 To stop port-forwards:"
    echo "  kill $PROMETHEUS_PID $ALERTMANAGER_PID"
}

# Setup log aggregation
setup_logging() {
    log "Setting up log aggregation with ELK stack..."
    
    # Add Elastic Helm repo
    helm repo add elastic https://helm.elastic.co
    helm repo update
    
    # Install Elasticsearch
    helm upgrade --install elasticsearch elastic/elasticsearch \
        --namespace $NAMESPACE \
        --set replicas=1 \
        --set minimumMasterNodes=1 \
        --set volumeClaimTemplate.resources.requests.storage=10Gi \
        --wait \
        --timeout 10m
    
    # Install Kibana
    helm upgrade --install kibana elastic/kibana \
        --namespace $NAMESPACE \
        --set service.type=LoadBalancer \
        --wait \
        --timeout 10m
    
    # Install Filebeat
    helm upgrade --install filebeat elastic/filebeat \
        --namespace $NAMESPACE \
        --wait \
        --timeout 10m
    
    log "ELK stack installed successfully"
}

# Main function
main() {
    verify_cluster
    create_namespace
    add_helm_repos
    install_prometheus_stack
    setup_service_monitors
    configure_alerting
    setup_logging
    get_access_info
    
    # Cleanup temporary files
    rm -f prometheus-values.yaml k8s-hub-servicemonitor.yaml alerting-rules.yaml jaeger-instance.yaml
    
    log "Monitoring setup completed successfully!"
}

# Run main function
main "$@"
