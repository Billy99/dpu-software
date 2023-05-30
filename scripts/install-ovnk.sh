#!/bin/bash

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

# Source the variables in other files
. variables.sh

GATEWAY_IP_ADDRESS=${INFRA_GATEWAY_IP_ADDRESS}
OVN_IMAGE=${GATEWAY_IP_ADDRESS}:${HTTP_REGISTRY_PORT}/ovn-daemonset-f:latest

echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "OVN_IMAGE: ${OVN_IMAGE}"


echo
echo "#################################"
echo "Download OVN-Kubernetes ..."
echo "#################################"
mkdir -p ~/src/
pushd ~/src/
git clone https://github.com/ovn-org/ovn-kubernetes.git
popd

pushd ~/src/ovn-kubernetes/


echo
echo "#################################"
echo "Build OVN-Kubernetes ..."
echo "#################################"
pushd go-controller/
make
popd


echo
echo "#################################"
echo "Build OVN-Kube Image and Push to Registry ..."
echo "#################################"
pushd dist/images/
find ../../go-controller/_output/go/bin/ -maxdepth 1 -type f -exec cp -f {} . \;
echo "ref: $(git rev-parse  --symbolic-full-name HEAD)  commit: $(git rev-parse  HEAD)" > git_info
podman build -t ${OVN_IMAGE} -f Dockerfile.fedora .
podman push ${OVN_IMAGE}
popd


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
