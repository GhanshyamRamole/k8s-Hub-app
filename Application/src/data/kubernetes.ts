export interface KubernetesDistribution {
  id: string;
  name: string;
  description: string;
  script: string;
  prerequisites: string[];
}

export const kubernetesDistributions: KubernetesDistribution[] = [
  {
    id: "minikube",
    name: "Minikube",
    description: "Minikube is a lightweight Kubernetes implementation that creates a single-node Kubernetes cluster. It is primarily used for: \n Learning and experimenting.",
    prerequisites: [
      "Docker or VirtualBox installed",
      "At least 2GB of RAM available",
      "2 CPUs or more",
      "20GB of free disk space",
      "Internet connection"
    ],
    script: "https://github.com/GhanshyamRamole/k8s-Hub/blob/main/minikube/minikube.sh | chmod +x minikube.sh | ./minikube.sh "
  },
  {
    id: "eks",
    name: "eks",
    description: "An Amazon EKS cluster is a managed Kubernetes environment on AWS that simplifies the process of deploying, managing, and scaling containerized applications using Kubernetes..",
    prerequisites: [
      "AWS Account & IAM Setup",
      "AWS CLI must be configured using: aws configure",
      "Required Tools Installed: AWS CLI",
      "Network Requirement: A valid VPC with at least 2 subnets in different Availability Zones (EKS can auto-create this if not provided)",
      "System Requirements Linux/macOS terminal or WSL on Windows sudo/root privileges to install CLI tools Minimum RAM: 4 GB, CPU: 2 cores (on your local machine)"
    ],
    script: "https://github.com/GhanshyamRamole/k8s-Hub/blob/main/eks/eks-cluster.sh | chmod +x eks-cluster.sh | ./eks-cluster.sh "
  },
  {
    id: "microk8s",
    name: "MicroK8s",
    description: "A small, powerful Kubernetes for local testing and development.",
    prerequisites: [
      "Ubuntu 16.04 LTS or later",
      "Snap package manager",
      "At least 4GB of RAM",
      "20GB of disk space",
      "Internet connection"
    ],
    script: "sudo snap install microk8s --classic"
  },
  {
    id: "kind",
    name: "KIND",
    description: "Kubernetes IN Docker - run local Kubernetes clusters using Docker containers.",
    prerequisites: [
      "Docker installed and running",
      "Go 1.16+ (for building from source)",
      "At least 8GB of RAM",
      "Internet connection",
      "Linux: ubuntu"
    ],
    script: "https://github.com/GhanshyamRamole/k8s-Hub/blob/main/kind/kind-cluster.sh | chmod +x kind-cluster.sh | ./kind-cluster.sh"
  },
  {
    id: "k0s",
    name: "k0s",
    description: "Zero friction Kubernetes distribution with minimal resource requirements.",
    prerequisites: [
      "Linux x86-64, ARM64, or ARMv7",
      "1GB of RAM minimum",
      "1GB of disk space",
      "Network connectivity",
      "Root or sudo access"
    ],
    script: "curl -sSLf https://get.k0s.sh | sudo sh"
  },
  {
    id: "rke2",
    name: "RKE2",
    description: "Rancher Kubernetes Engine 2 - security focused Kubernetes distribution.",
    prerequisites: [
      "Linux operating system",
      "2GB of RAM minimum",
      "1GB of disk space",
      "Network connectivity",
      "Root or sudo access"
    ],
    script: "curl -sfL https://get.rke2.io | sh -"
  },
  {
    id: "kubeadm",
    name: "kubeadm",
    description: "Official Kubernetes cluster bootstrapping tool for production clusters.",
    prerequisites: [
      "Ubuntu 16.04+, Debian 9+, CentOS 7+, or RHEL 7+",
      "2GB of RAM minimum",
      "2 CPUs minimum",
      "Network connectivity between nodes",
      "Root or sudo access",
      "Container runtime (Docker, containerd, or CRI-O)"
    ],
    script: "sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl && curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg && echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main' | sudo tee /etc/apt/sources.list.d/kubernetes.list && sudo apt-get update && sudo apt-get install -y kubelet kubeadm kubectl"
  },
  {
    id: "k3d",
    name: "k3d",
    description: "Little helper to run k3s in Docker - perfect for local development.",
    prerequisites: [
      "Docker installed and running",
      "At least 512MB of RAM",
      "Network connectivity",
      "Linux, macOS, or Windows",
      "kubectl (optional but recommended)"
    ],
    script: "curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
  }
];
