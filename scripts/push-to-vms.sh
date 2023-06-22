#!/bin/bash

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

# Source the variables in other files
. variables.sh

push_scripts_yaml() {
    node_name=$1
    NODE_PREFIX=${node_name%-*}

    VM_STATE=$(sudo virsh list --all | grep ${node_name} | awk -F' {2,}' '{print $3}')
    if [[ ${VM_STATE} != "running" ]]; then
        echo "Push \"scripts\" and \"yaml\": ${node_name} does not exist or is not running. Skipping ..."
        echo
    else
        MAC_ADDR=$(sudo virsh dumpxml ${node_name} |  grep -B 1 "network='default'"| grep "mac address" | awk -F"'" '{print $2}')
        IP_ADDR=$(sudo journalctl -r -n 2000 | grep -m1 "${MAC_ADDR}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        echo "Pushing \"scripts\" and \"yaml\" to ${node_name} ${IP_ADDR}"
        scp -r ../scripts/. ${USER}@${IP_ADDR}:${WORKING_DIR}/dpu-software/scripts/.
        scp -r ../data/${NODE_PREFIX}/yaml/. ${USER}@${IP_ADDR}:${WORKING_DIR}/dpu-software/data/${NODE_PREFIX}/yaml/.
        echo
    fi
}

pull_output() {
    node_name=$1
    NODE_PREFIX=${node_name%-*}

    VM_STATE=$(sudo virsh list --all | grep ${node_name} | awk -F' {2,}' '{print $3}')
    if [[ ${VM_STATE} != "running" ]]; then
        echo "Pull \"output\": ${node_name} does not exist or is not running. Skipping ..."
        echo
    else
        MAC_ADDR=$(sudo virsh dumpxml ${node_name} |  grep -B 1 "network='default'"| grep "mac address" | awk -F"'" '{print $2}')
        IP_ADDR=$(sudo journalctl -r -n 2000 | grep -m1 "${MAC_ADDR}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        echo "Pulling \"output\" from ${node_name} ${IP_ADDR}"
        scp -r ${USER}@${IP_ADDR}:${WORKING_DIR}/dpu-software/data/${NODE_PREFIX}/output/. ../data/${NODE_PREFIX}/output/.
        echo
    fi
}

push_output() {
    node_name=$1
    NODE_PREFIX=${node_name%-*}

    VM_STATE=$(sudo virsh list --all | grep ${node_name} | awk -F' {2,}' '{print $3}')
    if [[ ${VM_STATE} != "running" ]]; then
        echo "Push \"output\": ${node_name} does not exist or is not running. Skipping ..."
        echo
    else
        MAC_ADDR=$(sudo virsh dumpxml ${node_name} |  grep -B 1 "network='default'"| grep "mac address" | awk -F"'" '{print $2}')
        IP_ADDR=$(sudo journalctl -r -n 2000 | grep -m1 "${MAC_ADDR}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
        echo "Pushing \"output\" to ${node_name} ${IP_ADDR}"
        scp -r ../data/${NODE_PREFIX}/output/. ${USER}@${IP_ADDR}:${WORKING_DIR}/dpu-software/data/${NODE_PREFIX}/output/.
        echo
    fi
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
    push_scripts_yaml ${NODE}
done
for NODE in "${INFRA_CTRL_LIST[@]}"
do
    push_scripts_yaml ${NODE}
    pull_output ${NODE}
done
for NODE in "${INFRA_DPU_LIST[@]}"
do
    push_scripts_yaml ${NODE}
    push_output ${NODE}
done
for NODE in "${TENANT_CTRL_LIST[@]}"
do
    push_scripts_yaml ${NODE}
    pull_output ${NODE}
done
for NODE in "${TENANT_DPU_HOST_LIST[@]}"
do
    push_scripts_yaml ${NODE}
    push_output ${NODE}
done
for NODE in "${TENANT_WORKER_LIST[@]}"
do
    push_scripts_yaml ${NODE}
    push_output ${NODE}
done


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
