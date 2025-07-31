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


## This project is deploy with Devops best practices 

1. ec2 --> jenkins --> sonar --> trity --> eks cluster --> argocd --> minitoring tools
   here is Open [DevOps.md](https://github.com/GhanshyamRamole/k8s-Hub-app/blob/main/DevOps.md) file for implementation 

3. Fully Automated with Infrastructure Provisioning with CloudFormation and scripts 
    here is Open [https://github.com/GhanshyamRamole/k8s-Hub-app/blob/main/DevOps.md](comming soon) for implementation  
