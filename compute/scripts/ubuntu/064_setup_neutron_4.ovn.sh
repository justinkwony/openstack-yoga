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
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall ovn-host neutron-ovn-metadata-agent openvswitch-switch

sudo systemctl restart openvswitch-switch

# sudo /usr/share/openvswitch/scripts/ovs-ctl start  --system-id="random"

# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # Configure the common component
# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# conf=/etc/neutron/neutron.conf
# echo "Configuring $conf."

# # Configure [DEFAULT] section.
# iniset_sudo $conf DEFAULT core_plugin ml2
# iniset_sudo $conf DEFAULT service_plugins ovn-router

# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# # Configure the Modular Layer 2 (ML2) plug-in
# # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# echo "Configuring the Modular Layer 2 (ML2) plug-in."
# conf=/etc/neutron/plugins/ml2/ml2_conf.ini

# # Edit the [ml2] section.
# iniset_sudo $conf ml2 type_drivers local,flat,vlan,geneve
# iniset_sudo $conf ml2 tenant_network_types geneve
# iniset_sudo $conf ml2 mechanism_drivers ovn
# iniset_sudo $conf ml2 extension_drivers port_security
# iniset_sudo $conf ml2 overlay_ip_version 4

# # Edit the [ml2_type_geneve] section.
# iniset_sudo $conf ml2_type_geneve vni_ranges 1:65536
# iniset_sudo $conf ml2_type_geneve max_header_size 38

# # Edit the [securitygroup] section.
# iniset_sudo $conf securitygroup enable_security_group true

# # Edit the [ovn] section.
OVERLAY_INTERFACE_IP_ADDRESS=$(get_node_ip_in_network "$(hostname)" "mgmt")
# iniset_sudo $conf ovn ovn_nb_connection tcp:$OVERLAY_INTERFACE_IP_ADDRESS:6641
# iniset_sudo $conf ovn ovn_sb_connection tcp:$OVERLAY_INTERFACE_IP_ADDRESS:6642
# iniset_sudo $conf ovn ovn_l3_scheduler leastloaded

# conf=/etc/neutron/neutron_ovn_metadata_agent.ini
# echo "Configuring $conf."

# # Edit the [DEFAULT] section.
# iniset_sudo $conf DEFAULT nova_metadata_host $OVERLAY_INTERFACE_IP_ADDRESS
# iniset_sudo $conf DEFAULT metadata_proxy_shared_secret "$METADATA_SECRET"

# # Edit the [ovs] section.
# iniset_sudo $conf ovs ovsdb_connection tcp:10.10.0.11:6640

sudo ovs-vsctl set open . external-ids:ovn-remote=tcp:10.10.0.11:6642
sudo ovs-vsctl set open . external-ids:ovn-encap-type=geneve,vxlan
sudo ovs-vsctl set open . external-ids:ovn-encap-ip=$OVERLAY_INTERFACE_IP_ADDRESS

# sudo /usr/share/ovn/scripts/ovn-ctl stop_controller
# sudo /usr/share/ovn/scripts/ovn-ctl start_controller

# sudo systemctl restart openvswitch-switch ovn-host
# sudo systemctl restart neutron-ovn-metadata-agent nova-compute
sudo systemctl start ovn-controller neutron-ovn-metadata-agent
#------------------------------------------------------------------------------
# Verify operation
#------------------------------------------------------------------------------
sudo ovn-sbctl show
