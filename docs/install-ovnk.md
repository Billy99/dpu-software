# OVN-Kubernetes Installation

OVN-Kubernetes needs to be installed on all the VMs except the
Gateway Node and OvS needs to be installed on all the VMs except the
Gateway Node and servers hosting the DPUs (`tenant-2` and `tenant-3`).
So `infra-1` will be cloned before installing OvS.
OvS will be install in the `infra-1` VM, then later, that VM will be
cloned to other VMs.

OVN-Kubernetes runs in containers in Kubernetes.
There will also be some churn in OVN-Kubernetes to support DPUs and test
different OPI APIs.
So OVN-Kubernetes will be downloaded to the Remote Server where container
images will be built and then pushed to the registry on the Gateway Node
as additional changes are made.

![OVN-Kubernetes Dataplane](images/OVNK_Dataplane.png)

## Create Servers Hosting DPUs Before Installing OvS

> Remote Server Commands: BEGIN

The servers hosting the DPUs (`tenant-2` and `tenant-3`) do not need OvS
installed, so the following script will shutdown `infra-1`, clone it, and
then restart it.
Close any open session to `infra-1` then run the script.

```console
cd ~/src/dpu-software/
sudo ./scripts/create-dpu-host-vms.sh
```

**Summary:**
As a summary, the script above performs the following:

* Shutdown the base VM. Defaults to `infra-1`, but can be overwritten with `BASE_VM`.
* Wait for VM to complete shutdown.
* Clone base VM to sever hosting DPU VMs. Defaults to `tenant-2` and `tenant-3`, but
  list taken from `TENANT_DPU_HOST_LIST` in `./scripts/variables.sh`.
* Restart base VM.

> Remote Server Commands: END

## OvS

### Install OvS

> Virtual Machine `infra-1` Commands: BEGIN

Instructions taken from:
* https://docs.openvswitch.org/en/latest/intro/install/fedora/

OVN-Kubernetes doesn't specify which version of OvS to use, other than OVN needs features that
are only available in kernel 4.6 and greater.
Running a KIND Cluster on remote server with a recent code base was using `OVS 2.17.5`, so that
is what is used below.

```console
kubectl logs -n ovn-kubernetes ovs-node-z7ghm

================= ovnkube.sh --- version: 3 ================
 ==================== command: ovs-server
 =================== hostname: ovn-worker4
 =================== daemonset version 3
 =================== Image built from ovn-kubernetes ref: refs/heads/master  commit: a2a2d6d49f478a6f638fd0c154494a432fd0326d
Starting ovsdb-server.
Configuring Open vSwitch system IDs.
Enabling remote OVSDB managers.
Starting ovs-vswitchd.
Enabling remote OVSDB managers.
==> /var/log/openvswitch/ovs-vswitchd.log <==
2023-04-18T15:27:58.226Z|00082|coverage|INFO|dpif_port_add              0.0/sec     0.000/sec        0.0000/sec   total: 1
2023-04-18T15:27:58.226Z|00083|coverage|INFO|cmap_expand                0.0/sec     0.000/sec        0.0000/sec   total: 25
2023-04-18T15:27:58.226Z|00084|coverage|INFO|rev_flow_table             0.0/sec     0.000/sec        0.0000/sec   total: 1
2023-04-18T15:27:58.226Z|00085|coverage|INFO|ofproto_update_port        0.0/sec     0.000/sec        0.0000/sec   total: 16
2023-04-18T15:27:58.226Z|00086|coverage|INFO|ofproto_flush              0.0/sec     0.000/sec        0.0000/sec   total: 1
2023-04-18T15:27:58.226Z|00087|coverage|INFO|bridge_reconfigure         0.0/sec     0.000/sec        0.0000/sec   total: 1
2023-04-18T15:27:58.226Z|00088|coverage|INFO|122 events never hit
2023-04-18T15:27:58.226Z|00089|dpif|WARN|system@ovs-system: failed to query port patch-br-int-to-breth0_ovn-worker4: Invalid argument
2023-04-18T15:27:58.298Z|00090|bridge|INFO|ovs-vswitchd (Open vSwitch) 2.17.5
2023-04-18T15:27:58.391Z|00004|ofproto_dpif_xlate(handler25)|INFO|/proc/sys/net/core/netdev_max_backlog: open failed (No such file or directory)
:
```

The [install-ovs.sh](../scripts/install-ovs.sh) script will build and install OvS.
Run the script in the Infra VM.

```console
cd ~/src/dpu-software/
./scripts/install-ovs.sh
```

> **NOTE:** No `sudo` used on this script.

**Summary:**
As a summary, the script above performs the following:

* Download OvS.
* Install OvS Dependencies.
* Build OvS RPM.
* Install OvS RPM and then start/enable OvS.


Verify OvS is running:

```console
sudo systemctl status openvswitch
● openvswitch.service - Open vSwitch
     Loaded: loaded (/usr/lib/systemd/system/openvswitch.service; enabled; preset: disabled)
     Active: active (exited) since Tue 2023-04-18 15:26:28 EDT; 12min ago
   Main PID: 152394 (code=exited, status=0/SUCCESS)
        CPU: 1ms

Apr 18 15:26:28 infra-1 systemd[1]: Starting openvswitch.service - Open vSwitch...
Apr 18 15:26:28 infra-1 systemd[1]: Finished openvswitch.service - Open vSwitch.


sudo systemctl status ovs-vswitchd
● ovs-vswitchd.service - Open vSwitch Forwarding Unit
     Loaded: loaded (/usr/lib/systemd/system/ovs-vswitchd.service; static)
     Active: active (running) since Tue 2023-04-18 15:26:28 EDT; 13min ago
   Main PID: 152385 (ovs-vswitchd)
      Tasks: 1 (limit: 4665)
     Memory: 3.7M
        CPU: 71ms
     CGroup: /system.slice/ovs-vswitchd.service
             └─152385 ovs-vswitchd unix:/var/run/openvswitch/db.sock -vconsole:emer -vsyslog:err -vfile:info --mlockall --user openvswitch:openvswitch ->

Apr 18 15:26:27 infra-1 systemd[1]: Starting ovs-vswitchd.service - Open vSwitch Forwarding Unit...
Apr 18 15:26:28 infra-1 ovs-ctl[152351]: Starting ovs-vswitchd.
Apr 18 15:26:28 infra-1 ovs-vsctl[152392]: ovs|00001|vsctl|INFO|Called as ovs-vsctl --no-wait add Open_vSwitch . external-ids hostname=infra-1
Apr 18 15:26:28 infra-1 ovs-ctl[152351]: Enabling remote OVSDB managers.
Apr 18 15:26:28 infra-1 systemd[1]: Started ovs-vswitchd.service - Open vSwitch Forwarding Unit.


sudo systemctl status ovsdb-server
● ovsdb-server.service - Open vSwitch Database Unit
     Loaded: loaded (/usr/lib/systemd/system/ovsdb-server.service; static)
     Active: active (running) since Tue 2023-04-18 15:26:27 EDT; 13min ago
   Main PID: 152325 (ovsdb-server)
      Tasks: 1 (limit: 4665)
     Memory: 3.3M
        CPU: 247ms
     CGroup: /system.slice/ovsdb-server.service
             └─152325 ovsdb-server /etc/openvswitch/conf.db -vconsole:emer -vsyslog:err -vfile:info --remote=punix:/var/run/openvswitch/db.sock --privat>

Apr 18 15:26:27 infra-1 chown[152274]: /usr/bin/chown: cannot access '/run/openvswitch': No such file or directory
Apr 18 15:26:27 infra-1 ovs-ctl[152280]: /etc/openvswitch/conf.db does not exist ... (warning).
Apr 18 15:26:27 infra-1 ovs-ctl[152280]: Creating empty database /etc/openvswitch/conf.db.
Apr 18 15:26:27 infra-1 ovs-ctl[152280]: Starting ovsdb-server.
Apr 18 15:26:27 infra-1 ovs-vsctl[152326]: ovs|00001|vsctl|INFO|Called as ovs-vsctl --no-wait -- init -- set Open_vSwitch . db-version=8.3.0
Apr 18 15:26:27 infra-1 ovs-vsctl[152337]: ovs|00001|vsctl|INFO|Called as ovs-vsctl --no-wait set Open_vSwitch . ovs-version=2.17.5 "external-ids:system>
Apr 18 15:26:27 infra-1 ovs-ctl[152280]: Configuring Open vSwitch system IDs.
Apr 18 15:26:27 infra-1 ovs-ctl[152280]: Enabling remote OVSDB managers.
Apr 18 15:26:27 infra-1 systemd[1]: Started ovsdb-server.service - Open vSwitch Database Unit.
Apr 18 15:26:27 infra-1 ovs-vsctl[152343]: ovs|00001|vsctl|INFO|Called as ovs-vsctl --no-wait add Open_vSwitch . external-ids hostname=infra-1


sudo ovs-vsctl show
a0317764-2bb2-47fb-9a68-e268460335dc
    ovs_version: "2.17.5"
```

> Virtual Machine `infra-1` Commands: END

### Configure OVN-Kubernetes Networking

> Virtual Machine `infra-1` Commands: BEGIN

To configure OvS to be used with OVN-Kubernetes, the following guide was used:
* https://github.com/ovn-org/ovn-kubernetes/blob/master/docs/INSTALL.KUBEADM.md#configure-networking

The [config-ovnk-network.sh](../scripts/config-ovnk-network.sh) script will configure
OvS for the VM as needed.
Run the script in the `infra-1` VM, then reboot the VM.
The [config-ovnk-network.sh](../scripts/config-ovnk-network.sh) script uses the VM
hostname to determine the `NODE_NUM`, which is used to IP Addresses.

```console
cd ~/src/dpu-software/
sudo ./scripts/config-ovnk-network.sh

sudo reboot
```

**Summary:**
As a summary, the script above performs the following:

* Set the IP address on `br-ext` and configures the routing.
* Configure DNS.

Once the Infra VM is back, make sure the system is configured properly:

```console
$ ip route
default via 192.168.200.254 dev br-ex proto static metric 50 
192.168.122.0/24 dev enp1s0 proto kernel scope link src 192.168.122.193 metric 100 
192.168.200.0/24 dev br-ex proto kernel scope link src 192.168.200.1 metric 50 

$ sudo ovs-vsctl show
7c1b494b-0d35-4e7b-b605-2e2cec31453a
    Bridge br-ex
        Port br-ex
            Interface br-ex
                type: internal
        Port enp7s0
            Interface enp7s0
                type: system
    ovs_version: "2.17.5"

$ sudo nmcli conn
NAME             UUID                                  TYPE           DEVICE 
ovs-if-br-ex     9a690d2e-e92e-4f1c-8842-5bfceaf77295  ovs-interface  br-ex  
enp1s0           d238db6d-f3e2-322d-b6a0-98f0087c2d88  ethernet       enp1s0 
br-ex            c00af4d2-f659-4c1a-b511-f702fb9d3284  ovs-bridge     br-ex  
ovs-if-enp7s0    43e9e29f-5bc3-46e4-aa57-5172a1f5c3f1  ethernet       enp7s0 
ovs-port-br-ex   91b75c65-b962-4c55-b699-2a280c49c1a9  ovs-port       br-ex  
ovs-port-enp7s0  f090b0f7-a541-4833-9f56-374f3284b732  ovs-port       enp7s0 

$ ping -4 -c 1 google.com
PING google.com (142.251.16.100) 56(84) bytes of data.
64 bytes from bl-in-f100.1e100.net (142.251.16.100): icmp_seq=1 ttl=53 time=8.03 ms

--- google.com ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 8.028/8.028/8.028/0.000 ms
```
> Virtual Machine `infra-1` Commands: END

## Download and Build OVN-Kubernetes

> Remote Server Commands: BEGIN

Instructions taken from:
* https://github.com/ovn-org/ovn-kubernetes#building-the-daemonset-container

The [install-ovnk.sh](../scripts/install-ovnk.sh) script will download and build
OVN-Kubernetes.
Run the script in the Remote Server.

```console
cd ~/src/dpu-software/
./scripts/install-ovnk.sh
```

> **NOTE:** No `sudo` used on this script.

**Summary:**
As a summary, the script above performs the following:

* Download OVN-Kubernetes.
* Build OVN-Kubernetes container image.
* Push OVN-Kubernetes container image to HTTP Registry on Gateway.

> Remote Server Commands: END


--------------------------

VF-0 (`tap<X>-vf0-<Z>`) is special in the way OVN-Kubernetes uses it.
On the tenant side, it binds to the host network so that host traffic get pushed through
the DPU.

Create OVN StatefulSet, DaemonSet and Deployment yamls:

```console
export MASTER_IP=192.168.122.70
pushd dist/images/
./daemonset.sh --output-directory=$WORKING_DIR/ovn-kubernetes/dist/yaml \
   --image=$OVN_IMAGE \
   --ovnkube-image=$OVN_IMAGE \
   --net-cidr=10.244.0.0/16 \
   --svc-cidr=10.96.0.0/16 \
   --gateway-mode=shared \
   --gateway-options= \
   --enable-ipsec=false \
   --hybrid-enabled=false \
   --disable-snat-multiple-gws=false \
   --disable-forwarding=false \
   --disable-pkt-mtu-check=false \
   --ovn-empty-lb-events=false \
   --multicast-enabled=false \
   --k8s-apiserver=https://$MASTER_IP:6443 \
   --ovn-master-count=1 \
   --ovn-unprivileged-mode=no \
   --master-loglevel=5 \
   --node-loglevel=5 \
   --dbchecker-loglevel=5 \
   '--ovn-loglevel-northd=-vconsole:info -vfile:info' \
   '--ovn-loglevel-nb=-vconsole:info -vfile:info' \
   '--ovn-loglevel-sb=-vconsole:info -vfile:info' \
   --ovn-loglevel-controller=-vconsole:info \
   --ovnkube-config-duration-enable=true \
   --egress-ip-enable=true \
   --egress-ip-healthcheck-port=9107 \
   --egress-firewall-enable=true \
   --egress-qos-enable=true \
   --v4-join-subnet=100.64.0.0/16 \
   --v6-join-subnet=fd98::/64 \
   --ex-gw-network-interface= \
   --multi-network-enable=false \
   --ovnkube-metrics-scale-enable=false \
   --compact-mode=false
popd
```

> Virtual Machine Commands: END


## Start Kubernetes

```console
sudo kubeadm init --token-ttl 0 --pod-network-cidr=10.244.0.0/16 --cri-socket=unix:///var/run/containerd/containerd.sock
:
addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 192.168.122.70:6443 --token vgp7i3.fn12uc2mztw6gdoj \
	--discovery-token-ca-cert-hash sha256:133a1dce9751e74f63810be1f3238537dd6792926f35214813fcc95098a52726 
```

## Start OVN-Kubernetes

br-int might be added by OVN, but the files for it are not created in `/var/run/openvswitch`.

```console
kubectl logs -n ovn-kubernetes ovnkube-node-2lhq7 -c ovn-controller
:
2023-04-18T21:42:33.907Z|00043|rconn|WARN|unix:/var/run/openvswitch/br-int.mgmt: connection failed (No such file or directory)
2023-04-18T21:42:41.915Z|00044|rconn|WARN|unix:/var/run/openvswitch/br-int.mgmt: connection failed (No such file or directory)
2023-04-18T21:42:41.915Z|00045|rconn|WARN|unix:/var/run/openvswitch/br-int.mgmt: connection failed (No such file or directory)
:
```

The best workaroud is to pre-create br-int before the OVN Kubernetes installation:
```console
sudo ovs-vsctl add-br br-int
```


```console
# Create OVN namespace, service accounts, ovnkube-db headless service, configmap, and policies
kubectl create -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovn-setup.yaml

# Optionally, if you plan to use the Egress IPs or EgressFirewall features, create the corresponding CRDs:
# create egressips.k8s.ovn.org CRD
kubectl create -f $WORKING_DIR/ovn-kubernetes/dist/yaml/k8s.ovn.org_egressips.yaml
# create egressfirewalls.k8s.ovn.org CRD
kubectl create -f $WORKING_DIR/ovn-kubernetes/dist/yaml/k8s.ovn.org_egressfirewalls.yaml

# Run ovnkube-db deployment.
kubectl create -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-db.yaml

# Run ovnkube-master deployment
# To run ovnkube-master deployment with both cluster manager and network controller manager as one container)
kubectl create -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-master.yaml

# or to run ovnkube-master deployment with cluster manager and network controller manager as independent containers.
#kubectl create -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-cm-ncm.yaml

# Run ovnkube daemonset for nodes
kubectl create -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-node.yaml

kubectl delete daemonsets -n kube-system kube-proxy
```


In order to uninstall OVN kubernetes:
```console
kubectl delete -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-node.yaml
kubectl delete -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-master.yaml
kubectl delete -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovnkube-db.yaml
kubectl delete -f $WORKING_DIR/ovn-kubernetes/dist/yaml/ovn-setup.yaml
```
