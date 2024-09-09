#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

#------------------------------------------------------------------------------
# Networking Option 2: Self-service networks
#------------------------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Open vSwitch agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the Open vSwitch agent."
conf=/etc/neutron/plugins/ml2/openvswitch_agent.ini

# Edit the [ovs] section.
# $ ovs-vsctl add-br br-provider
# $ ovs-vsctl add-port br-provider PROVIDER_INTERFACE
iniset_sudo $conf ovs bridge_mappings provider:br-provider
OVERLAY_INTERFACE_IP_ADDRESS=$(get_node_ip_in_network "$(hostname)" "mgmt")
iniset_sudo $conf ovs local_ip $OVERLAY_INTERFACE_IP_ADDRESS

# Edit the [agent] section.
iniset_sudo $conf agent tunnel_types vxlan
iniset_sudo $conf agent l2_population true

# Edit the [securitygroup] section.
iniset_sudo $conf securitygroup enable_security_group true
iniset_sudo $conf securitygroup firewall_driver openvswitch

echo "Ensuring that the kernel supports network bridge filters."
if ! sudo sysctl net.bridge.bridge-nf-call-iptables; then
    sudo modprobe br_netfilter
    echo "# bridge support module added by The SkillPedia" >> /etc/modules
    echo br_netfilter >> /etc/modules
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Compute service to use the Networking service
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

neutron_admin_user=neutron

echo "Configuring Compute to use Networking."
conf=/etc/nova/nova.conf

iniset_sudo $conf neutron auth_url http://controller:5000
iniset_sudo $conf neutron auth_type password
iniset_sudo $conf neutron project_domain_name default
iniset_sudo $conf neutron user_domain_name default
iniset_sudo $conf neutron region_name "$REGION"
iniset_sudo $conf neutron project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf neutron username "$neutron_admin_user"
iniset_sudo $conf neutron password "$NEUTRON_PASS"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Finalize installation
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Restarting the Compute service."
sudo systemctl restart nova-compute.service

echo "Restarting neutron-openvswitch-agent."
sudo systemctl restart neutron-openvswitch-agent.service

#------------------------------------------------------------------------------
# Verifying
#------------------------------------------------------------------------------
# echo "Listing agents to verify successful launch of the neutron agents."

# echo "openstack network agent list"
# # openstack network agent list
# AUTH="source $CONFIG_DIR/admin-openstackrc.sh"
# node_ssh controller "$AUTH; openstack network agent list"
