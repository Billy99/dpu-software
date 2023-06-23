#!/bin/bash

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

# Source the variables in other files
. variables.sh


push_scripts() {
    node_name=$1
    ip_addr=$2

    echo "Pushing \"scripts\" to ${node_name} ${ip_addr}"
    scp -r ../scripts/. ${USER}@${ip_addr}:${WORKING_DIR}/dpu-software/scripts/.
    echo
}

push_yaml() {
    node_name=$1
    ip_addr=$2
    NODE_PREFIX=${node_name%-*}

    echo "Pushing \"yaml\" to ${node_name} ${ip_addr}"
    scp -r ../data/${NODE_PREFIX}/yaml/. ${USER}@${ip_addr}:${WORKING_DIR}/dpu-software/data/${NODE_PREFIX}/yaml/.
    echo
}

pull_output() {
    node_name=$1
    ip_addr=$2
    NODE_PREFIX=${node_name%-*}

    echo "Pulling \"output\" from ${node_name} ${ip_addr}"
    scp -r ${USER}@${ip_addr}:${WORKING_DIR}/dpu-software/data/${NODE_PREFIX}/output/. ../data/${NODE_PREFIX}/output/.
    echo
}

push_output() {
    node_name=$1
    ip_addr=$2
    NODE_PREFIX=${node_name%-*}

    echo "Pushing \"output\" to ${node_name} ${ip_addr}"
    scp -r ../data/${NODE_PREFIX}/output/. ${USER}@${ip_addr}:${WORKING_DIR}/dpu-software/data/${NODE_PREFIX}/output/.
    echo
}

echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "WORKING_DIR          = ${WORKING_DIR}"
echo "USER                 = ${USER}"
echo "GATEWAY_LIST         = ${GATEWAY_LIST[*]}"
echo "INFRA_CTRL_LIST      = ${INFRA_CTRL_LIST[*]}"
echo "INFRA_DPU_LIST       = ${INFRA_DPU_LIST[*]}"
echo "TENANT_CTRL_LIST     = ${TENANT_CTRL_LIST[*]}"
echo "TENANT_DPU_HOST_LIST = ${TENANT_DPU_HOST_LIST[*]}"
echo "TENANT_WORKER_LIST   = ${TENANT_WORKER_LIST[*]}"


echo
echo "#################################"
echo "Push dpu-software to all VMs"
echo "#################################"
for NODE in "${GATEWAY_LIST[@]}"
do
    NODE_IP_ADDR=$(get_node_ip ${NODE})
    if [[ -z ${NODE_IP_ADDR} ]]; then
        echo "${node_name} does not exist or is not running. Skipping ..."
    else
        push_scripts ${NODE} ${NODE_IP_ADDR}
    fi
done

for NODE in "${INFRA_CTRL_LIST[@]}"
do
    NODE_IP_ADDR=$(get_node_ip ${NODE})
    if [[ -z ${NODE_IP_ADDR} ]]; then
        echo "${node_name} does not exist or is not running. Skipping ..."
    else
        push_scripts ${NODE} ${NODE_IP_ADDR}
        push_yaml ${NODE} ${NODE_IP_ADDR}
        pull_output ${NODE} ${NODE_IP_ADDR}
    fi
done

for NODE in "${INFRA_DPU_LIST[@]}"
do
    NODE_IP_ADDR=$(get_node_ip ${NODE})
    if [[ -z ${NODE_IP_ADDR} ]]; then
        echo "${node_name} does not exist or is not running. Skipping ..."
    else
        push_scripts ${NODE} ${NODE_IP_ADDR}
        #push_yaml ${NODE} ${NODE_IP_ADDR}
        push_output ${NODE} ${NODE_IP_ADDR}
    fi
done

for NODE in "${TENANT_CTRL_LIST[@]}"
do
    NODE_IP_ADDR=$(get_node_ip ${NODE})
    if [[ -z ${NODE_IP_ADDR} ]]; then
        echo "${node_name} does not exist or is not running. Skipping ..."
    else
        push_scripts ${NODE} ${NODE_IP_ADDR}
        push_yaml ${NODE} ${NODE_IP_ADDR}
        pull_output ${NODE} ${NODE_IP_ADDR}
    fi
done

for NODE in "${TENANT_DPU_HOST_LIST[@]}"
do
    NODE_IP_ADDR=$(get_node_ip ${NODE})
    if [[ -z ${NODE_IP_ADDR} ]]; then
        echo "${node_name} does not exist or is not running. Skipping ..."
    else
        push_scripts ${NODE} ${NODE_IP_ADDR}
        #push_yaml ${NODE} ${NODE_IP_ADDR}
        push_output ${NODE} ${NODE_IP_ADDR}
    fi
done

for NODE in "${TENANT_WORKER_LIST[@]}"
do
    NODE_IP_ADDR=$(get_node_ip ${NODE})
    if [[ -z ${NODE_IP_ADDR} ]]; then
        echo "${node_name} does not exist or is not running. Skipping ..."
    else
        push_scripts ${NODE} ${NODE_IP_ADDR}
        push_output ${NODE} ${NODE_IP_ADDR}
    fi
done


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
