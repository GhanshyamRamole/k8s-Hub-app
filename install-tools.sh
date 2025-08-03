#!/bin/bash
# install-tools.sh - Complete DevOps tools installation script

set -e

echo "🚀 Starting DevOps tools installation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Update system
update_system() {
    log "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
}

# Install Docker
install_docker() {
    if command -v docker &> /dev/null; then
        log "Docker is already installed"
        return
    fi
    
    log "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    log "Docker installed successfully"
}

# Install Java (required for Jenkins and SonarQube)
install_java() {
    if command -v java &> /dev/null; then
        log "Java is already installed"
        return
    fi
    
    log "Installing Java 17..."
    sudo apt install -y openjdk-17-jdk
    echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> ~/.bashrc
    source ~/.bashrc
}

# Install Jenkins
install_jenkins() {
    if command -v jenkins &> /dev/null; then
        log "Jenkins is already installed"
        return
    fi
    
    log "Installing Jenkins..."
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo apt-key add -
    sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt update
    sudo apt install -y jenkins
    
    # Start Jenkins
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    
    # Wait for Jenkins to start
    log "Waiting for Jenkins to start..."
    sleep 30
    
    # Get initial admin password
    if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
        log "Jenkins initial admin password:"
        sudo cat /var/lib/jenkins/secrets/initialAdminPassword
    fi
    
    log "Jenkins installed successfully. Access it at http://$(curl -s ifconfig.me):8080"
}

# Install SonarQube
install_sonarqube() {
    log "Installing SonarQube..."
    
    # Create SonarQube user
    sudo useradd -r -s /bin/false sonarqube || true
    
    # Download and install SonarQube
    cd /opt
    sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.1.69595.zip
    sudo unzip sonarqube-9.9.1.69595.zip
    sudo mv sonarqube-9.9.1.69595 sonarqube
    sudo chown -R sonarqube:sonarqube /opt/sonarqube
    
    # Create systemd service
    sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOF
[Unit]
Description=SonarQube service
After=syslog.target network.target

[Service]
Type=forking
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
User=sonarqube
Group=sonarqube
Restart=always
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
    
    # Start SonarQube
    sudo systemctl daemon-reload
    sudo systemctl start sonarqube
    sudo systemctl enable sonarqube
    
    log "SonarQube installed successfully. Access it at http://$(curl -s ifconfig.me):9000"
    log "Default credentials: admin/admin"
}

# Install Trivy
install_trivy() {
    if command -v trivy &> /dev/null; then
        log "Trivy is already installed"
        return
    fi
    
    log "Installing Trivy..."
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
    echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
    sudo apt-get update
    sudo apt-get install -y trivy
    
    log "Trivy installed successfully"
}

# Install AWS CLI
install_aws_cli() {
    if command -v aws &> /dev/null; then
        log "AWS CLI is already installed"
        return
    fi
    
    log "Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
    rm -rf aws awscliv2.zip
    
    log "AWS CLI installed successfully"
}

# Install kubectl
install_kubectl() {
    if command -v kubectl &> /dev/null; then
        log "kubectl is already installed"
        return
    fi
    
    log "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
    
    log "kubectl installed successfully"
}

# Install eksctl
install_eksctl() {
    if command -v eksctl &> /dev/null; then
        log "eksctl is already installed"
        return
    fi
    
    log "Installing eksctl..."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv /tmp/eksctl /usr/local/bin
    
    log "eksctl installed successfully"
}

# Install Helm
install_helm() {
    if command -v helm &> /dev/null; then
        log "Helm is already installed"
        return
    fi
    
    log "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    
    log "Helm installed successfully"
}

# Install ArgoCD CLI
install_argocd_cli() {
    if command -v argocd &> /dev/null; then
        log "ArgoCD CLI is already installed"
        return
    fi
    
    log "Installing ArgoCD CLI..."
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
    
    log "ArgoCD CLI installed successfully"
}

# Install Node.js and npm
install_nodejs() {
    if command -v node &> /dev/null; then
        log "Node.js is already installed"
        return
    fi
    
    log "Installing Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    
    log "Node.js installed successfully"
}

# Configure system limits
configure_system() {
    log "Configuring system limits..."
    
    # Increase file limits for SonarQube
    echo 'sonarqube   -   nofile   65536' | sudo tee -a /etc/security/limits.conf
    echo 'sonarqube   -   nproc    4096' | sudo tee -a /etc/security/limits.conf
    
    # Configure sysctl for SonarQube
    echo 'vm.max_map_count=524288' | sudo tee -a /etc/sysctl.conf
    echo 'fs.file-max=131072' | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
}

# Display installation summary
display_summary() {
    log "Installation Summary:"
    echo "=================================="
    
    # Check installed tools
    tools=("docker" "java" "jenkins" "trivy" "aws" "kubectl" "eksctl" "helm" "argocd" "node")
    
    for tool in "${tools[@]}"; do
        if command -v $tool &> /dev/null; then
            version=$(case $tool in
                "java") java -version 2>&1 | head -n 1 ;;
                "docker") docker --version ;;
                "jenkins") echo "Jenkins installed" ;;
                "aws") aws --version ;;
                "kubectl") kubectl version --client --short 2>/dev/null || echo "kubectl installed" ;;
                "eksctl") eksctl version ;;
                "helm") helm version --short ;;
                "argocd") argocd version --client --short 2>/dev/null || echo "argocd installed" ;;
                "node") node --version ;;
                "trivy") trivy --version ;;
            esac)
            echo "✅ $tool: $version"
        else
            echo "❌ $tool: Not installed"
        fi
    done
    
    echo "=================================="
    log "Access URLs:"
    PUBLIC_IP=$(curl -s ifconfig.me)
    echo "🌐 Jenkins: http://$PUBLIC_IP:8080"
    echo "🌐 SonarQube: http://$PUBLIC_IP:9000"
    echo ""
    log "Next Steps:"
    echo "1. Configure AWS CLI: aws configure"
    echo "2. Setup Jenkins plugins and credentials"
    echo "3. Configure SonarQube projects and webhooks"
    echo "4. Create EKS cluster: ./eks-setup.sh"
    echo "5. Deploy application: ./deploy.sh"
}

# Main installation function
main() {
    log "Starting complete DevOps tools installation..."
    
    update_system
    install_java
    install_docker
    install_nodejs
    install_jenkins
    install_sonarqube
    install_trivy
    install_aws_cli
    install_kubectl
    install_eksctl
    install_helm
    install_argocd_cli
    configure_system
    
    log "All tools installed successfully!"
    display_summary
    
    warn "Please reboot the system to ensure all changes take effect"
    warn "After reboot, configure AWS CLI with: aws configure"
}

# Run main function
main "$@"
