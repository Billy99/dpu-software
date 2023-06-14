#!/bin/bash

if [ $USER != "root" ]; then
    echo "ERROR: \"root\" or \"sudo\" required."
    exit
fi

#CALL_POPD=false
#if [[ "$PWD" != */scripts ]]; then
#    pushd scripts &>/dev/null
#fi

# Source the variables in other files
#. variables.sh

echo
echo "#################################"
echo "Variables ..."
echo "#################################"

# Install CRI-O
echo
echo "#################################"
echo "Download and Installing Containerd ..."
echo "#################################"
wget https://github.com/containerd/containerd/releases/download/v1.6.18/containerd-1.6.18-linux-amd64.tar.gz
wget https://github.com/containerd/containerd/releases/download/v1.6.18/containerd-1.6.18-linux-amd64.tar.gz.sha256sum
sha256sum -c containerd-1.6.18-linux-amd64.tar.gz.sha256sum
sudo tar Cxzvf /usr/local containerd-1.6.18-linux-amd64.tar.gz
rm containerd-1.6.18-linux-amd64.tar.gz
rm containerd-1.6.18-linux-amd64.tar.gz.sha256sum

# Download the containerd.service unit file and start containerd via systemd:
echo
echo "#################################"
echo "Configure and Start Containerd ..."
echo "#################################"
wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /usr/lib/systemd/system/.
systemctl daemon-reload
systemctl enable --now containerd

# Download and install `runc`:
echo
echo "#################################"
echo "Download and install runc ..."
echo "#################################"
wget https://github.com/opencontainers/runc/releases/download/v1.1.4/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
rm runc.amd64

# Installing CNI plugins:
echo
echo "#################################"
echo "Installing CNI Plugins ..."
echo "#################################"
sudo mkdir -p /opt/cni/bin
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
sudo tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.2.0.tgz
rm cni-plugins-linux-amd64-v1.2.0.tgz

# Generate default containerd configuration file:
echo
echo "#################################"
echo "Generate default containerd configuration file and update ..."
echo "#################################"
mkdir -p /etc/containerd/
containerd config default > /etc/containerd/config.toml
# Configuring the systemd cgroup driver to use the systemd cgroup driver with runc,:
# vi /etc/containerd/config.toml
# [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#   ...
#   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#     SystemdCgroup = true  <-- Here
sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g'/etc/containerd/config.toml
systemctl restart containerd


#if [[ "$CALL_POPD" == true ]]; then
#    popd &>/dev/null
#fi
