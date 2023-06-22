#!/bin/bash

if [ $USER == "root" ]; then
    echo "ERROR: Don't run with \"root\" or \"sudo\"."
    exit
fi

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

# Source the variables in other files
. variables.sh

NODE_NAME=$(hostname -s)

# Based on hostname, determine Node Number and if this is infra or tenant
NODE_NUM=${NODE_NAME#*-}
NODE_PREFIX=${NODE_NAME%-*}

if [[ "${NODE_PREFIX}" == "infra" ]] ; then
    API_SERVER_IP_ADDR="${INFRA_OCTETS}.${NODE_NUM}"
    GATEWAY_IP_ADDRESS=${INFRA_GATEWAY_IP_ADDRESS}
elif [[ "${NODE_PREFIX}" == "tenant" ]] ; then
    API_SERVER_IP_ADDR="${TENANT_OCTETS}.${NODE_NUM}"
    GATEWAY_IP_ADDRESS=${TENANT_GATEWAY_IP_ADDRESS}
fi

NODE_TYPE=$(get_node_type ${NODE_NAME})

echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "NODE_NAME:          ${NODE_NAME}"
echo "API_SERVER_IP_ADDR: ${API_SERVER_IP_ADDR}"
echo "NET_CIDR:           ${NET_CIDR}"
echo "SVC_CIDR:           ${SVC_CIDR}"
echo "TAP_0:              ${TAP_0}"
echo "NODE_PREFIX:        ${NODE_PREFIX}"
echo "NODE_NUM:           ${NODE_NUM}"
echo "NODE_TYPE:          ${NODE_TYPE}"


wait_for_pod_up() {
    pod_name=$1

    POD_UP=false
    for ((i=1; i<=60; i++))
    do
        sleep 5
        POD_STATE=$(kubectl get pods -n ovn-kubernetes | grep "${pod_name}" | awk -F' {2,}' '{print $3}')
        echo "${POD_STATE} state: ${POD_STATE}"
        if [[ ${POD_STATE} == "Running" ]]; then
            CONTAINER_STR=$(kubectl get pods -n ovn-kubernetes | grep "${pod_name}" | awk -F' {2,}' '{print $2}')
            ACT_CNT=$(echo "${CONTAINER_STR}" | awk -F'/' '{print $1}')
            TOT_CNT=$(echo "${CONTAINER_STR}" | awk -F'/' '{print $2}')
            echo "${CONTAINER_STR} state: ${ACT_CNT}/${TOT_CNT}"
            if [[ ${ACT_CNT} == ${TOT_CNT} ]]; then
                POD_UP=true
                break
            fi
        fi
    done
    if [[ ${POD_UP} == false ]]; then
        echo "${pod_name} not up, make sure it is up and rerun."
        exit 1
    else
        echo "${pod_name} is up"
    fi
}


echo
echo "#################################"
echo "Launch Kubernetes ..."
echo "#################################"
kubectl get nodes &>/dev/null
if [[ $? != 0 ]]; then
    if [[ -z $(cat /etc/sysconfig/kubelet | grep ${API_SERVER_IP_ADDR}) ]]; then
        echo "Add \"--node-ip=${API_SERVER_IP_ADDR}\" to /etc/sysconfig/kubelet"
        #sudo --preserve-env=API_SERVER_IP_ADDR sh -c 'sed -i "s/KUBELET_EXTRA_ARGS=/KUBELET_EXTRA_ARGS=\"--node-ip=${API_SERVER_IP_ADDR}\"/" /etc/sysconfig/kubelet'
        sudo -E sed -i "s/KUBELET_EXTRA_ARGS=/KUBELET_EXTRA_ARGS=\"--node-ip=${API_SERVER_IP_ADDR}\"/" /etc/sysconfig/kubelet
    else
        echo "/etc/sysconfig/kubelet already contains \"--node-ip=${API_SERVER_IP_ADDR}\""
    fi

    echo "sudo -E kubeadm init --pod-network-cidr $NET_CIDR --service-cidr $SVC_CIDR --cri-socket=unix:///var/run/crio/crio.sock --apiserver-advertise-address ${API_SERVER_IP_ADDR} --control-plane-endpoint ${API_SERVER_IP_ADDR}"
    KUBEADM_OUTPUT=$(sudo -E kubeadm init --pod-network-cidr ${NET_CIDR} --service-cidr ${SVC_CIDR} --cri-socket=unix:///var/run/crio/crio.sock --apiserver-advertise-address ${API_SERVER_IP_ADDR} --control-plane-endpoint ${API_SERVER_IP_ADDR})

    if [[ $? != 0 ]]; then
        echo "${KUBEADM_OUTPUT}"
        echo
        echo "Issue with \"kubeadm init\", exiting ..."
        exit 1
    fi
    # awk implicitly reads its input line by line. The next command uses two variables.
    # n keeps track of how many times we have seen "kubeadm join". f keeps track of how
    # many lines we are supposed to print.
    #  * /kubeadm join/{n++; if (n==2)f=2;}
    #    If we reach a line containing "kubeadm join", then increment the count n by one.
    #    If n is two, then set f to two (how many lines to print).
    #  * f{print;f--;}
    #    If f is nonzero, then print the line and decrement f.
    JOIN_CMD=$(echo "${KUBEADM_OUTPUT}" | awk '/kubeadm join/{n++; if (n==2)f=2;} f{print;f--;}')
    echo
    echo "KUBEADM_OUTPUT:"
    echo "${KUBEADM_OUTPUT}"
    echo
    echo "JOIN_CMD:"
    echo "${JOIN_CMD}"
    echo "${JOIN_CMD}" > ../data/${NODE_PREFIX}/output/join_cmd.out


    echo
    echo "#################################"
    echo "Setup KubeConfig ..."
    echo "#################################"
    echo "mkdir -p $HOME/.kube"
    mkdir -p $HOME/.kube
    echo "sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config"
    sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
    echo "sudo chown $(id -u):$(id -g) $HOME/.kube/config"
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
else
    echo "Kubernetes already started"
fi


echo
echo "#################################"
echo "Create br-int in OvS ..."
echo "#################################"
if [[ -z $(sudo ovs-vsctl show | grep -m 1 "br-int") ]]; then
    echo "Adding \"br-int\""
    sudo ovs-vsctl add-br br-int
else
    echo "\"br-int\" already exists."
fi


echo
echo "#################################"
echo "Launch OVN-Kubernetes ..."
echo "#################################"

echo "Create the namespace: ../data/${NODE_PREFIX}/yaml/ovn-setup.yaml"
kubectl apply -f ../data/${NODE_PREFIX}/yaml/ovn-setup.yaml

echo "Create the database: ../data/${NODE_PREFIX}/yaml/ovnkube-db.yaml"
kubectl apply -f ../data/${NODE_PREFIX}/yaml/ovnkube-db.yaml
# Wait until the pods are up and running before progressing to the next command:
wait_for_pod_up "ovnkube-db"

echo "Create master pods: ../data/${NODE_PREFIX}/yaml/ovnkube-master.yaml"
kubectl apply -f ../data/${NODE_PREFIX}/yaml/ovnkube-master.yaml
# Wait until the pods are up and running before progressing to the next command:
wait_for_pod_up "ovnkube-master"

echo "Create ovnkube-node pods: ../data/${NODE_PREFIX}/yaml/ovnkube-node.yaml"
kubectl apply -f ../data/${NODE_PREFIX}/yaml/ovnkube-node.yaml
# Wait until the pods are up and running before progressing to the next command:
wait_for_pod_up "ovnkube-node"

echo "Delete kube-proxy"
kubectl delete ds -n kube-system kube-proxy


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
