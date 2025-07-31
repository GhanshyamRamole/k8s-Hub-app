# Kubernetes-Hub Deployment Project
![image](./src/Overview.png)

## Project Overview
This project demonstrates deploying an k8s-hub using a set of DevOps tools and best practices. The primary tools include:

- **Cloudformation**: Infrastructure as Code (IaC) tool to create AWS infrastructure.
- **Shell Scripting**: for automating and install aws-cli, eksclt, kubectl, eks creation.
- **GitHub**: Source code management.
- **Jenkins**: CI/CD automation tool.
- **SonarQube**: Code quality analysis and quality gate too
- **Trivy**: Security vulnerability scanner.
- **Docker**: Containerization tool to create images.
- **AWS ECR**: Repository to store Docker images.
- **AWS EKS**: Container management platform.
- **ArgoCD**: Continuous deployment tool.
- **Prometheus & Grafana**: Monitoring and alerting tools.

## Pre-requisites
1. **AWS Account**: Ensure you have an AWS account. 

## Configuration
### AWS Setup
1. **IAM User**: Create an IAM user and generate the access and secret keys to configure your machine with AWS.
2. **Key Pair**: Create a key pair named `key` for accessing your EC2 instances.

