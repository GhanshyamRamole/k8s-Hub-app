# Kubernetes Hub

![Kubernetes Hub](./public/cover.png)

A comprehensive web platform for Kubernetes learners and professionals to explore all types of Kubernetes installation methods. 

This project is built using [Next.js](https://nextjs.org), bootstrapped with [`create-next-app`](https://nextjs.org/docs/app/api-reference/cli/create-next-app).

---

## 🌐 Project Overview

Kubernetes Hub is a one-stop destination offering guides, scripts, and resources for installing Kubernetes using various methods such as:

- **Minikube**
- **Kubeadm**
-  **AWS EKS**
- **Kind (Kubernetes in Docker)**
- **MicroK8s**
- **K3s**

Whether you're experimenting locally or deploying in production, Kubernetes Hub provides everything you need in one UI-friendly platform.

---

## 🚀 Getting Started

### Prerequisites

- Node.js `>=16.x`
- npm or yarn
- Git

### Clone the Repository

```bash
git clone https://github.com/yourusername/kubernetes-hub.git
cd kubernetes-hub
```

## Getting Started

First, run the development server:

```bash
npm run dev
# or
yarn dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser to see the result.

---

# 🚀 Kubernetes Hub - DevOps Implementation Guide 

![DevOps Pipeline](./public/devops-overview.png)

> Complete guide for deploying Kubernetes Hub using two comprehensive DevOps approaches:
1. Classic CI/CD Pipeline and
2. Infrastructure as Code (IaC).

---

## 📋 Table of Contents

1. [Classic CI/CD Pipeline](https://github.com/GhanshyamRamole/k8s-Hub-app/blob/main/DevOps.md)
2. [Infrastructure as Code (IaC)](https://github.com/GhanshyamRamole/k8s-Hub-app/blob/main/IaC-deployment.md)


---

## 🌐 Project Overview

This project demonstrates deploying **Kubernetes Hub** using enterprise-grade DevOps practices with two distinct approaches:

### 🔄 Classic DevOps Pipeline
```
GitHub → Jenkins → SonarQube → Trivy → Docker → ECR → EKS → ArgoCD → Monitoring
```

### 🏗️ Infrastructure as Code (IaC)
```
CloudFormation → VPC/Subnets/EC2 → Shell Scripts → AWS CLI/eksctl/kubectl → EKS → K8s Deployment
```

---
