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


echo
echo "#################################"
echo "Rename \"Wired connection x\" (2nd and 3rd Interfaces) ..."
echo "#################################"
# Get the list of "Wired Connection x", and rename to the device name. Depending on the
# state of the device, the output is either
# $ sudo nmcli conn
# NAME                 UUID                                  TYPE           DEVICE 
# Wired connection 1   f31bf84c-a17f-38d0-b1ea-4231bc285c29  ethernet       --     
# Wired connection 2   18b3021e-ef84-3814-b795-40c36b6042fb  ethernet       --     
# :
# OR
# $ sudo nmcli conn
# NAME                 UUID                                  TYPE           DEVICE
# Wired connection 1   f31bf84c-a17f-38d0-b1ea-4231bc285c29  ethernet       enp7s0
# Wired connection 2   18b3021e-ef84-3814-b795-40c36b6042fb  ethernet       enp8s0
# :
# The first `awk` command pulls out "Wired connection 1" and the second `awk`
# command pulls out the number (easier to manage an array of numbers instead
# of an array of words like "Wired connection 1 Wired connection 2 ...")
CONNECTION_ARRAY=($(nmcli conn show | grep "Wired connection" | awk -F' {2,}' '{print $1}' | awk -F' ' '{print $3}'))
for CONN_NUM in "${CONNECTION_ARRAY[@]}"
do
    CONN_NAME="Wired connection ${CONN_NUM}"
    DEVICE=$(nmcli conn show "${CONN_NAME}" | grep connection.interface-name | awk -F' ' '{print $2}')
    echo "Remapping ${CONN_NAME} to ${DEVICE}"
    nmcli conn mod "${CONN_NAME}" con-name ${DEVICE}
    nmcli conn mod ${DEVICE} connection.autoconnect no
done

# Set IP Addresses
echo
echo "#################################"
echo "Setup IP Addresses ..."
echo "#################################"

echo "Management Interface: Set ${IF1} to DHCP"
nmcli conn mod ${IF1} connection.autoconnect yes
nmcli device reapply ${IF1}

echo "Infra Interface: Set ${IF2} to ${INFRA_GATEWAY_IP_ADDRESS}/24"
#nmcli conn mod ${IF2} ipv4.address ${INFRA_GATEWAY_IP_ADDRESS}/24,${TENANT_GATEWAY_IP_ADDRESS}/24
nmcli conn mod ${IF2} ipv4.address ${INFRA_GATEWAY_IP_ADDRESS}/24
nmcli conn mod ${IF2} ipv4.method static
nmcli conn mod ${IF2} connection.autoconnect yes
nmcli device reapply ${IF2}

echo "Tenant Interface: Set ${IF3} to ${TENANT_GATEWAY_IP_ADDRESS}/24"
nmcli conn mod ${IF3} ipv4.address ${TENANT_GATEWAY_IP_ADDRESS}/24
nmcli conn mod ${IF3} ipv4.method static
nmcli conn mod ${IF3} connection.autoconnect yes
nmcli device reapply ${IF3}

# Stop firewalld
echo
echo "#################################"
echo "Disable firewalld ..."
echo "#################################"
echo "systemctl stop firewalld"
systemctl stop firewalld

# Configure IP Forwarding
echo
echo "#################################"
echo "Set sysctl params ..."
echo "#################################"
echo "Write /etc/sysctl.d/99-sysctl.conf"
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
