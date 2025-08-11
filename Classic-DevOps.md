
# Kubernetes-Hub Deployment Project

![Overview](./src/Overview.png)

## 📘 Project Overview

This project demonstrates deploying a **Kubernetes Hub (k8s-hub)** using a DevOps toolchain and best practices.

## 🔧 Tools Used:

- **GitHub** – Source code management
- **Shell Scripts** – Automate AWS CLI, EKSCTL, kubectl installation, and EKS cluster setup
- **Jenkins** – CI/CD orchestration
- **SonarQube** – Static code analysis and quality gates
- **Trivy** – Container security scanning
- **Docker** – Containerization platform
- **AWS ECR** – Private Docker registry
- **AWS EKS** – Managed Kubernetes service
- **ArgoCD** – GitOps continuous deployment
- **Prometheus & Grafana** – Monitoring and alerting tools

---

## ✅ Pre-requisites

1. **AWS Account**
2. **IAM User** with programmatic access (Access Key + Secret Key)
3. **Key Pair** named `key` for EC2 instance SSH access

---

## ☁️ AWS Configuration

### 1. IAM Setup
- Create an IAM user with admin privileges
- Generate Access Key & Secret Key
- Configure your machine:

  ```bash
  aws configure
  ```
---

##🏗️ Infrastructure Provisioning with CloudFormation
   - Step 1: Create Stack
   - Go to AWS Console → CloudFormation → Create Stack

      Choose “With new resources (standard)”
        Template Options:
        Upload: infrastructure-template.yml
        Or provide an Amazon S3 URL

##🔧 EKS and Tool Setup via Shell Scripts**:
   **step 1:** Run EKS Setup Script
      - Run the below commands execute eks-setup.sh This will create eks and its prerequisites 
     
    ```bash
     chmod +x eks-setup.sh
     ./eks-setup.sh
   
This will Installs AWS CLI, EKSCTL, kubectl, and provisions the EKS cluster.

   **Step 2:** Install Required Tools
     
     ```bash
     chmod +x install.sh
     ./install.sh
     
This will install necessary tools like Docker, Jenkins, SonarQube, Trivy.

---

## 🔍 SonarQube Configuration
1. **Login Credentials**: Use `admin` for both username and password.
2. **Generate SonarQube Token**:
   - Create a token under `Administration → Security → Users → Tokens`.
   - Save the token for integration with Jenkins.
   - Create webhook for integration with jenkins for continuous integration of project code analysis 
   - get project keyfor conde analysis

---
     
## 🔧 Jenkins Configuration
1. **Add Jenkins Credentials**:
   - Add the SonarQube token, AWS access key, and secret key in `Manage Jenkins → Credentials → System → Global credentials`.
2. **Install Required Plugins**:
   - Install plugins such as pipeline stage view, SonarQube Scanner, NodeJS, Docker, and Prometheus metrics under `Manage Jenkins → Plugins`.
3. **Global Tool Configuration**:
   - Set up tools like JDK 17, SonarQube Scanner, NodeJS, and Docker under `Manage Jenkins → Global Tool Configuration`.

---

##  🚀 Jenkins Pipeline Overview
### Pipeline Stages
1. **Git Checkout**: Clones the source code from GitHub.
2. **SonarQube Analysis**: Performs static code analysis.
3. **Quality Gate**: Ensures code quality standards.
4. **Trivy Security Scan**: Scans the project for vulnerabilities.
5. **Docker Build**: Builds a Docker image for the project.
6. **Push to AWS ECR**: Tags and pushes the Docker image to ECR.
7. **Image Cleanup**: Deletes images from the Jenkins server to save space.

### Create Pipeline
Create and run the build pipeline in Jenkins. The pipeline will build, analyze, and push the project Docker image to ECR.
Create a Jenkins pipeline by adding the following script:

### Build Pipeline

## Continuous Deployment with ArgoCD
1. **Create EKS Cluster**: Use Terraform to create an EKS cluster and related resources.
2. **Deploy Amazon Prime Clone**: Use ArgoCD to deploy the application using Kubernetes YAML files.
3. **Monitoring Setup**: Install Prometheus and Grafana using Helm charts for monitoring the Kubernetes cluster.

### Deployment Pipeline

## Cleanup
- Run cleanup pipelines to delete the resources such as load balancers, services, and deployment files.


