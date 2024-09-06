#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"
source "$CONFIG_DIR/openstack"

exec_logfile

indicate_current_auto

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Install the components
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Installing additional packages for OVN networks."
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall ovn-central openvswitch-common

sudo systemctl restart openvswitch-switch

# sudo /usr/share/openvswitch/scripts/ovs-ctl start --system-id="random"

OVERLAY_INTERFACE_IP_ADDRESS=$(get_node_ip_in_network "$(hostname)" "mgmt")
sudo ovn-nbctl set-connection ptcp:6641:$OVERLAY_INTERFACE_IP_ADDRESS -- set connection . inactivity_probe=60000
sudo ovn-sbctl set-connection ptcp:6642:$OVERLAY_INTERFACE_IP_ADDRESS -- set connection . inactivity_probe=60000
# if using the VTEP functionality:
sudo ovs-appctl -t ovsdb-server ovsdb-server/add-remote ptcp:6640:$OVERLAY_INTERFACE_IP_ADDRESS

sudo /usr/share/ovn/scripts/ovn-ctl start_northd

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the common component
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

conf=/etc/neutron/neutron.conf
echo "Configuring $conf."

# Configure [DEFAULT] section.
iniset_sudo $conf DEFAULT core_plugin ml2
iniset_sudo $conf DEFAULT service_plugins ovn-router

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Modular Layer 2 (ML2) plug-in
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the Modular Layer 2 (ML2) plug-in."
conf=/etc/neutron/plugins/ml2/ml2_conf.ini

# Edit the [ml2] section.
iniset_sudo $conf ml2 type_drivers local,flat,vlan,geneve
iniset_sudo $conf ml2 tenant_network_types geneve
iniset_sudo $conf ml2 mechanism_drivers ovn
iniset_sudo $conf ml2 extension_drivers port_security
iniset_sudo $conf ml2 overlay_ip_version 4

# Edit the [ml2_type_geneve] section.
iniset_sudo $conf ml2_type_geneve vni_ranges 1:65536
iniset_sudo $conf ml2_type_geneve max_header_size 38

# Edit the [ml2_type_vxlan] section.
iniset_sudo $conf ml2_type_vxlan vni_ranges 1001:1100

# Edit the [ml2_type_vlan] section.
iniset_sudo $conf ml2_type_vlan network_vlan_ranges provider,in_net_1:1001:2000

# Edit the [securitygroup] section.
iniset_sudo $conf securitygroup enable_security_group true

# Edit the [ovn] section.
iniset_sudo $conf ovn ovn_nb_connection tcp:$OVERLAY_INTERFACE_IP_ADDRESS:6641
iniset_sudo $conf ovn ovn_sb_connection tcp:$OVERLAY_INTERFACE_IP_ADDRESS:6642
iniset_sudo $conf ovn ovn_l3_scheduler leastloaded

sudo ovs-vsctl set open . external-ids:ovn-cms-options=enable-chassis-as-gw

# sudo systemctl restart openvswitch-switch
# sudo systemctl restart ovn-central ovn-northd
sudo systemctl restart neutron-server
