# Base VM Creation Notes

The are multiple ways and technologies that can be leveraged to create a Virtual Machine.
For this Software DPU Deployment, QEMU/libvirt VMs were created running Fedora.

This example will create and provision a base VM named `golden-fedora-37` with all the
packages needed.
Then the base VM will be stopped and cloned several times to the set of nodes needed
for the deployment.

## Remote Server Requirements

### Install Dependencies

> Remote Server Commands: BEGIN

The remote server is running Fedora 37.
The following packages were installed on the remote server.
Not all of these may be needed to create and launch a VM (like some of the Development Tools),
but they are all listed in case a dependency was installed that was needed. 

```console
sudo dnf install -y pciutils tcpdump wget git lshw
sudo dnf install -y kernel-devel
sudo dnf groupinstall -y 'Development Tools'
sudo dnf groupinstall -y 'C Development Tools and Libraries'
sudo dnf install -y golang
sudo dnf install -y virt-manager libvirt virt-install
sudo dnf install -y podman python3-pip
```

> Remote Server Commands: END

### Install Scripts

> Remote Server Commands: BEGIN

Download this repository for a local copy of the scripts:

```console
mkdir -p ~/src/; cd ~/src/
git clone https://github.com/Billy99/dpu-software.git
cd ~/src/dpu-software/
```

If there are any non-default settings to use, update
[variables.sh](scripts/variables.sh) now with those changes.

> Remote Server Commands: END

### libvirt Image Directories

> Remote Server Commands: BEGIN

The `/` partition usually has less allocated memory, so all the libvirt images were moved
to the `/home` partition with more memory.
This is optional and symlinks to original locations are created.

```console
# Create new directory.
sudo mkdir -p /home/images/isos/

# If libvirt has already been run, clean up existing directories.
# WARNING: Make sure all VMs are stopped before running these commands.
sudo mv /var/lib/libvirt/images/* /home/images/.
sudo mv /var/lib/libvirt/boot/* /home/images/isos/.
sudo rm -rf /var/lib/libvirt/images/
sudo rm -rf /var/lib/libvirt/boot/

# Symlink libvirt to the /home directory.
sudo ln -s /home/images /var/lib/libvirt/images
sudo ln -s /home/images/isos /var/lib/libvirt/boot
```

Start libvirt if not already started:

```console
sudo systemctl start libvirtd
```

> Remote Server Commands: END

## Local Host Requirements

> Local Host Commands: BEGIN

To install TigerVNC on the local host.
In my installation, I left the password blank, but use a password if desired.

```console
sudo dnf install -y tigervnc-server

vncpasswd
 Password:
 Verify:
 Would you like to enter a view-only password (y/n)? n
 A view-only password is not used
  
sudo cp /lib/systemd/system/vncserver@.service  /etc/systemd/system/vncserver@.service
```

To allow VNC to a VM on server, open firewall ports on the local host: 

```console
sudo firewall-cmd --permanent --add-port=5900-5910/tcp
sudo firewall-cmd --reload
```

> Local Host Commands: END

## Create VM

> Remote Server Commands: BEGIN

Run the following commands on the Remote Server.

Download ISO:

```console
wget https://download.fedoraproject.org/pub/fedora/linux/releases/37/Server/x86_64/iso/Fedora-Server-dvd-x86_64-37-1.7.iso
sudo mv Fedora-Server-dvd-x86_64-37-1.7.iso /var/lib/libvirt/boot/.
```

Create VM:

```console
sudo qemu-img create -f qcow2 /var/lib/libvirt/images/golden-fedora-37.qcow2 80G
sudo virt-install \
  --virt-type=kvm \
  --name golden-fedora-37 \
  --vcpus=4 \
  --ram 4096 \
  --os-variant=fedora37 \
  --hvm \
  --cdrom=/var/lib/libvirt/boot/Fedora-Server-dvd-x86_64-37-1.7.iso \
  --network network=default,model=virtio \
  --graphics vnc \
  --disk path=/var/lib/libvirt/images/golden-fedora-37.qcow2,format=qcow2,bus=virtio
```

Determine which port VNC is using (`5900` in this example):

```console
sudo virsh dumpxml golden-fedora-37 | grep vnc
<graphics type='vnc' port='5900' autoport='yes' listen='127.0.0.1'>
```

> Remote Server Commands: END


> Local Host Commands: BEGIN

From the Local Host, `ssh` to the Remote Server binding the port being used by VNC on the
Local Host to the same port on the Remote Server. This will allow VNC running locally to
manage the install on the Remote Server.

```console
ssh <$USER>@<$IP> -L 5900:127.0.0.1:5900
```

Run TigerVNC Viewer on Local Host and in the GUI:
```
  VNC server: localhost:5900
```

Once VNC is up and running, complete the OS Installation.
Install minimum installation and the required packages will be installed below.
For simplicity, create the same user in the VM that is used to log into the
Remote Server.
Once complete, push reboot.

> Local Host Commands: END

## Virtual Machine Requirements

> Remote Server Commands: BEGIN

From the remote server, mange the VM.

All the Nodes in the deployment will have two interfaces, one for management on the
`192.168.122.0/24` network (`default` network), and one used for the Kubernetes networking
(either `infra` or `tenant`).
First, make sure the VM is created and stop it if needed:

```console
$ sudo virsh list --all
 Id   Name               State
-----------------------------------
 1    golden-fedora-37   running

$ sudo virsh shutdown golden-fedora-37
Domain 'golden-fedora-37' is being shutdown

$ sudo virsh list --all
 Id   Name               State
-----------------------------------
 -    golden-fedora-37   shut off
```

Now create the additional Kubernetes networks:

```console
sudo vi /usr/share/libvirt/networks/infra.xml
<network>
  <name>infra</name>
  <bridge name='virbr2' stp='on' delay='0'/>
  <domain name='infra'/>
</network>

sudo virsh net-create /usr/share/libvirt/networks/infra.xml


sudo vi /usr/share/libvirt/networks/tenant.xml
<network>
  <name>tenant</name>
  <bridge name='virbr3' stp='on' delay='0'/>
  <domain name='tenant'/>
</network>

sudo virsh net-create /usr/share/libvirt/networks/tenant.xml

```

Add a second interface to the VM leveraging the `infra` network just created:

```console
$ sudo virsh edit golden-fedora-37
:
    <interface type='network'>
      <mac address='52:54:00:be:15:e5'/>
      <source network='default'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x01' slot='0x00' function='0x0'/>
    </interface>
# ADD ADDITIONAL INTERFACE: BEGIN
    <interface type='network'>
      <source network='infra'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x07' slot='0x00' function='0x0'/>
    </interface>
# ADD ADDITIONAL INTERFACE: END
:
```

Start the VM:

```console
$ sudo virsh list --all
 Id   Name               State
-----------------------------------
 -    golden-fedora-37   shut off

$ sudo virsh start golden-fedora-37
Domain 'golden-fedora-37' started
```

Log into the base VM named `golden-fedora-37` and run through the following sections.
Determine the IP Address of the VM:

```console
$ sudo journalctl -f
:
Apr 17 11:23:45 nfvsdn-21-oot.lab.eng.rdu2.redhat.com dnsmasq-dhcp[44355]: DHCPREQUEST(virbr0) 192.168.122.142 52:54:00:25:b7:13
Apr 17 11:23:45 nfvsdn-21-oot.lab.eng.rdu2.redhat.com dnsmasq-dhcp[44355]: DHCPACK(virbr0) 192.168.122.142 52:54:00:25:b7:13 golden-fedora-37
:
```

For documentation, save the IP in an environment variable:

```console
export GOLDEN_IP=192.168.122.142
```


Generate and ssh key and copy the ssh key to the VM so logging into the VM doesn't require a password:

```console
ssh-keygen -t rsa -b 4096 -C "${USER_EMAIL}"
ssh-copy-id -i ~/.ssh/id_rsa.pub ${GOLDEN_IP}
```

Log into the `golden-fedora-37` VM:

```console
$ ssh ${USER}@${GOLDEN_IP}
```

> Remote Server Commands: END

### Record IP Address in .bashrc

> Remote Server Commands: BEGIN

Optional, but may be useful to record the IP Address of each VM in the `~/.bashrc`
 in an alias for easy login to each VM, something like:

```console
vi ~/.bashrc
:

svm() {
    ssh ${USER}@192.168.122."$1"
}

alias vmgd='svm 142'
alias vmg1='svm 138'
alias vmi1='svm 194'
alias vmi2='svm 193'
alias vmi3='svm 52'
alias vmt1='svm 181'
alias vmt2='svm 39'
alias vmt3='svm 62'
alias vmt4='svm 185'

svmhelp() {
   echo ""
   echo " vmgd - svm 142 - golden-fedora-37"
   echo " vmg1 - svm 138 - gw-1"
   echo " vmi1 - svm 194 - infra-1"
   echo " vmi2 - svm 193 - infra-2"
   echo " vmi3 - svm 52  - infra-3"
   echo " vmt1 - svm 181 - tenant-1"
   echo " vmi2 - svm 39  - tenant-2"
   echo " vmi3 - svm 62  - tenant-3"
   echo " vmi4 - svm 185 - tenant-4"
   echo ""
}
```

Remember to reload the file after each edit:

```console
. ~/.bashrc
```

> Remote Server Commands: END


### Install Base Packages

> Virtual Machine `golden-fedora-37` Commands: BEGIN

Install the following packages:

```console
sudo dnf update -y
sudo dnf install -y net-tools pciutils tcpdump bridge-utils wget git jq
sudo dnf install -y kernel-devel
sudo dnf groupinstall -y 'Development Tools' 
sudo dnf groupinstall -y 'C Development Tools and Libraries' 
sudo dnf install -y golang
sudo dnf install python3-pip
```

To run 'sudo' commands without password:

```console
sudo visudo
:
## Same thing without a password
# %wheel        ALL=(ALL)       NOPASSWD: ALL
$USER ALL=(ALL) NOPASSWD:ALL
:
```

> Virtual Machine `golden-fedora-37` Commands: END

### Install Scripts

> Virtual Machine `golden-fedora-37` Commands: BEGIN

Download this repository in the Golden VM for a local copy of the scripts:

```console
mkdir -p ~/src/; cd ~/src/
git clone https://github.com/Billy99/dpu-software.git
cd ~/src/dpu-software/
```

If any non-default settings were made on the Remote Server, update
[variables.sh](scripts/variables.sh) in the VM now with those same changes.

> Virtual Machine `golden-fedora-37` Commands: END

### Stop the VM

> Remote Server Commands: BEGIN

The base VM is initialized, so stop it:

```console
$ sudo virsh list --all
 Id   Name               State
-----------------------------------
 2    golden-fedora-37   running

$ sudo virsh shutdown golden-fedora-37
Domain 'golden-fedora-37' is being shutdown

$ sudo virsh list --all
 Id   Name               State
-----------------------------------
 -    golden-fedora-37   shut off
```

> Remote Server Commands: END
