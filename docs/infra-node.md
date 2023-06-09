# Infra Node

## Clone the Golden VM

> Remote Server Commands: BEGIN

Make sure the `golden-fedora-37` VM has been stopped.
Clone the `golden-fedora-37` to a new VM named `infra-1`.

```console
sudo virt-clone --connect qemu:///system --original golden-fedora-37 --name infra-1 --file /var/lib/libvirt/images/infra-1.qcow2
```

Start the VM:

```console
sudo virsh start infra-1
```

Determine the IP Address of the VM:

```console
$ sudo journalctl -f
:
May 31 10:07:16 nfvsdn-21-oot.lab.eng.rdu2.redhat.com dnsmasq-dhcp[44355]: DHCPREQUEST(virbr0) 192.168.122.47 52:54:00:6a:af:43
May 31 10:07:16 nfvsdn-21-oot.lab.eng.rdu2.redhat.com dnsmasq-dhcp[44355]: DHCPACK(virbr0) 192.168.122.47 52:54:00:6a:af:43 golden-fedora-37
:
```

For documentation, save the IP in an environment variable:

```console
export INFRA_1_IP=192.168.122.47
```

Log into the Infra-1 VM:

```console
$ ssh ${USER}@${INFRA_1_IP}
```

> Remote Server Commands: END

## OvS

### Install OvS

> Virtual Machine Commands: BEGIN

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
cd ${WORKING_DIR}/dpu-software/
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

> Virtual Machine Commands: END

### Configure OvS Networking

> Virtual Machine Commands: BEGIN

To configure OvS to be used with OVN-Kubernetes, the following guide was used:
* https://github.com/ovn-org/ovn-kubernetes/blob/master/docs/INSTALL.KUBEADM.md#configure-networking

The [infra-setup.sh](../scripts/infra-setup.sh) script will configure the OvS for Infra VM
as needed.
Run the script in the Infra VM, then reboot the VM.
The [infra-setup.sh](../scripts/infra-setup.sh) script requires the node number passed in
as a parameter, so pass a `1` since this is the `infra-1` VM.

```console
cd ${WORKING_DIR}/dpu-software/
sudo ./scripts/infra-setup.sh 1

sudo reboot
```

**Summary:**
As a summary, the script above performs the following:

* Set the hostname.
* Runs `nmcli` commands to create the OvS bridge `br-ext` and attach `enp7s0` to the bridge.
  Also set the IP address on `br-ext` and configures the routing.
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
> Virtual Machine Commands: END

## Install Container Runtime

> Virtual Machine Commands: BEGIN

A container runtime needs to be installed on each node in the cluster so that Pods can run there.

* https://kubernetes.io/docs/setup/production-environment/container-runtimes/

Instructions to install CRI-O and Containerd are below, but other runtimes could be used instead.
CRI-O is being used in the original deployment.

### Install Container Runtime: CRI-O

Installation instructions:

* https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cri-o
* https://github.com/cri-o/cri-o/blob/main/install.md#readme

The [install-crio.sh](../scripts/install-crio.sh) script will install and configure CRI-O
as the Container Runtime.
Run the script in the Infra VM.

```console
cd ${WORKING_DIR}/dpu-software/
sudo ./scripts/install-crio.sh
```

**Summary:**
As a summary, the script above performs the following:

* Use `dnf` to install CRI-O.
* Install the CNI Plugins.
* Mark the registry on Gateway as insecure.
* Removing CRI-O Bridge Conf file.
* Enable and Start CRI-O.

### Install Container Runtime: Containerd

Installation instructions:

* https://kubernetes.io/docs/setup/production-environment/container-runtimes/#containerd
* https://github.com/containerd/containerd/blob/main/docs/getting-started.md

Find release at: https://github.com/containerd/containerd/releases

> **NOTE:** Manually ran through these steps, but haven't retried since the steps were 
  moved into a script.
  Feel free to push updates if issues or errors are encountered.

The [install-containerd.sh](../scripts/install-containerd.sh) script will install and configure
Containerd as the Container Runtime.
Run the script in the Infra VM.

```console
cd ${WORKING_DIR}/dpu-software/
sudo ./scripts/install-containerd.sh
```

**Summary:**
As a summary, the script above performs the following:

* Download and install Containerd.
* Start/Enable Containerd.
* Download and install runc.
* Install the CNI Plugins.
* Configure and restart Containerd.

> Virtual Machine Commands: END

## Install Kubernetes

> Virtual Machine Commands: BEGIN

The [install-kubernetes.sh](../scripts/install-kubernetes.sh) script will install and configure
Kubernetes.
Run the script in the Infra VM.

```console
cd ${WORKING_DIR}/dpu-software/
sudo ./scripts/install-kubernetes.sh
```

**Summary:**
As a summary, the script above performs the following:

* Disable SELinux and Swap
* Manage firewalld. Disable by default, override and open needed ports with
  "DISABLE_FIREWALLD=false". 
* Install required kernel modules.
* Set sysctl params.
* Download and install Kubernetes.
* Start/Enable Kubelet.

Verify it's started (Error expected):

```console
kubectl get nodes
E0602 11:44:48.254857    4033 memcache.go:265] couldn't get current server API group list: Get "http://localhost:8080/api?timeout=32s": dial tcp [::1]:8080: connect: connection refused
:
The connection to the server localhost:8080 was refused - did you specify the right host or port?
```

> Virtual Machine Commands: END

## Download and Build OVN-Kubernetes

> Virtual Machine Commands: BEGIN

Instructions taken from:
* https://github.com/ovn-org/ovn-kubernetes#building-the-daemonset-container

The [install-ovnk.sh](../scripts/install-ovnk.sh) script will install and configure
OVN-Kubernetes.
Run the script in the Infra VM.

```console
cd ${WORKING_DIR}/dpu-software/
./scripts/install-ovnk.sh
```

> **NOTE:** No `sudo` used on this script.

**Summary:**
As a summary, the script above performs the following:

* Download OVN-Kubernetes.
* Build OVN-Kubernetes container image.
* Push OVN-Kubernetes container image to HTTP Registry on Gateway.

> Virtual Machine Commands: END
