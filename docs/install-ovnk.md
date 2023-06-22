# OVN-Kubernetes Installation

OVN-Kubernetes needs to be installed on all the VMs except the
Gateway Node and OvS needs to be installed on all the VMs except the
Gateway Node and servers hosting the DPUs (`tenant-2` and `tenant-3`).
So `tenant-2` and `tenant-3` will be cloned from `infra-1` will be cloned
before installing OvS.
OvS will be install in the `infra-1` VM, then later, that VM will be
cloned to other VMs.

OVN-Kubernetes runs in containers in Kubernetes.
There will also be some churn in OVN-Kubernetes to support DPUs and test
different OPI APIs.
So OVN-Kubernetes will be downloaded to the Remote Server where container
images will be built and then pushed to the registry on the Gateway Node
as additional changes are made.

## Create Servers Hosting DPUs Before Installing OvS

> Remote Server Commands: BEGIN

The servers hosting the DPUs (`tenant-2` and `tenant-3`) do not need OvS
installed, so the following script will shutdown `infra-1`, clone it, and
then restart it.
Close any open session to `infra-1` then run the script.

```console
cd ${WORKING_DIR}/dpu-software/
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

> Virtual Machine `infra-1` Commands: END

## Download and Build OVN-Kubernetes

> Remote Server Commands: BEGIN

Instructions taken from:
* https://github.com/ovn-org/ovn-kubernetes#building-the-daemonset-container

The [install-ovnk.sh](../scripts/install-ovnk.sh) script will download and build
OVN-Kubernetes.
Run the script in the Remote Server.


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
* Generate yaml files for deploying OVN-Kubernetes.

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
