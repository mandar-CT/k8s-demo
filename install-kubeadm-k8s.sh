#!/bin/sh

#ALLOW BRIDGED TRAFFIC FOR KUBEADM
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

#INSTALL K8S PRE-REQUISITES
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl

#DOWNLOAD GOOGLE CLOUD PUBLIC SIGNINIG KEY
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# ADD K8S APT REPO
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# INSTALL K8S COMPONENTS
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
kubectl taint nodes --all node-role.kubernetes.io/master-
sudo touch /etc/docker/daemon.json
cat <<EOF | sudo tee /etc/docker/daemon.json
{
        "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab
#init 6
sudo systemctl daemon-reload
sudo systemctl restart docker
kubeadm init --ignore-preflight-errors=all
export KUBECONFIG=/etc/kubernetes/admin.conf
sudo cp /etc/kubernetes/admin.conf $HOME/admin.conf
sudo chown $(id -u):$(id -g) $HOME/admin.conf
token=$(kubeadm token generate)
rm -f home/ubuntu/nodes-join-token.out
kubeadm token create $token --print-join-command --ttl=0 > /home/ubuntu/nodes-join-token.out
cat /home/ubuntu/nodes-join-token.out
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"
#kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
kubectl get cs
kubectl get componentstatus
kubectl cluster-info
kubectl get pods -n kube-system


#sudo kubeadm reset
#kubectl -n kube-system get cm kubeadm-config -o yaml

mv  $HOME/.kube $OME/.kube.bak
mkdir $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
sudo systemctl restart docker.service
sudo systemctl enable docker.service
sudo service kubelet restart
