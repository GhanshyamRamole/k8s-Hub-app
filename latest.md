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

### 🏗️ Infrastructure as Code (IaC)
```
CloudFormation → VPC/Subnets/EC2 → Shell Scripts → AWS CLI/eksctl/kubectl → EKS → K8s Deployment
```

---

## ✅ Prerequisites

### 🔧 Required Tools & Accounts
- **AWS Account** with administrative access
- **GitHub Account** for source code management
- **Domain** (optional) for custom DNS
- **Local Machine** with internet connectivity

### 🔑 AWS Setup
1. **IAM User Creation**
   ```bash
   # Create IAM user with programmatic access
   aws iam create-user --user-name k8s-hub-devops
   aws iam attach-user-policy --user-name k8s-hub-devops --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
   aws iam create-access-key --user-name k8s-hub-devops
   ```

2. **Key Pair Setup**
   ```bash
   # Create EC2 key pair
   aws ec2 create-key-pair --key-name k8s-hub-key --query 'KeyMaterial' --output text > k8s-hub-key.pem
   chmod 400 k8s-hub-key.pem
   ```

3. **Configure AWS CLI**
   ```bash
   aws configure
   # Enter your Access Key ID, Secret Access Key, Region (us-east-1), and output format (json)
   ```

---

## 🔄 Classic DevOps Implementation

### Phase 1: Infrastructure Setup

#### 1.1 Launch EC2 Instance
```bash
# Launch Ubuntu EC2 instance
aws ec2 run-instances \
    --image-id ami-0c02fb55956c7d316 \
    --count 1 \
    --instance-type t3.large \
    --key-name k8s-hub-key \
    --security-group-ids sg-xxxxxxxxx \
    --subnet-id subnet-xxxxxxxxx \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s-hub-devops}]'
```

#### 1.2 Install Required Tools
```bash
#!/bin/bash
# install-tools.sh

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Jenkins
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install SonarQube
docker run -d --name sonarqube -p 9000:9000 sonarqube:latest

# Install Trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy -y

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
```

### Phase 2: EKS Cluster Setup

#### 2.1 Create EKS Cluster
```bash
#!/bin/bash
# eks-cluster-setup.sh

CLUSTER_NAME="k8s-hub-cluster"
REGION="us-east-1"

# Create EKS cluster
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --node-type t3.medium \
    --nodes 3 \
    --nodes-min 2 \
    --nodes-max 5 \
    --managed \
    --with-oidc \
    --ssh-access \
    --ssh-public-key k8s-hub-key

# Update kubeconfig
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Verify cluster
kubectl get nodes
```

### Phase 3: CI/CD Pipeline Configuration

#### 3.1 Jenkins Setup
```bash
# Access Jenkins
echo "Jenkins initial password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Install required plugins via Jenkins UI:
# - Pipeline Stage View
# - SonarQube Scanner
# - NodeJS
# - Docker Pipeline
# - AWS Steps
# - Kubernetes
# - ArgoCD
```

#### 3.2 SonarQube Configuration
```bash
# Access SonarQube at http://your-ip:9000
# Default credentials: admin/admin

# Create project and generate token
# Configure webhook: http://jenkins-ip:8080/sonarqube-webhook/
```

#### 3.3 Jenkins Pipeline Script
```groovy
pipeline {
    agent any
    
    tools {
        nodejs 'NodeJS-18'
    }
    
    environment {
        AWS_REGION = 'us-east-1'
        ECR_REPOSITORY = 'k8s-hub'
        EKS_CLUSTER = 'k8s-hub-cluster'
        SONAR_PROJECT_KEY = 'k8s-hub'
    }
    
    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/GhanshyamRamole/k8s-Hub-app.git'
            }
        }
        
        stage('Install Dependencies') {
            steps {
                dir('Application') {
                    sh 'npm install'
                }
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh '''
                        sonar-scanner \
                        -Dsonar.projectKey=$SONAR_PROJECT_KEY \
                        -Dsonar.sources=./Application \
                        -Dsonar.host.url=http://localhost:9000
                    '''
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 1, unit: 'HOURS') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
        
        stage('Trivy Security Scan') {
            steps {
                sh 'trivy fs --format table -o trivy-report.html .'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: '.',
                    reportFiles: 'trivy-report.html',
                    reportName: 'Trivy Security Report'
                ])
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    def image = docker.build("${ECR_REPOSITORY}:${BUILD_NUMBER}")
                }
            }
        }
        
        stage('Push to ECR') {
            steps {
                script {
                    sh '''
                        aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                        docker tag $ECR_REPOSITORY:$BUILD_NUMBER $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$BUILD_NUMBER
                        docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$BUILD_NUMBER
                    '''
                }
            }
        }
        
        stage('Update Kubernetes Manifests') {
            steps {
                script {
                    sh '''
                        sed -i "s|image: .*|image: $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPOSITORY:$BUILD_NUMBER|g" K8s-files/deployment.yml
                        git add K8s-files/deployment.yml
                        git commit -m "Update image tag to $BUILD_NUMBER"
                        git push origin main
                    '''
                }
            }
        }
        
        stage('Deploy to EKS') {
            steps {
                script {
                    sh '''
                        aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER
                        kubectl apply -f K8s-files/
                        kubectl rollout status deployment/k8s-hub-deployment
                    '''
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed!'
        }
    }
}
```

### Phase 4: ArgoCD GitOps Setup

#### 4.1 Install ArgoCD
```bash
# Create ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose ArgoCD server
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

# Get initial password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

#### 4.2 Configure ArgoCD Application
```yaml
# argocd-application.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: k8s-hub
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/GhanshyamRamole/k8s-Hub-app.git
    targetRevision: main
    path: K8s-files
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

---

## 🏗️ Infrastructure as Code Implementation

### Phase 1: CloudFormation Infrastructure

#### 1.1 Deploy Infrastructure Stack
```bash
# Deploy CloudFormation template
aws cloudformation create-stack \
    --stack-name k8s-hub-infrastructure \
    --template-body file://cloudformation-IAC/infrastructure-template.yml \
    --parameters ParameterKey=KeyName,ParameterValue=k8s-hub-key \
    --capabilities CAPABILITY_IAM

# Wait for stack completion
aws cloudformation wait stack-create-complete --stack-name k8s-hub-infrastructure
```

#### 1.2 Enhanced Infrastructure Template
```yaml
# cloudformation-IAC/infrastructure-template.yml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'Complete infrastructure for Kubernetes Hub'

Parameters:
  KeyName:
    Type: AWS::EC2::KeyPair::KeyName
    Description: EC2 Key Pair for SSH access

Resources:
  # VPC Configuration
  VPC:
    Type: AWS::EC2::VPC
    Properties:
      CidrBlock: 10.0.0.0/16
      EnableDnsHostnames: true
      EnableDnsSupport: true
      Tags:
        - Key: Name
          Value: k8s-hub-vpc

  # Internet Gateway
  InternetGateway:
    Type: AWS::EC2::InternetGateway
    Properties:
      Tags:
        - Key: Name
          Value: k8s-hub-igw

  AttachGateway:
    Type: AWS::EC2::VPCGatewayAttachment
    Properties:
      VpcId: !Ref VPC
      InternetGatewayId: !Ref InternetGateway

  # Public Subnets
  PublicSubnet1:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.1.0/24
      AvailabilityZone: !Select [0, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: k8s-hub-public-subnet-1

  PublicSubnet2:
    Type: AWS::EC2::Subnet
    Properties:
      VpcId: !Ref VPC
      CidrBlock: 10.0.2.0/24
      AvailabilityZone: !Select [1, !GetAZs '']
      MapPublicIpOnLaunch: true
      Tags:
        - Key: Name
          Value: k8s-hub-public-subnet-2

  # Route Table
  PublicRouteTable:
    Type: AWS::EC2::RouteTable
    Properties:
      VpcId: !Ref VPC
      Tags:
        - Key: Name
          Value: k8s-hub-public-rt

  PublicRoute:
    Type: AWS::EC2::Route
    DependsOn: AttachGateway
    Properties:
      RouteTableId: !Ref PublicRouteTable
      DestinationCidrBlock: 0.0.0.0/0
      GatewayId: !Ref InternetGateway

  # Security Group
  SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for K8s Hub
      VpcId: !Ref VPC
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 22
          ToPort: 22
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 8080
          ToPort: 8080
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 9000
          ToPort: 9000
          CidrIp: 0.0.0.0/0

  # EC2 Instance
  EC2Instance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0c02fb55956c7d316
      InstanceType: t3.large
      KeyName: !Ref KeyName
      SecurityGroupIds:
        - !Ref SecurityGroup
      SubnetId: !Ref PublicSubnet1
      UserData:
        Fn::Base64: !Sub |
          #!/bin/bash
          apt-get update
          apt-get install -y git curl wget
      Tags:
        - Key: Name
          Value: k8s-hub-instance

Outputs:
  VPCId:
    Description: VPC ID
    Value: !Ref VPC
    Export:
      Name: !Sub "${AWS::StackName}-VPC-ID"
  
  InstanceId:
    Description: EC2 Instance ID
    Value: !Ref EC2Instance
    Export:
      Name: !Sub "${AWS::StackName}-Instance-ID"
```

### Phase 2: Automated Deployment Scripts

#### 2.1 Enhanced EKS Setup Script
```bash
#!/bin/bash
# enhanced-eks-setup.sh

set -e

# Configuration
CLUSTER_NAME="k8s-hub-cluster"
REGION="us-east-1"
NODE_GROUP_NAME="k8s-hub-nodes"

echo "🚀 Starting EKS cluster setup..."

# Install AWS CLI
install_aws_cli() {
    if ! command -v aws &> /dev/null; then
        echo "📦 Installing AWS CLI..."
        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
        sudo apt install unzip -y
        unzip awscliv2.zip
        sudo ./aws/install
        rm -rf aws awscliv2.zip
    else
        echo "✅ AWS CLI already installed"
    fi
}

# Install eksctl
install_eksctl() {
    if ! command -v eksctl &> /dev/null; then
        echo "📦 Installing eksctl..."
        curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
        sudo mv /tmp/eksctl /usr/local/bin
    else
        echo "✅ eksctl already installed"
    fi
}

# Install kubectl
install_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        echo "📦 Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl"
        sudo chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    else
        echo "✅ kubectl already installed"
    fi
}

# Configure AWS credentials
configure_aws() {
    echo "🔧 Configuring AWS credentials..."
    if ! aws sts get-caller-identity &>/dev/null; then
        echo "Please configure AWS CLI:"
        aws configure
    else
        echo "✅ AWS CLI already configured"
    fi
}

# Create EKS cluster
create_eks_cluster() {
    echo "🏗️ Creating EKS cluster (this may take 15-20 minutes)..."
    
    # Check if cluster already exists
    if aws eks describe-cluster --name $CLUSTER_NAME --region $REGION &>/dev/null; then
        echo "✅ Cluster $CLUSTER_NAME already exists"
    else
        eksctl create cluster \
            --name $CLUSTER_NAME \
            --region $REGION \
            --node-type t3.medium \
            --nodes 3 \
            --nodes-min 2 \
            --nodes-max 5 \
            --managed \
            --with-oidc \
            --ssh-access \
            --ssh-public-key k8s-hub-key \
            --tags Environment=dev,Project=k8s-hub
    fi
    
    # Update kubeconfig
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    
    # Verify cluster
    echo "🔍 Verifying cluster..."
    kubectl get nodes
    kubectl get pods --all-namespaces
}

# Install additional tools
install_additional_tools() {
    echo "📦 Installing additional tools..."
    
    # Install Helm
    if ! command -v helm &> /dev/null; then
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    # Install ArgoCD CLI
    if ! command -v argocd &> /dev/null; then
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
    fi
}

# Main execution
main() {
    install_aws_cli
    install_eksctl
    install_kubectl
    configure_aws
    create_eks_cluster
    install_additional_tools
    
    echo ""
    echo "🎉 EKS cluster setup completed successfully!"
    echo ""
    echo "Cluster Information:"
    echo "  Name: $CLUSTER_NAME"
    echo "  Region: $REGION"
    echo "  Nodes: $(kubectl get nodes --no-headers | wc -l)"
    echo ""
    echo "Next steps:"
    echo "  1. Deploy your application: ./deploy.sh"
    echo "  2. Setup monitoring: ./setup-monitoring.sh"
    echo "  3. Configure ArgoCD: ./setup-argocd.sh"
    echo ""
    echo "To delete the cluster later:"
    echo "  eksctl delete cluster --name $CLUSTER_NAME --region $REGION"
}

main "$@"
```

#### 2.2 Enhanced Deployment Script
```bash
#!/bin/bash
# enhanced-deploy.sh

set -e

CLUSTER_NAME="k8s-hub-cluster"
REGION="us-east-1"
NAMESPACE="k8s-hub"

echo "🚀 Starting application deployment..."

# Verify cluster connection
verify_cluster() {
    echo "🔍 Verifying cluster connection..."
    if ! kubectl cluster-info &>/dev/null; then
        echo "❌ Cannot connect to cluster. Updating kubeconfig..."
        aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    fi
    echo "✅ Connected to cluster: $(kubectl config current-context)"
}

# Create namespace
create_namespace() {
    echo "📦 Creating namespace..."
    kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
}

# Deploy application
deploy_application() {
    echo "🚀 Deploying Kubernetes Hub application..."
    
    # Apply Kubernetes manifests
    kubectl apply -f K8s-files/ -n $NAMESPACE
    
    # Wait for deployment to be ready
    echo "⏳ Waiting for deployment to be ready..."
    kubectl rollout status deployment/k8s-hub-deployment -n $NAMESPACE --timeout=300s
    
    # Get service information
    echo "📋 Service Information:"
    kubectl get svc -n $NAMESPACE
    
    # Get external IP
    echo "🌐 Getting external access information..."
    EXTERNAL_IP=$(kubectl get svc k8s-hub-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    
    if [ -n "$EXTERNAL_IP" ]; then
        echo "✅ Application deployed successfully!"
        echo "🌐 Access your application at: http://$EXTERNAL_IP:3000"
    else
        echo "⏳ LoadBalancer is still provisioning. Check again in a few minutes:"
        echo "kubectl get svc -n $NAMESPACE"
    fi
}

# Setup ingress (optional)
setup_ingress() {
    echo "🔧 Setting up ingress controller..."
    
    # Install AWS Load Balancer Controller
    helm repo add eks https://aws.github.io/eks-charts
    helm repo update
    
    helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
        -n kube-system \
        --set clusterName=$CLUSTER_NAME \
        --set serviceAccount.create=false \
        --set serviceAccount.name=aws-load-balancer-controller
}

# Main execution
main() {
    verify_cluster
    create_namespace
    deploy_application
    
    echo ""
    echo "🎉 Deployment completed successfully!"
    echo ""
    echo "Useful commands:"
    echo "  kubectl get pods -n $NAMESPACE"
    echo "  kubectl get svc -n $NAMESPACE"
    echo "  kubectl logs -f deployment/k8s-hub-deployment -n $NAMESPACE"
    echo "  kubectl describe svc k8s-hub-service -n $NAMESPACE"
}

main "$@"
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
