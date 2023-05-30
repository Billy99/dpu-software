# Gateway Node

The Gateway Node is a simple gateway which will NAT everything that comes in on
interface `enp7s0`.
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

Start the VM:

```console
sudo virsh start gw-1
```

Determine the IP Address of the VM:

```console
$ sudo journalctl -f
:
May 30 16:36:12 nfvsdn-21-oot.lab.eng.rdu2.redhat.com dnsmasq-dhcp[44355]: DHCPREQUEST(virbr0) 192.168.122.138 52:54:00:74:09:8a
May 30 16:36:12 nfvsdn-21-oot.lab.eng.rdu2.redhat.com dnsmasq-dhcp[44355]: DHCPACK(virbr0) 192.168.122.138 52:54:00:74:09:8a golden-fedora-37
:
```

For documentation, save the IP in an environment variable or update `~/.bashrc` is using alias:

```console
export GATEWAY_1_IP=192.168.122.138
```

From the remote server, copy the [gateway-setup.sh](../scripts/gateway-setup.sh) script
to the Gateway VM:

```console
scp ./scripts/gateway-setup.sh ${USER}@${GATEWAY_1_IP}:/home/$USER/.
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
* Runs `nmcli` commands to manage the IP Addresses for `enp1s0` and `enp7s0`.
* Set IP Table rules to NAT traffic from the blue network (`192.168.200.0/24`) to
  the default red network (`192.168.122.0/24`).
* Sets up an HTTP Registry

> Virtual Machine `gw-1` Commands: END
