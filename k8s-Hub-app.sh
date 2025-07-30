#!/bin/bash

set -e

# ----------- CONFIG -------------
GITHUB_REPO_URL="https://github.com/YourUsername/your-repo.git"
CLONE_DIR="/tmp/cloudformation-repo"
STACK_NAME="prerequisites-stack"
TEMPLATE_FILE="prerequisites.yaml"        # Update if in subfolder
REGION="us-east-1"
PARAMETERS_FILE="parameters.json"         # Optional
CAPABILITIES="CAPABILITY_IAM CAPABILITY_NAMED_IAM"

# ----------- FUNCTIONS -----------

check_and_install_aws_cli() {
  if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Installing..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
      curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip awscliv2.zip
      sudo ./aws/install
      rm -rf aws awscliv2.zip
    elif [[ "$OSTYPE" == "darwin"* ]]; then
      brew install awscli
    else
      echo "Unsupported OS. Please install AWS CLI manually."
      exit 1
    fi
  else
    echo "✅ AWS CLI is already installed."
  fi
}

configure_aws_cli() {
  echo "Checking AWS CLI configuration..."
  if ! aws sts get-caller-identity &>/dev/null; then
    echo "🔧 AWS CLI is not configured. Let's set it up:"
    aws configure
  else
    echo "✅ AWS CLI is already configured."
  fi
}

clone_or_update_repo() {
  if [ -d "$CLONE_DIR/.git" ]; then
    echo "📦 Pulling latest changes from GitHub repo..."
    git -C "$CLONE_DIR" pull
  else
    echo "📁 Cloning GitHub repo into $CLONE_DIR..."
    git clone "$GITHUB_REPO_URL" "$CLONE_DIR"
  fi
}

validate_template() {
  echo "🔍 Validating CloudFormation template..."
  aws cloudformation validate-template \
    --template-body file://$CLONE_DIR/$TEMPLATE_FILE
}

deploy_stack() {
  echo "🚀 Deploying CloudFormation stack: $STACK_NAME"

  if [ -f "$CLONE_DIR/$PARAMETERS_FILE" ]; then
    PARAMS="--parameter-overrides $(jq -r '.[] | "\(.ParameterKey)=\(.ParameterValue)"' $CLONE_DIR/$PARAMETERS_FILE)"
  else
    PARAMS=""
  fi

  aws cloudformation deploy \
    --stack-name "$STACK_NAME" \
    --template-file "$CLONE_DIR/$TEMPLATE_FILE" \
    --capabilities $CAPABILITIES \
    --region "$REGION" \
    $PARAMS \
    --no-fail-on-empty-changeset
}

print_outputs() {
  echo "📤 Stack Outputs:"
  aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --region "$REGION" \
    --query "Stacks[0].Outputs" \
    --output table
}

# ----------- EXECUTION -----------

echo "🔧 Checking prerequisites and deploying CloudFormation template..."

check_and_install_aws_cli
configure_aws_cli
clone_or_update_repo
validate_template
deploy_stack
print_outputs

echo "✅ CloudFormation stack '$STACK_NAME' deployed successfully."

