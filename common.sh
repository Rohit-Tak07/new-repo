#!/bin/bash
#
# Common setup for ALL SERVERS (Control Plane and Nodes)
# will run on Ubuntu Server 22.04 LTS
# If you see some warning at certificates, RUN AGAIN

#set -euxo pipefail
apt-get update -y
# Variable Declaration

KUBERNETES_VERSION="1.29.0-1.1"

# disable swap
echo ""
echo  "\033[4mDisabling Swap Memory.\033[0m"
echo ""
sudo swapoff -a
sed -e '/swap/s/^/#/g' -i /etc/fstab

# Install CRI-O Runtime
echo ""
echo  "\033[4mInstalling CRI-O | Kubelet | Kubeadm | Kubectl.\033[0m"
echo ""
OS="xUbuntu_22.04"

VERSION="1.23"

# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/crio.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Set up required sysctl params, these persist across reboots.
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

#### NEW location for keyrings
echo
echo
echo "****************************************"
echo "INSTALLING CRI-O KUBEADM KUBECTL KUBELET"
echo "****************************************"
echo
echo
apt-get update -y
apt-get install -y software-properties-common curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" |
    tee /etc/apt/sources.list.d/kubernetes.list

curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

apt-get update -y
apt-get install -y cri-o cri-tools kubelet kubeadm kubectl




echo ""
echo  "\033[4mConfiguring CRI-O to use dockerhub.\033[0m"
echo ""
cat <<EOF | sudo tee /etc/crio/crio.conf
registries = [
"docker.io"
]
EOF

systemctl restart crio
echo ""
echo  "\033[4mCRI-O installed and configured.\033[0m"
echo ""
echo  "\033[4mSetting nameservers.\033[0m"
echo ""
#sudo systemctl stop systemd-resolved
#sudo rm /etc/resolv.conf
#create new /etc/resolv.conf with no loopback entry
#systemctl start systemd-resolved
#systemctl enable systemd-resolved


apt install resolvconf -y
systemctl start resolvconf.service
systemctl enable resolvconf.service
cat <<EOF | sudo tee /etc/resolvconf/resolv.conf.d/head
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

systemctl restart resolvconf.service
systemctl restart systemd-resolved.service

echo ""
echo "===="
echo "Generate token on manager using"
echo "==="
echo "kubeadm token create --print-join-command"
echo ""
echo ""