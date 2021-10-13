#!/bin/sh

#Install Docker
curl --SSL https://get.docker.com | sh

# INStall Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-Linux-x86_64" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

# Download Istio and unpack it
wget https://github.com/istio/istio/releases/download/1.0.6/istio-1.0.6-linux.tar.gz
tar -xvf istio-1.0.6-linux.tar.gz


#INSTALL KUBEADM - setup K8s cluster using Kubeadm
wget https://raw.githubusercontent.com/mandar-CT/k8s-demo/main/install-kubeadm-k8s.sh 

sh install-kubeadm-k8s.sh

sleep 30

# Preconfigure kubectl for pilot
kubectl config set-context istio --cluster=istio
kubectl config set-cluster istio --server=http://localhost:8080


# Create a DOCKER_GATEWAY environment variable
export DOCKER_GATEWAY=172.28.0.1:

# Bring up Istio's control plane  
#This may be need to run multiple times because the istio pilot container/pod needs istio-api-server to be up/running
# so first time istio pilot may exit and not start 

cd istio-1.0.6

# Modify the config as ports 2379 and 2380 are used by default etcd inside kubernetes cluster
sed -i 's/2379/2385/g' install/consul/istio.yaml
sed -i 's/2380/2382/g' install/consul/istio.yaml

docker-compose -f install/consul/istio.yaml up -d
sleep 15
docker-compose -f install/consul/istio.yaml up -d

# Ensure Port 9081 is open in your AWS EC2 SG

# Bring up the application

cd ..
docker-compose -f istio-1.0.6/samples/bookinfo/platform/consul/bookinfo.yaml up -d

#  Bring up the sidecars (Envoy proxy)
docker-compose -f istio-1.0.6/samples/bookinfo/platform/consul/bookinfo.sidecars.yaml up -d
