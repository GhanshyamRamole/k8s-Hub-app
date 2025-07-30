#!/bin/bash 

echo "Cloning git repo ..."
  git clone https://github.com/GhanshyamRamole/k8s-Hub-app.git

echo "Install prerequisites and creating eks cluster"
  https://raw.githubusercontent.com/GhanshyamRamole/k8s-Hub-app/main/eks-setup.sh
  chmod +x eks-cluster.sh
  ./eks-cluster.sh

echo "Deploying website on eks"
  kubectl apply -f K8s-files
 
echo " now get access to web throught svc"
  kubectl get svc/k8s-app -o wide

  echo "Copy External IP and past in sarch-bar ExternalIP:3000"


