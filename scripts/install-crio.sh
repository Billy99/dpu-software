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

#echo
#echo "#################################"
#echo "Variables ..."
#echo "#################################"


echo
echo "#################################"
echo "Installing CRI-O ..."
echo "#################################"
dnf install -y cri-o 


echo
echo "#################################"
echo "Installing CNI Plugins ..."
echo "#################################"
mkdir -p /opt/cni/bin
wget https://github.com/containernetworking/plugins/releases/download/v1.2.0/cni-plugins-linux-amd64-v1.2.0.tgz
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.2.0.tgz
rm cni-plugins-linux-amd64-v1.2.0.tgz


# Remove /etc/cni/net.d/100-crio-bridge.conf to avoid falling back to
# CRI-O's default networking:
echo
echo "#################################"
echo "Removing CRI-O Bridge Conf ..."
echo "#################################"
mv /etc/cni/net.d/100-crio-bridge.conf ~/.


echo
echo "#################################"
echo "Enable and Start CRI-O ..."
echo "#################################"
systemctl daemon-reload
systemctl enable crio --now


#if [[ "$CALL_POPD" == true ]]; then
#    popd &>/dev/null
#fi
