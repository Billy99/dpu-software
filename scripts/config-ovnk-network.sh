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

# Based on hostname, determine Node Number and if this is infra or tenant
NODE_NAME=$(hostname -s)
NODE_NUM=${NODE_NAME#*-}
NODE_PREFIX=${NODE_NAME%-*}

if [ "${NODE_PREFIX}" == "infra" ] ; then
    IP_ADDRESS="${INFRA_OCTETS}.${NODE_NUM}/24"
    GATEWAY_IP_ADDRESS=${INFRA_GATEWAY_IP_ADDRESS}
elif [ "${NODE_PREFIX}" == "tenant" ] ; then
    IP_ADDRESS="${TENANT_OCTETS}.${NODE_NUM}/24"
    GATEWAY_IP_ADDRESS=${TENANT_GATEWAY_IP_ADDRESS}
else
    echo "Unable to parse hostname: ${NODE_NAME}"
    exit 1
fi

NODE_TYPE=$(get_node_type ${NODE_NAME})

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
echo "TAP_0:              ${TAP_0}"
echo "NODE_PREFIX:        ${NODE_PREFIX}"
echo "NODE_NUM:           ${NODE_NUM}"
echo "NODE_TYPE:          ${NODE_TYPE}"

if [[ ${NODE_TYPE} == ${GATEWAY_NODE} ]] || \
   [[ ${NODE_TYPE} == ${UNKNOWN_NODE} ]]; then
    echo
    echo "Nothing to do on node \"${NODE_NAME}\" of type ${NODE_TYPE}, exiting ..."
    exit 1
fi


if [[ ${NODE_TYPE} == ${DPU_HOST_NODE} ]] || \
   [[ ${NODE_TYPE} == ${DPU_NODE} ]]; then
    echo
    echo "#################################"
    echo "Manage TAP Interface ..."
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
    # Wired connection 1   f31bf84c-a17f-38d0-b1ea-4231bc285c29  ethernet       enp2s0f1
    # Wired connection 2   18b3021e-ef84-3814-b795-40c36b6042fb  ethernet       enp2s0f2
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
fi

if [[ ${NODE_TYPE} == ${DPU_HOST_NODE} ]]; then
    echo
    echo "#################################"
    echo "Delete OvS br-ex bridge ..."
    echo "#################################"
    # Delete br-ex and associated ports
    if [ ! -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "ovs-port-${BRIDGE_NAME}") ]; then
        echo "Deleting ovs-port-${BRIDGE_NAME}"
        nmcli conn del ovs-port-${BRIDGE_NAME}
    fi
    if [ ! -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "ovs-if-${BRIDGE_NAME}") ]; then
        echo "Deleting ovs-if-${BRIDGE_NAME}"
        nmcli conn del ovs-if-${BRIDGE_NAME}
    fi
    if [ ! -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "ovs-port-${IF2}") ]; then
        echo "Deleting ovs-port-${IF2}"
        nmcli conn del ovs-port-${IF2}
    fi
    if [ ! -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "ovs-if-${IF2}") ]; then
        echo "Deleting ovs-if-${IF2}"
        nmcli conn del ovs-if-${IF2}
    fi
    if [ ! -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "^${BRIDGE_NAME}") ]; then
        echo "Deleting ${BRIDGE_NAME}"
        nmcli conn del ${BRIDGE_NAME}
    fi
    if [ ! -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "^${IF2}") ]; then
        echo "Deleting ${IF2}"
        nmcli conn del ${IF2}
    fi


    echo
    echo "#################################"
    echo "Bind ${TAP_0} to host network and assign IP Address ..."
    echo "#################################"
    nmcli conn mod ${TAP_0} ipv4.address ${IP_ADDRESS}
    nmcli conn mod ${TAP_0} ipv4.method static
    nmcli conn mod ${TAP_0} ipv4.route-metric 50
    # Move the default route to br-ex
    nmcli conn mod ${TAP_0} ipv4.gateway ${GATEWAY_IP_ADDRESS}
    nmcli conn mod ${IF1} ipv4.never-default yes
    nmcli device reapply ${IF1}
    nmcli device reapply ${TAP_0}
fi

if [[ ${NODE_TYPE} == ${CONTROLLER_NODE} ]] || \
   [[ ${NODE_TYPE} == ${WORKER_NODE} ]] || \
   [[ ${NODE_TYPE} == ${DPU_NODE} ]]; then
    echo
    echo "#################################"
    echo "Setup OvS br-ex bridge ..."
    echo "#################################"
    # Rename Interface-2
    CONN_NAME="Wired connection 1"
    if [ ! -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "${CONN_NAME}") ]; then
        DEVICE=$(nmcli conn show "${CONN_NAME}" | grep connection.interface-name | awk -F' ' '{print $2}')
        echo "Remapping ${CONN_NAME} to ${DEVICE}"
        nmcli conn mod "${CONN_NAME}" con-name ${DEVICE}
    fi
    # Create and Configure br-ex and associated ports
    if [ -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "^${BRIDGE_NAME}") ]; then
        echo "Adding ${BRIDGE_NAME}"
        nmcli conn add type ovs-bridge conn.interface ${BRIDGE_NAME} con-name ${BRIDGE_NAME}
    fi
    if [ -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "ovs-port-${BRIDGE_NAME}") ]; then
        echo "Adding ovs-port-${BRIDGE_NAME}"
        nmcli conn add type ovs-port conn.interface ${BRIDGE_NAME} master ${BRIDGE_NAME} con-name ovs-port-${BRIDGE_NAME}
    fi
    if [ -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "ovs-if-${BRIDGE_NAME}") ]; then
        echo "Adding ovs-if-${BRIDGE_NAME}"
        nmcli conn add type ovs-interface slave-type ovs-port conn.interface ${BRIDGE_NAME} master ovs-port-${BRIDGE_NAME} con-name ovs-if-${BRIDGE_NAME}
    fi
    if [ -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "ovs-port-${IF2}") ]; then
        echo "Adding ovs-port-${IF2}"
        nmcli conn add type ovs-port conn.interface ${IF2} master ${BRIDGE_NAME} con-name ovs-port-${IF2}
    fi
    if [ -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "ovs-if-${IF2}") ]; then
        echo "Adding ovs-if-${IF2}"
        nmcli conn add type ethernet conn.interface ${IF2} master ovs-port-${IF2} con-name ovs-if-${IF2}
    fi
    if [ ! -z $(nmcli conn show | awk -F' {2,}' '{print $1}' | grep -w "^${IF2}") ]; then
        echo "Deleting ${IF2}"
        nmcli conn delete ${IF2}
    fi
    nmcli conn mod ${BRIDGE_NAME} connection.autoconnect yes
    nmcli conn mod ovs-if-${BRIDGE_NAME} connection.autoconnect yes
    nmcli conn mod ovs-if-${IF2} connection.autoconnect yes
    nmcli conn mod ovs-port-${IF2} connection.autoconnect yes
    nmcli conn mod ovs-port-${BRIDGE_NAME} connection.autoconnect yes
    nmcli conn mod ovs-if-${BRIDGE_NAME} ipv4.address ${IP_ADDRESS}
    nmcli conn mod ovs-if-${BRIDGE_NAME} ipv4.method static
    nmcli conn mod ovs-if-${BRIDGE_NAME} ipv4.route-metric 50
    # Move the default route to br-ex
    nmcli conn mod ovs-if-${BRIDGE_NAME} ipv4.gateway ${GATEWAY_IP_ADDRESS}
    nmcli conn mod ${IF1} ipv4.never-default yes

    DEVICE=$(nmcli conn show "${IF1}" | grep connection.interface-name | awk -F' ' '{print $2}')
    echo "Reapplying ${IF1}/${DEVICE}"
    nmcli device reapply ${DEVICE}

    DEVICE=$(nmcli conn show "ovs-if-${BRIDGE_NAME}" | grep connection.interface-name | awk -F' ' '{print $2}')
    echo "Reapplying ovs-if-${BRIDGE_NAME}/${DEVICE}"
    nmcli device reapply ${DEVICE}

    DEVICE=$(nmcli conn show "ovs-if-${IF2}" | grep connection.interface-name | awk -F' ' '{print $2}')
    echo "Reapplying ovs-if-${IF2}/${DEVICE}"
    nmcli device reapply ${DEVICE}

    DEVICE=$(nmcli conn show "ovs-port-${BRIDGE_NAME}" | grep connection.interface-name | awk -F' ' '{print $2}')
    echo "Reapplying ovs-port-${BRIDGE_NAME}/${DEVICE}"
    nmcli device reapply ${DEVICE}

    DEVICE=$(nmcli conn show "ovs-port-${IF2}" | grep connection.interface-name | awk -F' ' '{print $2}')
    echo "Reapplying ovs-port-${IF2}/${DEVICE}"
    nmcli device reapply ${DEVICE}
fi


echo
echo "#################################"
echo "Setup DNS ..."
echo "#################################"
nmcli conn mod ${IF1} ipv4.ignore-auto-dns yes
if [[ ${NODE_TYPE} == ${DPU_HOST_NODE} ]]; then
    nmcli conn mod ${TAP_0} ipv4.dns ${DNS_IP_ADDRESS}
else
    nmcli conn mod ovs-if-${BRIDGE_NAME} ipv4.dns ${DNS_IP_ADDRESS}
fi
sed -i '/#DNS=/c\DNS='"$DNS_IP_ADDRESS"'' /etc/systemd/resolved.conf
sed -i '/#DNSSEC=/c\DNSSEC=no' /etc/systemd/resolved.conf
sed -i '/#DNSOverTLS=/c\DNSOverTLS=opportunistic' /etc/systemd/resolved.conf
sed -i '/#DNSStubListener=/c\DNSStubListener=yes' /etc/systemd/resolved.conf
systemctl restart systemd-resolved


echo
echo "#################################"
echo "Mark the Registry on Gateway as Insecure ..."
echo "#################################"
mkdir -p /etc/containers/registries.conf.d/
cat >/etc/containers/registries.conf.d/999-insecure.conf <<EOL
[[registry]]
location = "${GATEWAY_IP_ADDRESS}:5000"
insecure = true
EOL


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
