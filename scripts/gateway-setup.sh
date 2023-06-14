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

echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "IF1:                       ${IF1}"
echo "IF2:                       ${IF2}"
echo "INFRA_GATEWAY_IP_ADDRESS:  ${INFRA_GATEWAY_IP_ADDRESS}"
echo "TENANT_GATEWAY_IP_ADDRESS: ${TENANT_GATEWAY_IP_ADDRESS}"
echo "INFRA_SUBNET:              ${INFRA_SUBNET}"
echo "TENANT_SUBNET:             ${TENANT_SUBNET}"
echo "HTTP_REGISTRY_PORT:        ${HTTP_REGISTRY_PORT}"

# Set Hostname
echo
echo "#################################"
echo "Setup Hostname ..."
echo "#################################"
hostnamectl set-hostname gw-1
nmcli general hostname gw-1


# Set IP Addresses
echo
echo "#################################"
echo "Setup IP Addresses ..."
echo "#################################"
nmcli conn mod ${IF1} connection.autoconnect yes
nmcli device reapply ${IF1}
# Rename Interface-2
nmcli connection modify "Wired connection 1" connection.id "${IF2}"
nmcli conn mod ${IF2} ipv4.address ${INFRA_GATEWAY_IP_ADDRESS}/24,${TENANT_GATEWAY_IP_ADDRESS}/24
nmcli conn mod ${IF2} ipv4.method static
nmcli conn mod ${IF2} connection.autoconnect yes
nmcli device reapply ${IF2}

# Stop firewalld
echo
echo "#################################"
echo "Disable firewalld ..."
echo "#################################"
systemctl stop firewalld

# Configure IP Forwarding
echo
echo "#################################"
echo "Set sysctl params ..."
echo "#################################"
cat /proc/sys/net/ipv4/ip_forward
sysctl -a | grep ip_forward
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/99-sysctl.conf
sysctl --system

# IP Tables
echo
echo "#################################"
echo "Configure IP Tables ..."
echo "#################################"
dnf install iptables-services -y
dnf remove firewalld -y
systemctl enable --now iptables
iptables-save
iptables -t nat -I POSTROUTING --src ${INFRA_SUBNET} -j MASQUERADE
iptables -t nat -I POSTROUTING --src ${TENANT_SUBNET} -j MASQUERADE
iptables -I FORWARD --j ACCEPT
iptables -I INPUT -p tcp --dport ${HTTP_REGISTRY_PORT} -j ACCEPT
iptables-save > /etc/sysconfig/iptables

# Setup HTTP registry
echo
echo "#################################"
echo "Setup HTTP registry ..."
echo "#################################"
dnf install podman -y
mkdir -p /opt/registry/data
podman run --name mirror-registry \
  -p ${HTTP_REGISTRY_PORT}:${HTTP_REGISTRY_PORT} -v /opt/registry/data:/var/lib/registry:z \
  -d docker.io/library/registry:2
podman generate systemd --name mirror-registry > /etc/systemd/system/mirror-registry-container.service
systemctl daemon-reload
systemctl enable --now mirror-registry-container


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
