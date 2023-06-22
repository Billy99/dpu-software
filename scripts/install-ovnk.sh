#!/bin/bash

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

# Source the variables in other files
. variables.sh

NODE_NAME="gw-1"
VM_STATE=$(sudo virsh list --all | grep ${NODE_NAME} | awk -F' {2,}' '{print $3}')
if [[ ${VM_STATE} == "running" ]]; then
    MAC_ADDR=$(sudo virsh dumpxml ${NODE_NAME} |  grep -B 1 "network='default'"| grep "mac address" | awk -F"'" '{print $2}')
    IP_ADDR=$(sudo journalctl -r -n 2000 | grep -m1 "${MAC_ADDR}" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')
else
    echo "${NODE_NAME} does not exist is not running. Push will fail."
fi

GATEWAY_IP_ADDRESS=${GATEWAY_IP_ADDRESS:-${IP_ADDR}}
OVN_IMAGE=${GATEWAY_IP_ADDRESS}:${HTTP_REGISTRY_PORT}/ovn-daemonset-f:latest

echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "WORKING_DIR:        ${WORKING_DIR}"
echo "NODE_NAME:          ${NODE_NAME}"
echo "VM_STATE:           ${VM_STATE}"
echo "IP_ADDR:            ${IP_ADDR}"
echo "GATEWAY_IP_ADDRESS: ${GATEWAY_IP_ADDRESS}"
echo "OVN_IMAGE:          ${OVN_IMAGE}"


echo
echo "#################################"
echo "Download OVN-Kubernetes ..."
echo "#################################"
mkdir -p ${WORKING_DIR}
pushd ${WORKING_DIR} &>/dev/null
if [ ! -d "./ovn-kubernetes" ]; then
    echo "ovn-kubernetes does not exist, cloning repo."
    git clone https://github.com/ovn-org/ovn-kubernetes.git
else
    echo "ovn-kubernetes already exists, skip cloning repo."
fi
popd &>/dev/null

pushd ${WORKING_DIR}/ovn-kubernetes/ &>/dev/null


echo
echo "#################################"
echo "Build OVN-Kubernetes ..."
echo "#################################"
pushd go-controller/ &>/dev/null
make
popd &>/dev/null


echo
echo "#################################"
echo "Build OVN-Kube Image and Push to Registry ..."
echo "#################################"
pushd dist/images/ &>/dev/null
find ../../go-controller/_output/go/bin/ -maxdepth 1 -type f -exec cp -f {} . \;
echo "ref: $(git rev-parse  --symbolic-full-name HEAD)  commit: $(git rev-parse  HEAD)" > git_info
podman build -t ${OVN_IMAGE} -f Dockerfile.fedora .
podman push ${OVN_IMAGE}
popd &>/dev/null


echo
echo "#################################"
echo "Generate Infra OVN-Kube YAML Files ..."
echo "#################################"

MASTER_IP="${INFRA_OCTETS}.1"
OVN_IMAGE=${INFRA_GATEWAY_IP_ADDRESS}:${HTTP_REGISTRY_PORT}/ovn-daemonset-f:latest
OVNK_NET_CIDR="${NET_CIDR}/24"

echo
echo "Variables ..."
echo "WORKING_DIR:              ${WORKING_DIR}"
echo "MASTER_IP:                ${MASTER_IP}"
echo "INFRA_GATEWAY_IP_ADDRESS: ${INFRA_GATEWAY_IP_ADDRESS}"
echo "OVN_IMAGE:                ${OVN_IMAGE}"
echo "OVNK_NET_CIDR:            ${OVNK_NET_CIDR}"
echo "SVC_CIDR:                 ${SVC_CIDR}"
echo

pushd dist/images/ &>/dev/null
./daemonset.sh --output-directory=${WORKING_DIR}/dpu-software/data/infra/yaml \
   --image=$OVN_IMAGE \
   --ovnkube-image=$OVN_IMAGE \
   --net-cidr=${OVNK_NET_CIDR} \
   --svc-cidr=${SVC_CIDR} \
   --gateway-mode=shared \
   --k8s-apiserver=https://$MASTER_IP:6443 \
   --master-loglevel=5 \
   --node-loglevel=5 \
   --dbchecker-loglevel=5 \
   '--ovn-loglevel-northd=-vconsole:info -vfile:info' \
   '--ovn-loglevel-nb=-vconsole:info -vfile:info' \
   '--ovn-loglevel-sb=-vconsole:info -vfile:info' \
   --ovn-loglevel-controller=-vconsole:info
popd &>/dev/null


echo
echo "#################################"
echo "Generate Tenant OVN-Kube YAML Files ..."
echo "#################################"

MASTER_IP="${TENANT_OCTETS}.1"
OVN_IMAGE=${TENANT_GATEWAY_IP_ADDRESS}:${HTTP_REGISTRY_PORT}/ovn-daemonset-f:latest

echo
echo "Variables ..."
echo "WORKING_DIR:               ${WORKING_DIR}"
echo "MASTER_IP:                 ${MASTER_IP}"
echo "TENANT_GATEWAY_IP_ADDRESS: ${TENANT_GATEWAY_IP_ADDRESS}"
echo "OVN_IMAGE:                 ${OVN_IMAGE}"
echo "OVNK_NET_CIDR:             ${OVNK_NET_CIDR}"
echo "SVC_CIDR:                  ${SVC_CIDR}"
echo

pushd dist/images/ &>/dev/null
./daemonset.sh --output-directory=${WORKING_DIR}/dpu-software/data/infra/yaml \
   --image=$OVN_IMAGE \
   --ovnkube-image=$OVN_IMAGE \
   --net-cidr=${OVNK_NET_CIDR} \
   --svc-cidr=${SVC_CIDR} \
   --gateway-mode=shared \
   --k8s-apiserver=https://$MASTER_IP:6443 \
   --master-loglevel=5 \
   --node-loglevel=5 \
   --dbchecker-loglevel=5 \
   '--ovn-loglevel-northd=-vconsole:info -vfile:info' \
   '--ovn-loglevel-nb=-vconsole:info -vfile:info' \
   '--ovn-loglevel-sb=-vconsole:info -vfile:info' \
   --ovn-loglevel-controller=-vconsole:info

./daemonset.sh --output-directory=${WORKING_DIR}/dpu-software/data/tenant/yaml \
   --image=$OVN_IMAGE \
   --ovnkube-image=$OVN_IMAGE \
   --net-cidr=${OVNK_NET_CIDR} \
   --svc-cidr=${SVC_CIDR} \
   --gateway-mode=shared \
   --k8s-apiserver=https://$MASTER_IP:6443 \
   --master-loglevel=5 \
   --node-loglevel=5 \
   --dbchecker-loglevel=5 \
   '--ovn-loglevel-northd=-vconsole:info -vfile:info' \
   '--ovn-loglevel-nb=-vconsole:info -vfile:info' \
   '--ovn-loglevel-sb=-vconsole:info -vfile:info' \
   --ovn-loglevel-controller=-vconsole:info
popd &>/dev/null


# Leave ovn-kubernetes directory
popd &>/dev/null


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
