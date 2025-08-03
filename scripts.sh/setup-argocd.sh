#!/bin/bash
# setup-argocd.sh - ArgoCD GitOps setup script

set -e

CLUSTER_NAME="k8s-hub-cluster"
REGION="us-east-1"
NAMESPACE="argocd"
APP_NAMESPACE="k8s-hub"

echo "🚀 Setting up ArgoCD GitOps..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
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

# Create ArgoCD namespace
create_namespace() {
    log "Creating ArgoCD namespace..."
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
    kubectl create namespace $APP_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
}

# Install ArgoCD
install_argocd() {
    log "Installing ArgoCD..."
    
    # Install ArgoCD
    kubectl apply -n $NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    
    # Wait for ArgoCD to be ready
    log "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-server -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-repo-server -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=600s deployment/argocd-dex-server -n $NAMESPACE
    
    log "ArgoCD installed successfully"
}

# Configure ArgoCD server
configure_argocd_server() {
    log "Configuring ArgoCD server..."
    
    # Patch ArgoCD server to use LoadBalancer
    kubectl patch svc argocd-server -n $NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'
    
    # Configure ArgoCD to work with insecure connections (for demo purposes)
    kubectl patch configmap argocd-cmd-params-cm -n $NAMESPACE --type merge -p '{"data":{"server.insecure":"true"}}'
    
    # Restart ArgoCD server to apply changes
    kubectl rollout restart deployment/argocd-server -n $NAMESPACE
    kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $NAMESPACE
    
    log "ArgoCD server configured"
}

# Get ArgoCD admin password
get_argocd_password() {
    log "Getting ArgoCD admin password..."
    
    # Wait for secret to be created
    kubectl wait --for=condition=complete --timeout=300s -n $NAMESPACE --selector=app.kubernetes.io/name=argocd-server job || true
    
    # Get the password
    ARGOCD_PASSWORD=$(kubectl -n $NAMESPACE get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
    
    if [ -z "$ARGOCD_PASSWORD" ]; then
        warn "Could not retrieve ArgoCD password automatically. Using default: admin"
        ARGOCD_PASSWORD="admin"
    fi
    
    echo "$ARGOCD_PASSWORD" > argocd-password.txt
    log "ArgoCD password saved to argocd-password.txt"
}

# Create ArgoCD application
create_argocd_application() {
    log "Creating ArgoCD application..."
    
    cat > k8s-hub-application.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: k8s-hub
  namespace: $NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/GhanshyamRamole/k8s-Hub-app.git
    targetRevision: main
    path: K8s-files
  destination:
    server: https://kubernetes.default.svc
    namespace: $APP_NAMESPACE
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
      allowEmpty: false
    syncOptions:
    - CreateNamespace=true
    - PrunePropagationPolicy=foreground
    - PruneLast=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF
    
    kubectl apply -f k8s-hub-application.yaml
    log "ArgoCD application created"
}

# Create ArgoCD project
create_argocd_project() {
    log "Creating ArgoCD project..."
    
    cat > k8s-hub-project.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: k8s-hub-project
  namespace: $NAMESPACE
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  description: Kubernetes Hub Project
  sourceRepos:
  - 'https://github.com/GhanshyamRamole/k8s-Hub-app.git'
  destinations:
  - namespace: $APP_NAMESPACE
    server: https://kubernetes.default.svc
  - namespace: $NAMESPACE
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  - group: 'rbac.authorization.k8s.io'
    kind: ClusterRole
  - group: 'rbac.authorization.k8s.io'
    kind: ClusterRoleBinding
  namespaceResourceWhitelist:
  - group: ''
    kind: Service
  - group: ''
    kind: ConfigMap
  - group: ''
    kind: Secret
  - group: 'apps'
    kind: Deployment
  - group: 'apps'
    kind: ReplicaSet
  - group: ''
    kind: Pod
  roles:
  - name: admin
    description: Admin role for k8s-hub project
    policies:
    - p, proj:k8s-hub-project:admin, applications, *, k8s-hub-project/*, allow
    - p, proj:k8s-hub-project:admin, repositories, *, *, allow
    groups:
    - k8s-hub:admin
EOF
    
    kubectl apply -f k8s-hub-project.yaml
    log "ArgoCD project created"
}

# Setup ArgoCD CLI
setup_argocd_cli() {
    log "Setting up ArgoCD CLI..."
    
    # Get ArgoCD server URL
    ARGOCD_SERVER=$(kubectl get svc argocd-server -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "$ARGOCD_SERVER" ]; then
        ARGOCD_SERVER=$(kubectl get svc argocd-server -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    if [ -z "$ARGOCD_SERVER" ]; then
        warn "LoadBalancer not ready yet. Using port-forward for CLI setup."
        kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443 &
        PORTFORWARD_PID=$!
        ARGOCD_SERVER="localhost:8080"
        sleep 5
    fi
    
    # Login to ArgoCD
    log "Logging into ArgoCD..."
    argocd login $ARGOCD_SERVER --username admin --password $ARGOCD_PASSWORD --insecure
    
    # Add repository
    argocd repo add https://github.com/GhanshyamRamole/k8s-Hub-app.git --type git --name k8s-hub-repo
    
    # Kill port-forward if it was used
    if [ ! -z "$PORTFORWARD_PID" ]; then
        kill $PORTFORWARD_PID 2>/dev/null || true
    fi
    
    log "ArgoCD CLI configured successfully"
}

# Create monitoring for ArgoCD
setup_argocd_monitoring() {
    log "Setting up ArgoCD monitoring..."
    
    cat > argocd-servicemonitor.yaml <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-metrics
  namespace: monitoring
  labels:
    app.kubernetes.io/name: argocd-metrics
    app.kubernetes.io/part-of: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-metrics
  endpoints:
  - port: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-server-metrics
  namespace: monitoring
  labels:
    app.kubernetes.io/name: argocd-server-metrics
    app.kubernetes.io/part-of: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-server-metrics
  endpoints:
  - port: metrics
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: argocd-repo-server-metrics
  namespace: monitoring
  labels:
    app.kubernetes.io/name: argocd-repo-server
    app.kubernetes.io/part-of: argocd
spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: argocd-repo-server
  endpoints:
  - port: metrics
EOF
    
    kubectl apply -f argocd-servicemonitor.yaml
    log "ArgoCD monitoring configured"
}

# Create RBAC for ArgoCD
setup_rbac() {
    log "Setting up RBAC for ArgoCD..."
    
    cat > argocd-rbac.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-rbac-cm
  namespace: $NAMESPACE
  labels:
    app.kubernetes.io/name: argocd-rbac-cm
    app.kubernetes.io/part-of: argocd
data:
  policy.default: role:readonly
  policy.csv: |
    p, role:admin, applications, *, */*, allow
    p, role:admin, clusters, *, *, allow
    p, role:admin, repositories, *, *, allow
    p, role:admin, certificates, *, *, allow
    p, role:admin, projects, *, *, allow
    p, role:admin, accounts, *, *, allow
    p, role:admin, gpgkeys, *, *, allow
    p, role:admin, logs, *, *, allow
    p, role:admin, exec, *, *, allow
    g, k8s-hub:admin, role:admin
  scopes: '[groups]'
EOF
    
    kubectl apply -f argocd-rbac.yaml
    
    # Restart ArgoCD server to apply RBAC changes
    kubectl rollout restart deployment/argocd-server -n $NAMESPACE
    
    log "RBAC configured for ArgoCD"
}

# Get access information
get_access_info() {
    log "Getting ArgoCD access information..."
    
    # Get ArgoCD server URL
    ARGOCD_SERVER=$(kubectl get svc argocd-server -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -z "$ARGOCD_SERVER" ]; then
        ARGOCD_SERVER=$(kubectl get svc argocd-server -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    
    if [ -z "$ARGOCD_SERVER" ]; then
        warn "LoadBalancer not ready. Use port-forward to access ArgoCD:"
        echo "kubectl port-forward svc/argocd-server -n $NAMESPACE 8080:443"
        ARGOCD_SERVER="localhost:8080"
    fi
    
    echo ""
    log "🎉 ArgoCD setup completed successfully!"
    echo ""
    echo "🌐 Access Information:"
    echo "  ArgoCD UI: https://$ARGOCD_SERVER"
    echo "  Username: admin"
    echo "  Password: $ARGOCD_PASSWORD"
    echo ""
    echo "📋 Useful Commands:"
    echo "  kubectl get applications -n $NAMESPACE"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  argocd app list"
    echo "  argocd app sync k8s-hub"
    echo "  argocd app get k8s-hub"
    echo ""
    echo "🔧 Application Status:"
    kubectl get application k8s-hub -n $NAMESPACE -o wide 2>/dev/null || echo "Application not yet synced"
}

# Main function
main() {
    verify_cluster
    create_namespace
    install_argocd
    configure_argocd_server
    get_argocd_password
    create_argocd_project
    create_argocd_application
    setup_argocd_cli
    setup_argocd_monitoring
    setup_rbac
    get_access_info
    
    # Cleanup temporary files
    rm -f k8s-hub-application.yaml k8s-hub-project.yaml argocd-servicemonitor.yaml argocd-rbac.yaml
    
    log "ArgoCD GitOps setup completed successfully!"
}

# Run main function
main "$@"
