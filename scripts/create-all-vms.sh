#!/bin/bash

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

# Source the variables in other files
. variables.sh


if [[ $USER != "root" ]]; then
    echo "ERROR: \"root\" or \"sudo\" required."
    exit
fi

BASE_VM=${BASE_VM:-"infra-1"}

echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "BASE_VM              = ${BASE_VM}"
echo "GATEWAY_LIST         = ${GATEWAY_LIST[*]}"
echo "INFRA_CTRL_LIST      = ${INFRA_CTRL_LIST[*]}"
echo "INFRA_DPU_LIST       = ${INFRA_DPU_LIST[*]}"
echo "TENANT_CTRL_LIST     = ${TENANT_CTRL_LIST[*]}"
echo "TENANT_DPU_HOST_LIST = ${TENANT_DPU_HOST_LIST[*]}"
echo "TENANT_WORKER_LIST   = ${TENANT_WORKER_LIST[*]}"


echo
echo "#################################"
echo "Shutdown ${BASE_VM} ..."
echo "#################################"
echo "virsh shutdown ${BASE_VM}"
virsh shutdown ${BASE_VM}

# Wait for VM to go to "shut off" state
FOUND=false
for ((i=1; i<=10; i++))
do
    sleep 1
    VM_STATE=$(virsh list --all | grep ${BASE_VM} | awk -F' {2,}' '{print $3}')
    echo "${BASE_VM} state: ${VM_STATE}"
    if [[ ${VM_STATE} == "shut off" ]]; then
        FOUND=true
        break
    fi
done
if [[ ${FOUND} == false ]]; then
    echo "${BASE_VM} not shutdown, make sure it is shutdown and rerun."
    exit 1
else
    echo "${BASE_VM} has shutdown"
fi


echo
echo "#################################"
echo "Clone ${BASE_VM} to Gateway Nodes ..."
echo "#################################"
for NODE in "${GATEWAY_LIST[@]}"
do
    VM_STATE=$(virsh list --all | grep ${NODE} | awk -F' {2,}' '{print $3}')
    if [[ -z ${VM_STATE} ]]; then
        echo "${NODE} does not exist. Creating ..."
        virt-clone --connect qemu:///system --original ${BASE_VM} --name ${NODE} --file /var/lib/libvirt/images/${NODE}.qcow2
    else
        echo "${NODE} already exists. VM_STATE=${VM_STATE}"
    fi
done


echo
echo "#################################"
echo "Clone ${BASE_VM} to Infra Control Plane Nodes ..."
echo "#################################"
for NODE in "${INFRA_CTRL_LIST[@]}"
do
    VM_STATE=$(virsh list --all | grep ${NODE} | awk -F' {2,}' '{print $3}')
    if [[ -z ${VM_STATE} ]]; then
        echo "${NODE} does not exist. Creating ..."
        virt-clone --connect qemu:///system --original ${BASE_VM} --name ${NODE} --file /var/lib/libvirt/images/${NODE}.qcow2
    else
        echo "${NODE} already exists. VM_STATE=${VM_STATE}"
    fi
done


echo
echo "#################################"
echo "Clone ${BASE_VM} to Infra DPU Nodes ..."
echo "#################################"
for NODE in "${INFRA_DPU_LIST[@]}"
do
    VM_STATE=$(virsh list --all | grep ${NODE} | awk -F' {2,}' '{print $3}')
    if [[ -z ${VM_STATE} ]]; then
        echo "${NODE} does not exist. Creating ..."
        virt-clone --connect qemu:///system --original ${BASE_VM} --name ${NODE} --file /var/lib/libvirt/images/${NODE}.qcow2
    else
        echo "${NODE} already exists. VM_STATE=${VM_STATE}"
    fi
done


echo
echo "#################################"
echo "Clone ${BASE_VM} to Tenant Control Plane Nodes ..."
echo "#################################"
for NODE in "${TENANT_CTRL_LIST[@]}"
do
    VM_STATE=$(virsh list --all | grep ${NODE} | awk -F' {2,}' '{print $3}')
    if [[ -z ${VM_STATE} ]]; then
        echo "${NODE} does not exist. Creating ..."
        virt-clone --connect qemu:///system --original ${BASE_VM} --name ${NODE} --file /var/lib/libvirt/images/${NODE}.qcow2
    else
        echo "${NODE} already exists. VM_STATE=${VM_STATE}"
    fi
done


echo
echo "#################################"
echo "Clone ${BASE_VM} to Tenant Servers Hosting DPU Nodes ..."
echo "#################################"
for NODE in "${TENANT_DPU_HOST_LIST[@]}"
do
    VM_STATE=$(virsh list --all | grep ${NODE} | awk -F' {2,}' '{print $3}')
    if [[ -z ${VM_STATE} ]]; then
        echo "${NODE} does not exist. Creating ..."
        virt-clone --connect qemu:///system --original ${BASE_VM} --name ${NODE} --file /var/lib/libvirt/images/${NODE}.qcow2
    else
        echo "${NODE} already exists. VM_STATE=${VM_STATE}"
    fi
done


echo
echo "#################################"
echo "Clone ${BASE_VM} to Tenant Worker Nodes ..."
echo "#################################"
for NODE in "${TENANT_WORKER_LIST[@]}"
do
    VM_STATE=$(virsh list --all | grep ${NODE} | awk -F' {2,}' '{print $3}')
    if [[ -z ${VM_STATE} ]]; then
        echo "${NODE} does not exist. Creating ..."
        virt-clone --connect qemu:///system --original ${BASE_VM} --name ${NODE} --file /var/lib/libvirt/images/${NODE}.qcow2
    else
        echo "${NODE} already exists. VM_STATE=${VM_STATE}"
    fi
done


echo
echo "#################################"
echo "Restart ${BASE_VM} ..."
echo "#################################"
echo "virsh start ${BASE_VM}"
virsh start ${BASE_VM}


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
