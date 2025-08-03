#!/bin/bash
# cleanup.sh - Complete cleanup script for both DevOps implementations

set -e

CLUSTER_NAME="k8s-hub-cluster"
REGION="us-east-1"
STACK_NAME="k8s-hub-infrastructure"

echo "🧹 Starting comprehensive cleanup process..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Confirm cleanup
confirm_cleanup() {
    echo ""
    warn "This will delete ALL resources including:"
    echo "  - EKS Cluster: $CLUSTER_NAME"
    echo "  - CloudFormation Stack: $STACK_NAME"
    echo "  - All Kubernetes resources"
    echo "  - All monitoring components"
    echo "  - ArgoCD installation"
    echo ""
    read -p "Are you sure you want to proceed? (yes/no): " -r
    if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
        echo "Cleanup cancelled."
        exit 0
    fi
}

# Cleanup Kubernetes resources
cleanup_k8s_resources() {
    log "Cleaning up Kubernetes resources..."
    
    # Update kubeconfig if cluster exists
    if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION &>/dev/null; then
        aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
        
        # Delete applications first
        log "Deleting ArgoCD applications..."
        kubectl delete applications --all -n argocd --ignore-not-found=true --timeout=60s
        
        # Delete namespaces (this will delete all resources in them)
        log "Deleting application namespaces..."
        kubectl delete namespace k8s-hub --ignore-not-found=true --timeout=300s
        kubectl delete namespace monitoring --ignore-not-found=true --timeout=300s
        kubectl delete namespace argocd --ignore-not-found=true --timeout=300s
        kubectl delete namespace jaeger-system --ignore-not-found=true --timeout=300s
        
        # Delete any remaining LoadBalancer services
        log "Cleaning up LoadBalancer services..."
        kubectl get svc --all-namespaces -o json | jq -r '.items[] | select(.spec.type=="LoadBalancer") | "\(.metadata.namespace) \(.metadata.name)"' | while read namespace name; do
            if [ ! -z "$namespace" ] && [ ! -z "$name" ]; then
                kubectl delete svc $name -n $namespace --ignore-not-found=true
            fi
        done
        
        # Wait for LoadBalancers to be deleted
        log "Waiting for LoadBalancers to be cleaned up..."
        sleep 60
        
    else
        warn "Cluster $CLUSTER_NAME not found or not accessible"
    fi
}

# Delete EKS cluster
delete_eks_cluster() {
    log "Deleting EKS cluster..."
    
    if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION &>/dev/null; then
        log "Deleting EKS cluster: $CLUSTER_NAME (this may take 10-15 minutes)"
        eksctl delete cluster --name $CLUSTER_NAME --region $REGION --wait
        log "EKS cluster deleted successfully"
    else
        warn "EKS cluster $CLUSTER_NAME not found"
    fi
}

# Delete CloudFormation stack
delete_cloudformation_stack() {
    log "Deleting CloudFormation stack..."
    
    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &>/dev/null; then
        log "Deleting CloudFormation stack: $STACK_NAME"
        aws cloudformation delete-stack --stack-name $STACK_NAME --region $REGION
        
        log "Waiting for stack deletion to complete..."
        aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME --region $REGION
        log "CloudFormation stack deleted successfully"
    else
        warn "CloudFormation stack $STACK_NAME not found"
    fi
}

# Cleanup ECR repositories
cleanup_ecr_repositories() {
    log "Cleaning up ECR repositories..."
    
    # List and delete ECR repositories
    ECR_REPOS=$(aws ecr describe-repositories --region $REGION --query 'repositories[?contains(repositoryName, `k8s-hub`)].repositoryName' --output text 2>/dev/null || true)
    
    if [ ! -z "$ECR_REPOS" ]; then
        for repo in $ECR_REPOS; do
            log "Deleting ECR repository: $repo"
            aws ecr delete-repository --repository-name $repo --region $REGION --force --ignore-not-found 2>/dev/null || true
        done
    else
        warn "No ECR repositories found with 'k8s-hub' in the name"
    fi
}

# Cleanup local Docker images
cleanup_local_docker() {
    log "Cleaning up local Docker images..."
    
    if command -v docker &> /dev/null; then
        # Remove k8s-hub related images
        docker images | grep k8s-hub | awk '{print $3}' | xargs -r docker rmi -f 2>/dev/null || true
        
        # Remove dangling images
        docker image prune -f 2>/dev/null || true
        
        log "Local Docker images cleaned up"
    else
        warn "Docker not found, skipping local image cleanup"
    fi
}

# Cleanup AWS resources
cleanup_aws_resources() {
    log "Cleaning up additional AWS resources..."
    
    # Delete any remaining ELBs
    log "Checking for remaining Load Balancers..."
    aws elbv2 describe-load-balancers --region $REGION --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-hub`)].LoadBalancerArn' --output text 2>/dev/null | while read lb_arn; do
        if [ ! -z "$lb_arn" ]; then
            log "Deleting Load Balancer: $lb_arn"
            aws elbv2 delete-load-balancer --load-balancer-arn $lb_arn --region $REGION 2>/dev/null || true
        fi
    done
    
    # Delete any remaining security groups (with retry)
    log "Cleaning up security groups..."
    for i in {1..3}; do
        aws ec2 describe-security-groups --region $REGION --filters "Name=group-name,Values=*k8s-hub*" --query 'SecurityGroups[].GroupId' --output text 2>/dev/null | while read sg_id; do
            if [ ! -z "$sg_id" ] && [ "$sg_id" != "None" ]; then
                log "Attempting to delete security group: $sg_id (attempt $i)"
                aws ec2 delete-security-group --group-id $sg_id --region $REGION 2>/dev/null || true
            fi
        done
        sleep 30
    done
}

# Cleanup local files
cleanup_local_files() {
    log "Cleaning up local temporary files..."
    
    # Remove temporary files
    rm -f argocd-password.txt
    rm -f ExternalIP.txt
    rm -f trivy-report.html
    rm -f prometheus-values.yaml
    rm -f k8s-hub-servicemonitor.yaml
    rm -f alerting-rules.yaml
    rm -f jaeger-instance.yaml
    rm -f k8s-hub-application.yaml
    rm -f k8s-hub-project.yaml
    rm -f argocd-servicemonitor.yaml
    rm -f argocd-rbac.yaml
    
    # Remove kubeconfig context
    kubectl config delete-context arn:aws:eks:$REGION:$(aws sts get-caller-identity --query Account --output text):cluster/$CLUSTER_NAME 2>/dev/null || true
    
    log "Local files cleaned up"
}

# Stop local services
stop_local_services() {
    log "Stopping local services..."
    
    # Stop Jenkins
    if systemctl is-active --quiet jenkins 2>/dev/null; then
        sudo systemctl stop jenkins
        log "Jenkins stopped"
    fi
    
    # Stop SonarQube
    if systemctl is-active --quiet sonarqube 2>/dev/null; then
        sudo systemctl stop sonarqube
        log "SonarQube stopped"
    fi
    
    # Stop Docker containers
    if command -v docker &> /dev/null; then
        docker stop $(docker ps -q) 2>/dev/null || true
        docker container prune -f 2>/dev/null || true
        log "Docker containers stopped and cleaned"
    fi
}

# Verify cleanup
verify_cleanup() {
    log "Verifying cleanup..."
    
    # Check if cluster still exists
    if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION &>/dev/null; then
        error "EKS cluster still exists!"
        return 1
    fi
    
    # Check if stack still exists
    if aws cloudformation describe-stacks --stack-name $STACK_NAME --region $REGION &>/dev/null; then
        error "CloudFormation stack still exists!"
        return 1
    fi
    
    log "✅ Cleanup verification completed successfully"
}

# Display cleanup summary
display_summary() {
    echo ""
    log "🎉 Cleanup completed successfully!"
    echo ""
    echo "📋 Cleanup Summary:"
    echo "  ✅ Kubernetes resources deleted"
    echo "  ✅ EKS cluster deleted"
    echo "  ✅ CloudFormation stack deleted"
    echo "  ✅ ECR repositories cleaned"
    echo "  ✅ Local Docker images cleaned"
    echo "  ✅ AWS resources cleaned"
    echo "  ✅ Local files cleaned"
    echo "  ✅ Local services stopped"
    echo ""
    echo "💡 Note: Some AWS resources may take additional time to be fully deleted."
    echo "💡 Check AWS Console to verify all resources are removed."
    echo ""
    echo "🔧 To restart the project:"
    echo "  1. Run: ./install-tools.sh"
    echo "  2. Run: ./eks-setup.sh"
    echo "  3. Run: ./deploy.sh"
}

# Main cleanup function
main() {
    log "Starting comprehensive cleanup process..."
    
    confirm_cleanup
    cleanup_k8s_resources
    delete_eks_cluster
    delete_cloudformation_stack
    cleanup_ecr_repositories
    cleanup_local_docker
    cleanup_aws_resources
    cleanup_local_files
    stop_local_services
    verify_cleanup
    display_summary
    
    log "All cleanup operations completed!"
}

# Handle script interruption
trap 'error "Cleanup interrupted! Some resources may still exist."; exit 1' INT TERM

# Run main function
main "$@"
