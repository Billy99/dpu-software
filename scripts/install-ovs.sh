#!/bin/bash

CALL_POPD=false
if [[ "$PWD" != */scripts ]]; then
    pushd scripts &>/dev/null
fi

 Source the variables in other files
. variables.sh

echo
echo "#################################"
echo "Variables ..."
echo "#################################"
echo "DISABLE_FIREWALLD: ${DISABLE_FIREWALLD}"


echo
echo "#################################"
echo "Download OvS ..."
echo "#################################"
mkdir -p ${WORKING_DIR}
pushd ${WORKING_DIR} &>/dev/null
git clone https://github.com/openvswitch/ovs.git
popd &>/dev/null

pushd ${WORKING_DIR}/ovs/ &>/dev/null


echo
echo "#################################"
echo "Install OvS Dependencies ..."
echo "#################################"
sudo dnf install -y @'Development Tools' rpm-build dnf-plugins-core
sudo dnf install -y unbound
sed -e 's/@VERSION@/0.0.1/' rhel/openvswitch-fedora.spec.in > /tmp/ovs.spec
sudo dnf builddep /tmp/ovs.spec
rm /tmp/ovs.spec


echo
echo "#################################"
echo "Build the OvS RPM ..."
echo "#################################"
./boot.sh
./configure
make rpm-fedora


echo
echo "#################################"
echo "Install the RPM and start and enable OvS ..."
echo "#################################"
sudo rpm -i rpm/rpmbuild/RPMS/x86_64/openvswitch-2.17.5-1.fc37.x86_64.rpm
sudo systemctl start openvswitch
sudo systemctl enable openvswitch


if [ "$DISABLE_FIREWALLD" == false ] ; then
   echo
   echo "#################################"
   echo "Open Firewall ports used by OVN-Kubernetes ..."
   echo "#################################"
   sudo firewall-cmd --permanent --add-port=6641/tcp
   sudo firewall-cmd --permanent --add-port=6642/tcp
   sudo firewall-cmd --permanent --add-port=9107/tcp
   sudo firewall-cmd --permanent --add-port=9410/tcp

   sudo firewall-cmd --reload
fi


# Leave ovs directory
popd &>/dev/null


if [[ "$CALL_POPD" == true ]]; then
    popd &>/dev/null
fi
