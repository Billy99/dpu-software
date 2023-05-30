# Create Remaining VMs

## Create Remaining VMs

> Remote Server Commands: BEGIN

Clone `infra-1` VM to the remaining VMs.
The following script will shutdown `infra-1`, clone it for all remaining VMs, and then restart it.
Close any open session to `infra-1` then run the script.

```console
cd ~/src/dpu-software/
sudo ./scripts/create-all-vms.sh
```

**Summary:**
As a summary, the script above performs the following:

* Shutdown the base VM. Defaults to `infra-1`, but can be overwritten with `BASE_VM`.
* Wait for VM to complete shutdown.
* Loop through all the lists of VMs in [variables.sh](../scripts/variables.sh).
  If the VM already exists, skip it, otherwise clone base VM to new node.
* Restart base VM.

Base on instructions so far and default values, the following set of VMs will be created:

* `infra-2`
* `infra-3`
* `tenant-1`
* `tenant-4`

> Remote Server Commands: END

## Add VFs to VMs

> Remote Server Commands: BEGIN

Edit the VM XML to add additional interfaces.
These interfaces will be backed by the TAP interfaces that are created using the
[deployment.sh](../scripts/deployment.sh) script in a future step.
Below, 20 interfaces have been added (`tap2-vf0-i` to `tap2-vf9-i`).
More interfaces can be added below, just make sure the same number are added to each of
node VMs (`infra-2`, `infra-3`, `tenant-2` and `tenant-3`), and the `END_VF` variable is
updated in [variables.sh](../scripts/varaibles.sh) script.

Update `infra-2` XML to add additional TAP interfaces:

```console
sudo virsh edit infra-2
:
    <interface type='network'>
      <mac address='52:54:00:61:be:8b'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <interface type='network'>
      <mac address='52:54:00:d1:13:86'/>
      <source network='infra'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </interface>
# ADD TAP INTERFACES: BEGIN
    <interface type='ethernet'>
      <target dev='tap2-vf0-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf1-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf2-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf3-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf4-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf5-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf6-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf7-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf8-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf9-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x5'/>
    </interface>
# ADD TAP INTERFACES: END
:
```

Repeat the step above for `infra-3`, editing the VM XML to add additional interfaces.
Below, 10 interfaces have been added (`tap3-vf0-i` to `tap3-vf9-i`).
Note the name changed from `tap2-*-i` to `tap3-*-i`.


```console
sudo virsh edit infra-3
:
    <interface type='network'>
      <mac address='52:54:00:48:de:ae'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <interface type='network'>
      <mac address='52:54:00:fd:ab:ba'/>
      <source network='infra'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </interface>
# ADD TAP INTERFACES: BEGIN
    <interface type='ethernet'>
      <target dev='tap3-vf0-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf1-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf2-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf3-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf4-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf5-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf6-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf7-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf8-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf9-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x5'/>
    </interface>
# ADD TAP INTERFACES: END
:
```

Repeat the step above for `tenant-2`, editing the VM XML to add additional interfaces.
Below, 10 interfaces have been added (`tap2-vf0-t` to `tap2-vf9-t`).
Note the name changed back to `tap2-*` and also changed from `tap2-*-i` to `tap2-*-t`.
For `tenant-2`, also remove the second primary interface

```console
sudo virsh edit tenant-2`
:
    <interface type='network'>
      <mac address='52:54:00:48:de:ae'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
# REMOVE SECOND INTERFACE: BEGIN
-    <interface type='network'>
-      <mac address='52:54:00:fd:ab:ba'/>
-      <source network='infra'/>
-      <model type='virtio'/>
-      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
-    </interface>
# REMOVE SECOND INTERFACE: END
# ADD TAP INTERFACES: BEGIN
    <interface type='ethernet'>
      <target dev='tap2-vf0-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf1-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf2-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf3-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf4-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf5-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf6-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf7-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf8-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf9-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x5'/>
    </interface>
# ADD TAP INTERFACES: END
:
```

Finally. repeat the step above for `tenant-3`, editing the VM XML to add additional interfaces.
Below, 10 interfaces have been added (`tap3-vf0-t` to `tap3-vf9-t`).
Note the name changed from `tap2-*-t` to `tap3-*-t`.
For `tenant-3`, also remove the second primary interface

```console
sudo virsh edit tenant-2`
:
    <interface type='network'>
      <mac address='52:54:00:48:de:ae'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
# REMOVE SECOND INTERFACE: BEGIN
-    <interface type='network'>
-      <mac address='52:54:00:fd:ab:ba'/>
-      <source network='infra'/>
-      <model type='virtio'/>
-      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
-    </interface>
# REMOVE SECOND INTERFACE: END
# ADD TAP INTERFACES: BEGIN
    <interface type='ethernet'>
      <target dev='tap3-vf0-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf1-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf2-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf3-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf4-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf5-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf6-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf7-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf8-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf9-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x5'/>
    </interface>
# ADD TAP INTERFACES: END
:
```

> Remote Server Commands: BEGIN

## Start All the VMs

> Remote Server Commands: BEGIN

Start all the VMs using the [deployment.sh](../scripts/deployment.sh) script.
This script will create a set of TAP interfaces for DPU nodes (`infra-2`, `infra-3`,
`tenant-2` and `tenant-3`), and a bridge for each TAP pair, tying the `infra-2` to
`tenant-2` and `infra-3` to `tenant-3` (see image on [README.md](../README.md) page):

* Bridge `br2-vf0` and taps `tap2-vf0-i` and `tap2-vf0-t`
* Bridge `br2-vf1` and taps `tap2-vf1-i` and `tap2-vf1-t`
* :
* Bridge `br3-vf0` and taps `tap3-vf8-i` and `tap3-vf8-t`
* Bridge `br3-vf1` and taps `tap3-vf9-i` and `tap3-vf9-t`

```console
sudo ./scripts/deployment.sh start

#################################
Create interfaces
#################################
Create Bridge br2-vf0 and taps tap2-vf0-i and tap2-vf0-t
Create Bridge br2-vf1 and taps tap2-vf1-i and tap2-vf1-t
Create Bridge br2-vf2 and taps tap2-vf2-i and tap2-vf2-t
Create Bridge br2-vf3 and taps tap2-vf3-i and tap2-vf3-t
Create Bridge br2-vf4 and taps tap2-vf4-i and tap2-vf4-t
Create Bridge br2-vf5 and taps tap2-vf5-i and tap2-vf5-t
Create Bridge br2-vf6 and taps tap2-vf6-i and tap2-vf6-t
Create Bridge br2-vf7 and taps tap2-vf7-i and tap2-vf7-t
Create Bridge br2-vf8 and taps tap2-vf8-i and tap2-vf8-t
Create Bridge br2-vf9 and taps tap2-vf9-i and tap2-vf9-t
Create Bridge br3-vf0 and taps tap3-vf0-i and tap3-vf0-t
Create Bridge br3-vf1 and taps tap3-vf1-i and tap3-vf1-t
Create Bridge br3-vf2 and taps tap3-vf2-i and tap3-vf2-t
Create Bridge br3-vf3 and taps tap3-vf3-i and tap3-vf3-t
Create Bridge br3-vf4 and taps tap3-vf4-i and tap3-vf4-t
Create Bridge br3-vf5 and taps tap3-vf5-i and tap3-vf5-t
Create Bridge br3-vf6 and taps tap3-vf6-i and tap3-vf6-t
Create Bridge br3-vf7 and taps tap3-vf7-i and tap3-vf7-t
Create Bridge br3-vf8 and taps tap3-vf8-i and tap3-vf8-t
Create Bridge br3-vf9 and taps tap3-vf9-i and tap3-vf9-t

#################################
Starting VMs
#################################
Domain 'gw-1' started

Domain 'infra-1' started

Domain 'infra-2' started

Domain 'infra-3' started

Domain 'tenant-1' started

Domain 'tenant-2' started

Domain 'tenant-3' started

Domain 'tenant-4' started
```

> Remote Server Commands: END


# Old Notes: To Be Removed

### Start the `infra-2` VM

> Remote Server Commands: BEGIN

Start `infra-2` VM.

```console
sudo virsh start infra-2
Domain 'infra-2' started
```

Determine the IP Address of the VM (it will still have the hostname of `infra-1`:

```console
$ sudo journalctl -f
:
Jun 06 08:43:15 nfvsdn-21-oot.lab.eng.rdu2.redhat.com dnsmasq-dhcp[44355]: DHCPREQUEST(virbr0) 192.168.122.193 52:54:00:61:be:8b
Jun 06 08:43:15 nfvsdn-21-oot.lab.eng.rdu2.redhat.com dnsmasq-dhcp[44355]: DHCPACK(virbr0) 192.168.122.193 52:54:00:61:be:8b infra-1
:
```

For documentation, save the IP in an environment variable:

```console
export INFRA_2_IP=192.168.122.193
```

Log into the Infra-2 VM:

```console
$ ssh ${USER}@${INFRA_2_IP}
```

> Remote Server Commands: BEGIN

### Remap the `infra-2` VM

> Virtual Machine `infra-1` Commands: BEGIN

All the cloned VMs still have the hostname and IP Configuration for the `infra-1` VM.
The [remap-vm.sh](../scripts/remap-vm.sh) script will remap the VM to `infra-2`.
Run the script in the `infra-2` VM.
The script takes two parameters.
The first parameter indicates if it is a infra or tenant VM, and can be one of:
`[i|infra|t|tenant]`
The second parameter is the node number.

```console
cd ~/src/dpu-software/
sudo ./scripts/remap-vm.sh i 2
```

**Summary:**
As a summary, the script above performs the following:

* Set the Hostname
* Change the IP Address for bridge `br-ex` to a match it's network (either
  `192.168.100.<NodeNumber>/24` for tenant or `192.168.200.<NodeNumber>/24` for infra).
* Change the Gateway IP Address (either `192.168.100.254/24` for tenant or
  `192.168.200.254/24` for infra).

Verify changes were applied (prompt won't change until a logout/login:

```console
sudo nmcli conn show id ovs-if-br-ex
connection.id:                          ovs-if-br-ex
:
ipv4.addresses:                         192.168.200.2/24
ipv4.gateway:                           192.168.200.254
:
IP4.ADDRESS[1]:                         192.168.200.2/24
IP4.GATEWAY:                            192.168.200.254
IP4.ROUTE[1]:                           dst = 192.168.200.0/24, nh = 0.0.0.0, mt = 50
IP4.ROUTE[2]:                           dst = 0.0.0.0/0, nh = 192.168.200.254, mt = 50
:

ip a
:
6: br-ex: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN group default qlen 1000
    link/ether c6:ee:b3:cc:73:4a brd ff:ff:ff:ff:ff:ff
    inet 192.168.200.2/24 brd 192.168.200.255 scope global noprefixroute br-ex
       valid_lft forever preferred_lft forever
    inet6 fe80::c45c:b767:a2b9:c67/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
```

> Virtual Machine `infra-1` Commands: END

### Start and Remap the Remaining VMs

Repeat the previous two steps for the remaining VMs.

> Virtual Machine Commands: BEGIN


`infra-3`

```console
cd ~/src/dpu-software/
sudo ./scripts/remap-vm.sh i 3
```

`tenant-1`

```console
cd ~/src/dpu-software/
sudo ./scripts/remap-vm.sh t 1
```

`tenant-2`

```console
cd ~/src/dpu-software/
sudo ./scripts/remap-vm.sh t 2
```

`tenant-3`

```console
cd ~/src/dpu-software/
sudo ./scripts/remap-vm.sh t 3
```

`tenant-4`

```console
cd ~/src/dpu-software/
sudo ./scripts/remap-vm.sh t 4
```

> Virtual Machine Commands: END

