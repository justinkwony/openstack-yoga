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
# Networking Option 2: Self-service networks
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Open vSwitch agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the Open vSwitch agent."
conf=/etc/neutron/plugins/ml2/openvswitch_agent.ini

# $ ovs-vsctl add-br PROVIDER_BRIDGE_NAME
# $ ovs-vsctl add-port PROVIDER_BRIDGE_NAME PROVIDER_INTERFACE_NAME
# $ ovs-vsctl add-br br-provider
# $ ovs-vsctl add-port br-provider eno1
set_iface_list
PROVIDER_INTERFACE_NAME=$(ifnum_to_ifname 0)
echo "PROVIDER_INTERFACE_NAME=$PROVIDER_INTERFACE_NAME"
sudo ovs-vsctl add-br br-provider || true
sudo ovs-vsctl add-port br-provider $PROVIDER_INTERFACE_NAME || true

## 2024.1
# Edit the [ovs] section.
iniset_sudo $conf ovs bridge_mappings provider:br-provider
OVERLAY_INTERFACE_IP_ADDRESS=$(get_node_ip_in_network "$(hostname)" "mgmt")
iniset_sudo $conf ovs local_ip $OVERLAY_INTERFACE_IP_ADDRESS

# Edit the [agent] section.
iniset_sudo $conf agent tunnel_types vxlan
iniset_sudo $conf agent l2_population true
## 2024.1

# ## 2023.1
# # Edit the [ovs] section.
# iniset_sudo $conf ovs bridge_mappings provider:br-provider

# # Edit the [vxlan] section.
# OVERLAY_INTERFACE_IP_ADDRESS=$(get_node_ip_in_network "$(hostname)" "mgmt")
# iniset_sudo $conf vxlan local_ip $OVERLAY_INTERFACE_IP_ADDRESS
# iniset_sudo $conf vxlan l2_population true
# ## 2023.1

# Edit the [securitygroup] section.
iniset_sudo $conf securitygroup enable_security_group true
iniset_sudo $conf securitygroup firewall_driver openvswitch
# iniset_sudo $conf securitygroup firewall_driver iptables_hybrid

echo "Ensuring that the kernel supports network bridge filters."
if ! sudo sysctl net.bridge.bridge-nf-call-iptables; then
    sudo modprobe br_netfilter
    echo "# bridge support module added by The SkillPedia" >> /etc/modules
    echo br_netfilter >> /etc/modules
fi
