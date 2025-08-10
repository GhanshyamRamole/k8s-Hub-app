#!/bin/bash 

echo "Cloning git repo ..."
  git clone https://github.com/GhanshyamRamole/k8s-Hub-app.git

#!/bin/bash
# Amazon EKS cluster setup

set -e

CLUSTER_NAME="dev"
REGION="us-east-1"
NODE_GROUP_NAME="dev-node"

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

AWS_ACCESS_KEY_ID="your-access-key-id"
AWS_SECRET_ACCESS_KEY="your-secret-access-key"
AWS_REGION="us-east-1"  
AWS_OUTPUT_FORMAT="json"

  echo "Checking AWS CLI configuration..."
  if ! aws sts get-caller-identity &>/dev/null; then
    echo "🔧 AWS CLI is not configured. Launching interactive setup..."
    aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID
    aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY
    aws configure set region $AWS_REGION
    aws configure set output $AWS_OUTPUT_FORMAT
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

# Wait for EKS control plane
echo "Waiting for EKS cluster to become ACTIVE..."
aws eks wait cluster-active --name $CLUSTER_NAME --region $REGION

echo "EKS cluster created successfully!"
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

echo "Testing cluster connection..."

until kubectl get nodes 2>/dev/null | grep -q "Ready"; do
  echo "Waiting for nodes to be ready..."
  sleep 20
done


echo ""
echo "🎉 EKS cluster is ready!"
echo ""
#echo "To delete the cluster later:"
#echo "eksctl delete cluster --name $CLUSTER_NAME --region $REGION"

echo "Deploying website on eks"
  kubectl apply -f k8s-Hub-app/K8s-files
 
echo " now get access to web throught svc"

until kubectl get svc/k8s-app -o wide 2>/dev/null | tee ExternalIP.txt | grep -q "Ready"; do
   echo "Getting External IP..."
   sleep 15
done


  echo "Copy External IP and past in sarch-bar ExternalIP:3000"


