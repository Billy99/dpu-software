# Gateway Node

The Gateway Node is a simple gateway which will NAT everything that comes in on
interface `enp7s0` and `enp8s0`.
The notes on setting up the Gateway Node were taken from:

* https://github.com/ovn-org/ovn-kubernetes/blob/master/docs/INSTALL.KUBEADM.md#gateway-setup-gw1

This section assumes that the steps in [Base VM Creation Notes](./create-base-vm.md) have already been
executed. 

## Clone the Golden VM

> Remote Server Commands: BEGIN

Make sure the `golden-fedora-37` VM has been stopped.
Clone the `golden-fedora-37` to a new VM named `gw-1`.

```console
sudo virt-clone --connect qemu:///system --original golden-fedora-37 --name gw-1 --file /var/lib/libvirt/images/gw-1.qcow2
```

Add an additional interface (`enp8s0`) to the Gateway VM leveraging the `tenant` network.
`golden-fedora-37` already has an additional interface (`enp7s0`) leveraging the `infra` .

```console
$ sudo virsh edit gw-1
:
    <interface type='network'>
      <mac address='52:54:00:74:09:8a'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <interface type='network'>
      <mac address='52:54:00:3a:78:fd'/>
      <source network='infra'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </interface>
# ADD ADDITIONAL INTERFACE: BEGIN
    <interface type='network'>
      <source network='tenant'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
    </interface>
# ADD ADDITIONAL INTERFACE: END
:
```

Start the VM:

```console
sudo virsh start gw-1
```

Determine the IP Address of the VM:

```console
$ sudo ./get-vm-ips.sh

#################################
Variables ...
#################################
GATEWAY_LIST         = gw-1
INFRA_CTRL_LIST      = infra-1
INFRA_DPU_LIST       = infra-2 infra-3
TENANT_CTRL_LIST     = tenant-1
TENANT_DPU_HOST_LIST = tenant-2 tenant-3
TENANT_WORKER_LIST   = tenant-4

MAC_ADDR=52:54:00:74:09:8a	IP_ADDR=192.168.122.138  	NODE=gw-1
infra-1 does not exist. Skipping ...
infra-2 does not exist. Skipping ...
infra-3 does not exist. Skipping ...
tenant-1 does not exist. Skipping ...
tenant-2 does not exist. Skipping ...
tenant-3 does not exist. Skipping ...
tenant-4 does not exist. Skipping ...
```

For documentation, save the IP in an environment variable or update `~/.bashrc` is using alias:

```console
export GATEWAY_1_IP=192.168.122.138
```

Log into the Gateway-1 VM:

```console
ssh ${USER}@${GATEWAY_1_IP}
OR
vmg1
```

> Remote Server Commands: END

## Provision the Gateway

> Virtual Machine `gw-1` Commands: BEGIN

The [gateway-setup.sh](../scripts/gateway-setup.sh) script will configure the Gateway VM
as needed.

Run the script in the Gateway VM, then reboot the VM:

```console
sudo ./gateway-setup.sh

sudo reboot
```

**Summary:**
As a summary, the script above performs the following:

* Set the hostname.
* Runs `nmcli` commands to manage the IP Addresses for `enp1s0`, `enp7s0` and `enp8s0`.
* Set IP Table rules to NAT traffic from the blue network (`192.168.200.0/24`) to
  the default red network (`192.168.122.0/24`).
* Set IP Table rules to NAT traffic from the green network (`192.168.100.0/24`) to
  the default red network (`192.168.122.0/24`).
* Sets up an HTTP Registry

> Virtual Machine `gw-1` Commands: END
