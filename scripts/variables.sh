#!/bin/bash

#
# Configurable Variables
#
IF1=${IF1:-enp1s0}
IF2=${IF2:-enp7s0}
TAP_0=${TAP_0:-enp2s0f1}
NODE_PREFIX=${NODE_PREFIX:-infra-}
INFRA_OCTETS=${INFRA_OCTETS:-"192.168.200"}
TENANT_OCTETS=${TENANT_OCTETS:-"192.168.100"}
DNS_IP_ADDRESS=${DNS_IP_ADDRESS:-"8.8.8.8"}
HTTP_REGISTRY_PORT=${HTTP_REGISTRY_PORT:-5000}
DISABLE_FIREWALLD=${DISABLE_FIREWALLD:-true}
NUM_VF=${NUM_VF:-10}

#
# Non-Configurable Variables
#
INFRA_SUBNET="${INFRA_OCTETS}.0/24"
TENANT_SUBNET="${TENANT_OCTETS}.0/24"

INFRA_GATEWAY_IP_ADDRESS="${INFRA_OCTETS}.254"
TENANT_GATEWAY_IP_ADDRESS="${TENANT_OCTETS}.254"

BRIDGE_NAME=br-ex

START_VF=0
END_VF=${NUM_VF}-1

#
# List of VMs by Purpose
#

# List of Gateway Nodes
GATEWAY_LIST=(
  "gw-1"
)

# List of Infra Control Plane Nodes
INFRA_CTRL_LIST=(
  "infra-1"
)

# List of DPUs
INFRA_DPU_LIST=(
  "infra-2"
  "infra-3"
)

# List of Tenant Control Plane Nodes
TENANT_CTRL_LIST=(
  "tenant-1"
)

# List of Worker Nodes with DPUs
TENANT_DPU_HOST_LIST=(
  "tenant-2"
  "tenant-3"
)

# List of Worker Nodes with NO DPUs
TENANT_WORKER_LIST=(
  "tenant-4"
)

# Determine type of node: Controller, DPU, DPUHost, Worker, Gateway
UNKNOWN_NODE="Unknown"
CONTROLLER_NODE="Controller"
DPU_NODE="DPU"
DPU_HOST_NODE="DPUHost"
WORKER_NODE="Worker"
GATEWAY_NODE="Gateway"
get_node_type() {
    NODE_NAME=$1
    NODE_TYPE=${UNKNOWN_NODE}

    for NODE in "${INFRA_CTRL_LIST[@]}"
    do
        if [[ ${NODE} == ${NODE_NAME} ]]; then
            NODE_TYPE=${CONTROLLER_NODE}
            break
        fi
    done
    if [[ ${NODE_TYPE} == ${UNKNOWN_NODE} ]]; then
        for NODE in "${TENANT_CTRL_LIST[@]}"
        do
            if [[ ${NODE} == ${NODE_NAME} ]]; then
                NODE_TYPE=${CONTROLLER_NODE}
                break
            fi
        done
    fi
    if [[ ${NODE_TYPE} == ${UNKNOWN_NODE} ]]; then
        for NODE in "${INFRA_DPU_LIST[@]}"
        do
            if [[ ${NODE} == ${NODE_NAME} ]]; then
                NODE_TYPE=${DPU_NODE}
                break
            fi
        done
    fi
    if [[ ${NODE_TYPE} == ${UNKNOWN_NODE} ]]; then
        for NODE in "${TENANT_DPU_HOST_LIST[@]}"
        do
            if [[ ${NODE} == ${NODE_NAME} ]]; then
                NODE_TYPE=${DPU_HOST_NODE}
                break
            fi
        done
    fi
    if [[ ${NODE_TYPE} == ${UNKNOWN_NODE} ]]; then
        for NODE in "${TENANT_WORKER_LIST[@]}"
        do
            if [[ ${NODE} == ${NODE_NAME} ]]; then
                NODE_TYPE=${WORKER_NODE}
                break
            fi
        done
    fi
    if [[ ${NODE_TYPE} == ${UNKNOWN_NODE} ]]; then
        for NODE in "${GATEWAY_LIST[@]}"
        do
            if [[ ${NODE} == ${NODE_NAME} ]]; then
                NODE_TYPE=${GATEWAY_NODE}
                break
            fi
        done
    fi

    echo ${NODE_TYPE}
}