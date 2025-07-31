# Kubernetes-Hub Deployment Project
![image](./src/Overview.png)

## Project Overview
This project demonstrates deploying an k8s-hub using a set of DevOps tools and best practices. The primary tools include:

- **Cloudformation**: Infrastructure as Code (IaC) tool for ec2, vpc, subnet .
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


## Configuration
### AWS Setup
1. **IAM User**: Create an IAM user and generate the access and secret keys to configure your machine with AWS.
2. **Key Pair**: Create a key pair named `key` for accessing your EC2 instances.

## Infrastructure Setup Using Cloudformation
1. **Create Stack**:
   Click “Create stack” > “With new resources (standard)”.
   Step : Choose a Template
           you have two options:
            - Upload a template file (YAML or JSON format)
            - Specify an Amazon S3 URL
   - infrastructure-template.yml
     
2. **Shell Script**:
   - Run the below commands execute eks-setup.sh This will create eks and its prerequisites 
     ```bash
     chmod +x eks-setup.sh
     ./eks-setup.sh
     ```
This will install aws-cli, configure aws, eksclt, kubectl and create cluster.
    
     ```bash
     chmod +x install.sh
     ./install.sh
     ```
This will install necessary tools like Docker, Jenkins, SonarQube, Trivy.

## SonarQube Configuration
1. **Login Credentials**: Use `admin` for both username and password.
2. **Generate SonarQube Token**:
   - Create a token under `Administration → Security → Users → Tokens`.
   - Save the token for integration with Jenkins.
   - Create webhook for integration with jenkins for continuous integration of project code analysis 
   - get project keyfor conde analysis
     
## Jenkins Configuration
1. **Add Jenkins Credentials**:
   - Add the SonarQube token, AWS access key, and secret key in `Manage Jenkins → Credentials → System → Global credentials`.
2. **Install Required Plugins**:
   - Install plugins such as pipeline stage view, SonarQube Scanner, NodeJS, Docker, and Prometheus metrics under `Manage Jenkins → Plugins`.

3. **Global Tool Configuration**:
   - Set up tools like JDK 17, SonarQube Scanner, NodeJS, and Docker under `Manage Jenkins → Global Tool Configuration`.

## Pipeline Overview
### Pipeline Stages
1. **Git Checkout**: Clones the source code from GitHub.
2. **SonarQube Analysis**: Performs static code analysis.
3. **Quality Gate**: Ensures code quality standards.
4. **Trivy Security Scan**: Scans the project for vulnerabilities.
5. **Docker Build**: Builds a Docker image for the project.
6. **Push to AWS ECR**: Tags and pushes the Docker image to ECR.
7. **Image Cleanup**: Deletes images from the Jenkins server to save space.

### Running Jenkins Pipeline
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

### Cleanup Pipeline
