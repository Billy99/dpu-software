#!/bin/bash

if [ $USER != "root" ]; then
    echo "ERROR: \"root\" or \"sudo\" required."
    exit
fi

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

# Source the variables in other files
. variables.sh

NODE_NAME=${NODE_NAME:-"infra-1"}

echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "NODE_NAME:         ${NODE_NAME}"
echo "DISABLE_FIREWALLD: ${DISABLE_FIREWALLD}"


echo
echo "#################################"
echo "Setup Hostname ..."
echo "#################################"
echo "Set hostname to ${NODE_NAME}"
hostnamectl set-hostname ${NODE_NAME}
nmcli general hostname ${NODE_NAME}


echo
echo "#################################"
echo "Disable SELinux ..."
echo "#################################"
setenforce 0
sed -i '/SELINUX=enforcing/c\SELINUX=permissive' /etc/sysconfig/selinux


echo
echo "#################################"
echo "Disable Swap ..."
echo "#################################"
# cat /proc/swaps
# Filename         Type       Size      Used  Priority
# /dev/zram0       partition  8134652   0     100
swapoff -v /dev/zram0
dnf remove -y zram-generator-defaults


if [ "$DISABLE_FIREWALLD" == true ] ; then
   echo
   echo "#################################"
   echo "Disable firewalld ..."
   echo "#################################"
   systemctl disable --now firewalld
else
   echo
   echo "#################################"
   echo "Open Firewall ports used by Kubernetes ..."
   echo "#################################"
   firewall-cmd --permanent --add-port=6443/tcp
   firewall-cmd --permanent --add-port=2379-2380/tcp
   firewall-cmd --permanent --add-port=10250/tcp
   firewall-cmd --permanent --add-port=10251/tcp
   firewall-cmd --permanent --add-port=10252/tcp
   firewall-cmd --permanent --add-port=10255/tcp
   firewall-cmd --permanent --add-port=10257/tcp
   firewall-cmd --permanent --add-port=10259/tcp

   firewall-cmd --permanent --add-port=5000/tcp

   firewall-cmd --reload
fi


echo
echo "#################################"
echo "Install required kernel modules ..."
echo "#################################"
modprobe overlay
modprobe br_netfilter

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF


# Set up required sysctl params, these persist across reboots.
# To ensure packets don't bypass IP-Tables (file may not exist):
echo
echo "#################################"
echo "Set sysctl params ..."
echo "#################################"
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
fs.inotify.max_user_instances       = 512
EOF

sysctl --system


echo
echo "#################################"
echo "Setup Kubernetes repo and download ..."
echo "#################################"
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

dnf install -y kubelet kubectl kubeadm --disableexcludes=kubernetes


echo
echo "#################################"
echo "Start and enable Kubelet ..."
echo "#################################"
systemctl enable --now kubelet


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
