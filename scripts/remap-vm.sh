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

node_prefix=$1
if [ -z "${node_prefix}" ]; then
    echo "Node Prefix required: [i|infra|t|tenant]"
    exit 1
fi

node_num=$2
if [ -z "${node_num}" ]; then
    echo "Node Number required"
    exit 1
fi

if [ "${node_prefix}" == "i" ] || [ "${node_prefix}" == "infra" ] ; then
    NODE_NAME="infra-${node_num}"
    IP_ADDRESS="${INFRA_OCTETS}.${node_num}/24"
    GATEWAY_IP_ADDRESS=${INFRA_GATEWAY_IP_ADDRESS}
elif [ "${node_prefix}" == "t" ] || [ "${node_prefix}" == "tenant" ] ; then
    NODE_NAME="tenant-${node_num}"
    IP_ADDRESS="${TENANT_OCTETS}.${node_num}/24"
    GATEWAY_IP_ADDRESS=${TENANT_GATEWAY_IP_ADDRESS}
else
    echo "Node Prefix required: [i|infra|t|tenant]"
    exit 1
fi


echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "NODE_NAME:          ${NODE_NAME}"
echo "IP_ADDRESS:         ${IP_ADDRESS}"
echo "GATEWAY_IP_ADDRESS: ${GATEWAY_IP_ADDRESS}"
echo "DNS_IP_ADDRESS:     ${DNS_IP_ADDRESS}"
echo "BRIDGE_NAME:        ${BRIDGE_NAME}"
echo "IF1:                ${IF1}"
echo "IF2:                ${IF2}"


echo
echo "#################################"
echo "Setup Hostname ..."
echo "#################################"
echo "Set hostname to ${NODE_NAME}"
hostnamectl set-hostname ${NODE_NAME}
nmcli general hostname ${NODE_NAME}


echo
echo "#################################"
echo "Update IP Address ..."
echo "#################################"

echo "Set IP to ${IP_ADDRESS}"
nmcli conn mod ovs-if-${BRIDGE_NAME} ipv4.address ${IP_ADDRESS}

echo "Set Gateway to ${GATEWAY_IP_ADDRESS}"
nmcli conn mod ovs-if-${BRIDGE_NAME} ipv4.gateway ${GATEWAY_IP_ADDRESS}
nmcli device reapply ${BRIDGE_NAME}

echo "Update registry to point to Gateway ${GATEWAY_IP_ADDRESS}:5000"
sed -i '/location =/c\location = '"${GATEWAY_IP_ADDRESS}:5000"'' /etc/containers/registries.conf.d/999-insecure.conf


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
