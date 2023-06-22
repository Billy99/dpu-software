#!/bin/bash

if [ $USER != "root" ]; then
    echo "ERROR: \"root\" or \"sudo\" required."
    exit
fi

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

PRINT_FMT="basic"
if [[ $1 == "bashrc" ]]; then
    PRINT_FMT="bashrc"
fi

# Source the variables in other files
. variables.sh


echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "GATEWAY_LIST         = ${GATEWAY_LIST[*]}"
echo "INFRA_CTRL_LIST      = ${INFRA_CTRL_LIST[*]}"
echo "INFRA_DPU_LIST       = ${INFRA_DPU_LIST[*]}"
echo "TENANT_CTRL_LIST     = ${TENANT_CTRL_LIST[*]}"
echo "TENANT_DPU_HOST_LIST = ${TENANT_DPU_HOST_LIST[*]}"
echo "TENANT_WORKER_LIST   = ${TENANT_WORKER_LIST[*]}"
echo


print_node_data() {
    node_name=$1
    VM_STATE=$(virsh list --all | grep ${node_name} | awk -F' {2,}' '{print $3}')
    if [[ -z ${VM_STATE} ]]; then
        echo "${node_name} does not exist. Skipping ..."
    else
        MAC_ADDR=$(virsh dumpxml ${node_name} |  grep -B 1 "network='default'"| grep "mac address" | awk -F"'" '{print $2}')
        IP_ADDR=$(journalctl -r -n 2000 | grep -m1 "${MAC_ADDR}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')

        if [[ ${PRINT_FMT} == "basic" ]]; then
            echo -e "MAC_ADDR=${MAC_ADDR}\tIP_ADDR=${IP_ADDR}  \tNODE=${node_name}"
        else
            NODE_NUM=${node_name#*-}
            NODE_PREFIX=${node_name:0:1}
            LAST_IP_OCTET=${IP_ADDR##*.}
            echo "alias vm${NODE_PREFIX}${NODE_NUM}='svm ${LAST_IP_OCTET}'"
        fi
    fi
}


for NODE in "${GATEWAY_LIST[@]}"
do
    print_node_data ${NODE}
done
for NODE in "${INFRA_CTRL_LIST[@]}"
do
    print_node_data ${NODE}
done
for NODE in "${INFRA_DPU_LIST[@]}"
do
    print_node_data ${NODE}
done
for NODE in "${TENANT_CTRL_LIST[@]}"
do
    print_node_data ${NODE}
done
for NODE in "${TENANT_DPU_HOST_LIST[@]}"
do
    print_node_data ${NODE}
done
for NODE in "${TENANT_WORKER_LIST[@]}"
do
    print_node_data ${NODE}
done


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
