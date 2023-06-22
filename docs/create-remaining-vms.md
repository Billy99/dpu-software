# Create Remaining VMs

## Create Remaining VMs

> Remote Server Commands: BEGIN

Clone `infra-1` VM to the remaining VMs.
The following script will shutdown `infra-1`, clone it for all remaining VMs, and then restart it.
Close any open session to `infra-1` then run the script.

```console
cd ${WORKING_DIR}/dpu-software/
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

## Modify XML for Additional VMs

### Add VFs to VMs

> Remote Server Commands: BEGIN

Edit the VM XML to add additional interfaces.
These interfaces will be backed by the TAP interfaces that are created using the
[deployment.sh](../scripts/deployment.sh) script in a future step.
Below, 20 interfaces have been added (`tap2-vf0-i` to `tap2-vf19-i`).
More interfaces can be added below, just make sure the same number are added to each of
node VMs (`infra-2`, `infra-3`, `tenant-2` and `tenant-3`), and the `NUM_VF` variable is
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
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x6'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf6-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x7'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf7-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf8-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf9-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf10-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf11-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf12-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x6'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf13-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x7'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf14-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf15-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf16-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf17-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf18-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf19-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x6'/>
    </interface>
# ADD TAP INTERFACES: END
:
```

Repeat the step above for `infra-3`, editing the VM XML to add additional interfaces.
Below, 20 interfaces have been added (`tap3-vf0-i` to `tap3-vf19-i`).
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
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x6'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf6-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x7'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf7-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf8-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf9-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf10-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf11-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf12-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x6'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf13-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x7'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf14-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf15-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf16-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf17-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf18-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf19-i'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x6'/>
    </interface>
# ADD TAP INTERFACES: END
:
```

Repeat the step above for `tenant-2`, editing the VM XML to add additional interfaces.
Below, 20 interfaces have been added (`tap2-vf0-t` to `tap2-vf19-t`).
Note the name changed back to `tap2-*` and also changed from `tap2-*-i` to `tap2-*-t`.
For `tenant-2`, also remove the second primary interface

```console
sudo virsh edit tenant-2
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
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x6'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf6-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x7'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf7-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf8-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf9-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf10-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf11-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf12-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x6'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf13-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x7'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf14-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf15-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf16-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf17-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf18-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap2-vf19-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x6'/>
    </interface>
# ADD TAP INTERFACES: END
:
```

Finally. repeat the step above for `tenant-3`, editing the VM XML to add additional
interfaces.
Below, 20 interfaces have been added (`tap3-vf0-t` to `tap3-vf19-t`).
Note the name changed from `tap2-*-t` to `tap3-*-t`.
For `tenant-3`, also remove the second primary interface

```console
sudo virsh edit tenant-3
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
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x6'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf6-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x02' slot='0x00' function='0x7'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf7-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf8-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf9-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf10-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf11-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf12-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x6'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf13-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x03' slot='0x00' function='0x7'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf14-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x1'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf15-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x2'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf16-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x3'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf17-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x4'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf18-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x5'/>
    </interface>
    <interface type='ethernet'>
      <target dev='tap3-vf19-t'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x04' slot='0x00' function='0x6'/>
    </interface>
# ADD TAP INTERFACES: END
:
```

> Remote Server Commands: BEGIN

### Move Tenant VMs to Tenant Network

> Remote Server Commands: BEGIN

Edit the VM XML on the remaining Tenant VMs (`tenant-1` and `tenant-4`) to move the second
interface to the Tenant Network.
For the other Tenant VMs (`tenant-2` and `tenant-3`), then second interface was removed and
replaced with TAP interfaces.

Update `tenant-1` XML to move the second interface to the Tenant Network:

```console
sudo virsh edit tenant-1`
:
    <interface type='network'>
      <mac address='52:54:00:fd:02:0b'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <interface type='network'>
      <mac address='52:54:00:6f:36:01'/>
-      <source network='infra'/>
+      <source network='tenant'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </interface>
:
```

Repeat the step above for `tenant-4`, moving the second interface to the Tenant Network:

```console
sudo virsh edit tenant-1`
:
    <interface type='network'>
      <mac address='52:54:00:3a:23:cd'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
    <interface type='network'>
      <mac address='52:54:00:a7:0a:34'/>
-      <source network='infra'/>
+      <source network='tenant'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </interface>
:
```
> Remote Server Commands: END

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

## Collect VM IP Addresses

> Remote Server Commands: BEGIN

To get the IP Address of each VM, run the following script:

```console
sudo ./get-vm-ips.sh

#################################
Variables ...
#################################
GATEWAY_LIST         = gw-1
INFRA_CTRL_LIST      = infra-1
INFRA_DPU_LIST       = infra-2 infra-3
TENANT_CTRL_LIST     = tenant-1
TENANT_DPU_HOST_LIST = tenant-2 tenant-3
TENANT_WORKER_LIST   = tenant-4

MAC_ADDR=52:54:00:74:09:8a  IP_ADDR=192.168.122.138   NODE=gw-1
MAC_ADDR=52:54:00:7a:c4:25  IP_ADDR=192.168.122.194   NODE=infra-1
MAC_ADDR=52:54:00:61:be:8b  IP_ADDR=192.168.122.193   NODE=infra-2
MAC_ADDR=52:54:00:48:de:ae  IP_ADDR=192.168.122.52    NODE=infra-3
MAC_ADDR=52:54:00:fd:02:0b  IP_ADDR=192.168.122.181   NODE=tenant-1
MAC_ADDR=52:54:00:44:96:cc  IP_ADDR=192.168.122.39    NODE=tenant-2
MAC_ADDR=52:54:00:9b:63:9e  IP_ADDR=192.168.122.62    NODE=tenant-3
MAC_ADDR=52:54:00:3a:23:cd  IP_ADDR=192.168.122.185   NODE=tenant-4
```

If you want to add the alias to the `~/.bashrc` file, add `bashrc` when calling the script,
then paste the output into the file and reload it:

```console
sudo ./get-vm-ips.sh bashrc

#################################
Variables ...
#################################
GATEWAY_LIST         = gw-1
INFRA_CTRL_LIST      = infra-1
INFRA_DPU_LIST       = infra-2 infra-3
TENANT_CTRL_LIST     = tenant-1
TENANT_DPU_HOST_LIST = tenant-2 tenant-3
TENANT_WORKER_LIST   = tenant-4

alias vmg1='svm 138'
alias vmi1='svm 194'
alias vmi2='svm 193'
alias vmi3='svm 52'
alias vmt1='svm 181'
alias vmt2='svm 39'
alias vmt3='svm 62'
alias vmt4='svm 185'
```

> Remote Server Commands: END
