# Kubernetes Installation

Kubernetes and a Container Runtime need to be installed on all the VMs
except the Gateway Node.
These set of commands are executed in the `infra-1` VM, then later, that
VM will be cloned to other VMs.

## Create `infra-1` VM

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

For documentation, save the IP in an environment variable or update `~/.bashrc` is using alias:

```console
export INFRA_1_IP=192.168.122.47
```

Log into the Infra-1 VM:

```console
ssh ${USER}@${INFRA_1_IP}
OR
vmi1
```

> Remote Server Commands: END

## Install Container Runtime

A container runtime needs to be installed on each node in the cluster so that
Pods can run there.

* https://kubernetes.io/docs/setup/production-environment/container-runtimes/

Instructions to install CRI-O and Containerd are below, but other runtimes could
be used instead.
CRI-O is being used in the original deployment.

### Install Container Runtime: CRI-O

> Virtual Machine `infra-1` Commands: BEGIN

Installation instructions:

* https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cri-o
* https://github.com/cri-o/cri-o/blob/main/install.md#readme

The [install-crio.sh](../scripts/install-crio.sh) script will install and configure CRI-O
as the Container Runtime.
Run the script in the Infra VM.

```console
cd ~/src/dpu-software/
sudo ./scripts/install-crio.sh
```

**Summary:**
As a summary, the script above performs the following:

* Use `dnf` to install CRI-O.
* Install the CNI Plugins.
* Mark the registry on Gateway as insecure.
* Removing CRI-O Bridge Conf file.
* Enable and Start CRI-O.

> Virtual Machine `infra-1` Commands: END

### Install Container Runtime: Containerd

> Virtual Machine `infra-1` Commands: BEGIN

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
cd ~/src/dpu-software/
sudo ./scripts/install-containerd.sh
```

**Summary:**
As a summary, the script above performs the following:

* Download and install Containerd.
* Start/Enable Containerd.
* Download and install runc.
* Install the CNI Plugins.
* Configure and restart Containerd.

> Virtual Machine `infra-1` Commands: END

## Install Kubernetes

> Virtual Machine `infra-1` Commands: BEGIN

The [install-kubernetes.sh](../scripts/install-kubernetes.sh) script will install and
configure Kubernetes.
Run the script in the Infra VM.

```console
cd ~/src/dpu-software/
sudo ./scripts/install-kubernetes.sh
```

> **NOTE:** Since `infra-1` was cloned from `golden-fedora-37`, the hostname is still
  set to `golden-fedora-37`.
  This script updates the hostname.
  It defaults to `infra-1`, but can be overridden by passing in a different NODE_NAME
  (i.e. `sudo NODE_NAME=tenant-2 ./scripts/install-kubernetes.sh`).

**Summary:**
As a summary, the script above performs the following:

* Set hostname.
* Disable SELinux and Swap.
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

> Virtual Machine `infra-1` Commands: END
