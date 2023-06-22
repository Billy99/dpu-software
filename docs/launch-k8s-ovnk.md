# Start and Configure Kubernetes

Start Kubernetes in the Infra Cluster.
`infra-1` is the controller node, so that is where the control-plane will
be initialized.
Then the CNI will be added.
Then other nodes (`infra-2` and `infra-3`) will be added to the cluster. 

## Launch Kubernetes and OVN-Kubernetes

Kubernetes and OVN-Kubernetes need to be started in the Infra Cluster and in
the Tenant Cluster.

### Launch Kubernetes and OVN-Kubernetes in the Infra Cluster

> Virtual Machine `infra-1` Commands: BEGIN

Log into `infra-1` VM and run the following command:
The [launch-k8s-ovnk.sh](../scripts/launch-k8s-ovnk.sh) script will launch Kubernetes
on the controller node, then start the OVN-Kubernetes CNI.
Run the script in the Infra VM.

```console
cd ${WORKING_DIR}/dpu-software/
sudo ./scripts/launch-k8s-ovnk.sh
```

**Summary:**
As a summary, the script above performs the following:

* Run `kubeadm init` to start Kubernetes.
* Save the `kubeadm join` command to a local file that will be distributed to worker nodes.
* Create `br-int` in OvS.
* Launch the CNI, OVN-Kubernetes. 

Verify Kubernetes and OVN-Kubernetes is running:

```console
$ kubectl get nodes -o wide
NAME      STATUS   ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION           CONTAINER-RUNTIME
infra-1   Ready    control-plane   6m2s   v1.27.2   192.168.200.1   <none>        Fedora Linux 37 (Thirty Seven)   6.1.13-200.fc37.x86_64   cri-o://1.24.1

$ kubectl get pods -A -o wide
NAMESPACE        NAME                              READY   STATUS    RESTARTS        AGE     IP              NODE      NOMINATED NODE   READINESS GATES
kube-system      coredns-5d78c9869d-s27c7          1/1     Running   0               5m48s   172.16.0.4      infra-1   <none>           <none>
kube-system      coredns-5d78c9869d-vmj9h          1/1     Running   0               5m48s   172.16.0.3      infra-1   <none>           <none>
kube-system      etcd-infra-1                      1/1     Running   14              6m2s    192.168.200.1   infra-1   <none>           <none>
kube-system      kube-apiserver-infra-1            1/1     Running   13              6m2s    192.168.200.1   infra-1   <none>           <none>
kube-system      kube-controller-manager-infra-1   1/1     Running   13              6m2s    192.168.200.1   infra-1   <none>           <none>
kube-system      kube-scheduler-infra-1            1/1     Running   14              6m2s    192.168.200.1   infra-1   <none>           <none>
ovn-kubernetes   ovnkube-db-788d8bfb85-jmb7g       2/2     Running   0               5m48s   192.168.200.1   infra-1   <none>           <none>
ovn-kubernetes   ovnkube-master-666b87fd45-5r7m2   2/2     Running   0               4m52s   192.168.200.1   infra-1   <none>           <none>
ovn-kubernetes   ovnkube-node-4t8wb                3/3     Running   1 (3m31s ago)   3m48s   192.168.200.1   infra-1   <none>           <none>
```

> Virtual Machine `infra-1` Commands: END

### Launch Kubernetes and OVN-Kubernetes in the Tenant Cluster

> Virtual Machine `tenant-1` Commands: BEGIN

Log into `tenant-1` VM and run the following command:
The [launch-k8s-ovnk.sh](../scripts/launch-k8s-ovnk.sh) script will launch Kubernetes
on the controller node, then start the OVN-Kubernetes CNI.
Run the script in the Infra VM.

```console
cd ${WORKING_DIR}/dpu-software/
sudo ./scripts/launch-k8s-ovnk.sh
```

**Summary:**
As a summary, the script above performs the following:

* Run `kubeadm init` to start Kubernetes.
* Save the `kubeadm join` command to a local file that will be distributed to worker nodes.
* Create `br-int` in OvS.
* Launch the CNI, OVN-Kubernetes. 

Verify Kubernetes and OVN-Kubernetes is running:

```console
$ kubectl get nodes -o wide
NAME      STATUS   ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION           CONTAINER-RUNTIME
infra-1   Ready    control-plane   136m   v1.27.2   192.168.200.1   <none>        Fedora Linux 37 (Thirty Seven)   6.1.13-200.fc37.x86_64   cri-o://1.24.1

$ kubectl get pods -A -o wide
NAMESPACE        NAME                              READY   STATUS    RESTARTS       AGE    IP              NODE      NOMINATED NODE   READINESS GATES
kube-system      coredns-5d78c9869d-5fbjs          1/1     Running   0              136m   172.16.0.4      infra-1   <none>           <none>
kube-system      coredns-5d78c9869d-6gmlr          1/1     Running   0              136m   172.16.0.3      infra-1   <none>           <none>
kube-system      etcd-infra-1                      1/1     Running   13             136m   192.168.200.1   infra-1   <none>           <none>
kube-system      kube-apiserver-infra-1            1/1     Running   12             136m   192.168.200.1   infra-1   <none>           <none>
kube-system      kube-controller-manager-infra-1   1/1     Running   12             136m   192.168.200.1   infra-1   <none>           <none>
kube-system      kube-scheduler-infra-1            1/1     Running   13             136m   192.168.200.1   infra-1   <none>           <none>
ovn-kubernetes   ovnkube-db-788d8bfb85-nm9qk       2/2     Running   0              136m   192.168.200.1   infra-1   <none>           <none>
ovn-kubernetes   ovnkube-master-666b87fd45-x8zn2   2/2     Running   0              134m   192.168.200.1   infra-1   <none>           <none>
ovn-kubernetes   ovnkube-node-b4wt8                3/3     Running   1 (133m ago)   133m   192.168.200.1   infra-1   <none>           <none>

```

> Virtual Machine `infra-1` Commands: END

### Uninstall Kubernetes or OVN-Kubernetes

> Virtual Machine `infra-1` or `tenant-1` Commands: BEGIN

If an error occurred and Kubernetes needs to be uninstalled (Only if needed).
This will also uninstall OVN-Kubernetes:

```console
sudo kubeadm reset
```

If an error occurred and only OVN-Kubernetes needs to be uninstalled (Only if needed):

```console
kubectl delete -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-node.yaml
kubectl delete -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-master.yaml
kubectl delete -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-db.yaml
kubectl delete -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovn-setup.yaml
```

> Virtual Machine `infra-1` or `tenant-1` Commands: BEGIN

