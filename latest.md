# 🚀 Kubernetes Hub - DevOps Implementation Guide

![DevOps Pipeline](./public/devops-overview.png)

> Complete guide for deploying Kubernetes Hub using two comprehensive DevOps approaches: Classic CI/CD Pipeline and Infrastructure as Code (IaC).

---

## 📋 Table of Contents

1. [Project Overview](#-project-overview)
2. [Prerequisites](#-prerequisites)
3. [Classic DevOps Implementation](#-classic-devops-implementation)
4. [Infrastructure as Code Implementation](#-infrastructure-as-code-implementation)
5. [Monitoring & Observability](#-monitoring--observability)
6. [Cleanup & Maintenance](#-cleanup--maintenance)

---

## 🌐 Project Overview

This project demonstrates deploying **Kubernetes Hub** using enterprise-grade DevOps practices with two distinct approaches:

### 🔄 Classic DevOps Pipeline
```
GitHub → Jenkins → SonarQube → Trivy → Docker → ECR → EKS → ArgoCD → Monitoring
```

---

## 📊 Monitoring & Observability

### Setup Prometheus & Grafana
```bash
#!/bin/bash
# setup-monitoring.sh

# Add Helm repositories
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install Prometheus
helm install prometheus prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --create-namespace \
    --set grafana.adminPassword=admin123

# Get Grafana URL
kubectl get svc -n monitoring prometheus-grafana
```

---

## 🧹 Cleanup & Maintenance

### Cleanup Script
```bash
#!/bin/bash
# cleanup.sh

CLUSTER_NAME="k8s-hub-cluster"
REGION="us-east-1"

echo "🧹 Starting cleanup process..."

# Delete Kubernetes resources
kubectl delete namespace k8s-hub --ignore-not-found=true
kubectl delete namespace monitoring --ignore-not-found=true

# Delete EKS cluster
eksctl delete cluster --name $CLUSTER_NAME --region $REGION

# Delete CloudFormation stack
aws cloudformation delete-stack --stack-name k8s-hub-infrastructure

echo "✅ Cleanup completed!"
```

---

## 🎯 Best Practices & Tips

### Security Best Practices
- Use IAM roles instead of access keys where possible
- Enable VPC Flow Logs for network monitoring
- Implement Pod Security Standards
- Use AWS Secrets Manager for sensitive data
- Enable audit logging for EKS

### Cost Optimization
- Use Spot instances for non-production workloads
- Implement Horizontal Pod Autoscaler (HPA)
- Use Cluster Autoscaler for node scaling
- Monitor resource usage with AWS Cost Explorer

### Troubleshooting
```bash
# Common debugging commands
kubectl get events --sort-by=.metadata.creationTimestamp
kubectl describe pod <pod-name>
kubectl logs -f <pod-name>
aws eks describe-cluster --name <cluster-name>
```

---

## 📞 Support & Resources

- **AWS EKS Documentation**: https://docs.aws.amazon.com/eks/
- **Kubernetes Documentation**: https://kubernetes.io/docs/
- **Jenkins Documentation**: https://www.jenkins.io/doc/
- **ArgoCD Documentation**: https://argo-cd.readthedocs.io/

---

<div align="center">
  <strong>🚀 Happy DevOps Journey! 🎉</strong>
</div>
