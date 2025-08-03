#!/bin/bash
# Amazon EKS cluster setup

set -e

read -p "Enter your cluster name: " CLUSTER_NAME
read -p "Enter your region: " REGION
read -p "Enter node-group name: " NODE_GROUP_NAME

echo "Setting up EKS cluster: $CLUSTER_NAME in $REGION"

echo "setting aws-cli"
  if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Installing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      # Installing AWS CLI
      #!/bin/bash
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      sudo apt install unzip -y
      unzip awscliv2.zip
      sudo ./aws/install
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      brew install awscli
    else
      echo "Unsupported OS. Please install AWS CLI manually."
      exit 1
    fi
  else
    echo "✅ AWS CLI is already installed."
  fi

  echo "Checking AWS CLI configuration..."
  if ! aws sts get-caller-identity &>/dev/null; then
    echo "🔧 AWS CLI is not configured. Launching interactive setup..."
    aws configure
  else
    echo "✅ AWS CLI is already configured."
  fi

# Check if kubectl is installed
if ! command -v eksctl &> /dev/null; then
    echo "Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
fi

# Check if eksctl is installed
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    #!/bin/bash
sudo apt update
sudo apt install curl -y
sudo curl -LO "https://dl.k8s.io/release/v1.28.4/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
fi

# Create EKS cluster
echo "Creating EKS cluster (wait for 15-20 minutes)..."
eksctl create cluster \
    --name $CLUSTER_NAME \
    --region $REGION \
    --node-type t3.medium \
    --nodes 2 \
    --nodes-min 1 \
    --nodes-max 4 \
    --managed

echo "EKS cluster created successfully!"
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "Testing cluster connection..."
kubectl get nodes

echo ""
echo "🎉 EKS cluster is ready!"
echo ""
echo "To delete the cluster later:"
echo "eksctl delete cluster --name $CLUSTER_NAME --region $REGION"
