#!/bin/bash

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

# Source the variables in other files
. variables.sh


usage() {
    echo ""
    echo "./scripts/deployment.sh start"
    echo "     Create all the bridges and taps, then start VMs."
    echo "./scripts/deployment.sh stop"
    echo "     Stop the VMs, the delete all the bridges and taps."
    echo "./scripts/deployment.sh up"
    echo "     Bring all the bridges and taps UP."
    echo ""
}


create() {
    node_num=$1
    vf_num=$2

    bridge_name="br${node_num}-vf${vf_num}"
    tap_infra="tap${node_num}-vf${vf_num}-i"
    tap_tenant="tap${node_num}-vf${vf_num}-t"

    echo "Create Bridge ${bridge_name} and taps ${tap_infra} and ${tap_tenant}"

    # Create Bridge
    ip link add name ${bridge_name} type bridge
    ip link set dev ${bridge_name} up

    # Create Tap for Infra and Tenant
    ip tuntap add mode tap ${tap_infra}
    ip link set dev ${tap_infra} up

    ip tuntap add mode tap ${tap_tenant}
    ip link set dev ${tap_tenant} up

    ip link set ${tap_infra} master ${bridge_name}
    ip link set ${tap_tenant} master ${bridge_name}
}

delete() {
    node_num=$1
    vf_num=$2

    bridge_name="br${node_num}-vf${vf_num}"
    tap_infra="tap${node_num}-vf${vf_num}-i"
    tap_tenant="tap${node_num}-vf${vf_num}-t"

    echo "Delete Bridge ${bridge_name} and taps ${tap_infra} and ${tap_tenant}"

    # Delete Tap for Infra and Tenant
    ip link delete ${bridge_name}
    ip link delete ${tap_infra}
    ip link delete ${tap_tenant}
}


iface_up() {
    node_num=$1
    vf_num=$2

    bridge_name="br${node_num}-vf${vf_num}"
    tap_infra="tap${node_num}-vf${vf_num}-i"
    tap_tenant="tap${node_num}-vf${vf_num}-t"

    echo "Enable ${bridge_name} and taps ${tap_infra} and ${tap_tenant}"

    ip link set dev ${bridge_name} up
    ip link set dev ${tap_infra} up
    ip link set dev ${tap_tenant} up
}


if [ $USER != "root" ]; then
    echo "ERROR: \"root\" or \"sudo\" required."
    exit
fi

if [ ${#INFRA_DPU_LIST[@]} != ${#TENANT_DPU_HOST_LIST[@]} ]; then
    echo "ERROR: INFRA_DPU_LIST[${#INFRA_DPU_LIST[@]}] must hast same number of entries as TENANT_DPU_HOST_LIST[${#TENANT_DPU_HOST_LIST[@]}]."
    exit
fi

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
echo "START_VF             = ${START_VF}"
echo "END_VF               = ${END_VF}"

case "$1" in
  "start")
    echo
    echo "#################################"
    echo "Create interfaces"
    echo "#################################"
    for NODE in "${INFRA_DPU_LIST[@]}"
    do
        i=${NODE#*-}
        #echo "For Node ${NODE}: i=$i"
        for  (( j=$START_VF; j<=$END_VF; j++ ))
        do
            #echo "  create $i $j"
            create $i $j
        done
    done

    echo
    echo "#################################"
    echo "Starting VMs"
    echo "#################################"
    for NODE in "${GATEWAY_LIST[@]}"
    do
        #echo "  Start: ${NODE}"
        virsh start ${NODE}
    done
    for NODE in "${INFRA_CTRL_LIST[@]}"
    do
        #echo "  Start: ${NODE}"
        virsh start ${NODE}
    done
    for NODE in "${INFRA_DPU_LIST[@]}"
    do
        #echo "  Start: ${NODE}"
        virsh start ${NODE}
    done
    for NODE in "${TENANT_CTRL_LIST[@]}"
    do
        #echo "  Start: ${NODE}"
        virsh start ${NODE}
    done
    for NODE in "${TENANT_DPU_HOST_LIST[@]}"
    do
        #echo "  Start: ${NODE}"
        virsh start ${NODE}
    done
    for NODE in "${TENANT_WORKER_LIST[@]}"
    do
        #echo "  Start: ${NODE}"
        virsh start ${NODE}
    done
    ;;
  "stop")
    echo
    echo "#################################"
    echo "Shutting down VMs"
    echo "#################################"
    for NODE in "${TENANT_WORKER_LIST[@]}"
    do
        #echo "  Shutdown: ${NODE}"
        virsh shutdown ${NODE}
    done
    for NODE in "${TENANT_DPU_HOST_LIST[@]}"
    do
        #echo "  Shutdown: ${NODE}"
        virsh shutdown ${NODE}
    done
    for NODE in "${TENANT_CTRL_LIST[@]}"
    do
        #echo "  Shutdown: ${NODE}"
        virsh shutdown ${NODE}
    done
    for NODE in "${INFRA_DPU_LIST[@]}"
    do
        
        #echo "  Shutdown: ${NODE}"
        virsh shutdown ${NODE}
    done
    for NODE in "${INFRA_CTRL_LIST[@]}"
    do
        #echo "  Shutdown: ${NODE}"
        virsh shutdown ${NODE}
    done
    for NODE in "${GATEWAY_LIST[@]}"
    do
        #echo "  Shutdown: ${NODE}"
        virsh shutdown ${NODE}
    done
    sleep 10

    echo
    echo "#################################"
    echo "Cleanup interfaces"
    echo "#################################"
    for NODE in "${INFRA_DPU_LIST[@]}"
    do
        i=${NODE#*-}
        #echo "For Node ${NODE}: i=$i"
        for  (( j=$START_VF; j<=$END_VF; j++ ))
        do
            #echo "  delete $i $j"
            delete $i $j
        done
    done
    ;;
  "up")
    for NODE in "${INFRA_DPU_LIST[@]}"
    do
        i=${NODE#*-}
        #echo "For Node ${NODE}: i=$i"
        for  (( j=$START_VF; j<=$END_VF; j++ ))
        do
            #echo "  iface_up $i $j"
            iface_up $i $j
        done
    done
    ;;
  "help"|"--help"|"?")
    usage
    ;;
  *)
    echo "Unknown input: $1"
    echo
    usage
    ;;
esac


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
