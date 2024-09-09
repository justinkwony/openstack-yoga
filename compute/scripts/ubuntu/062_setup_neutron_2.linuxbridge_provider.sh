#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

#------------------------------------------------------------------------------
# Networking Option 1: Provider networks
#------------------------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Linux bridge agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the Linux bridge agent."
conf=/etc/neutron/plugins/ml2/linuxbridge_agent.ini

# Edit the [linux_bridge] section.
set_iface_list
PUBLIC_INTERFACE_NAME=$(ifnum_to_ifname 1)
echo "PUBLIC_INTERFACE_NAME=$PUBLIC_INTERFACE_NAME"
iniset_sudo $conf linux_bridge physical_interface_mappings provider:$PUBLIC_INTERFACE_NAME

# Edit the [vxlan] section.
iniset_sudo $conf vxlan enable_vxlan false

# Edit the [securitygroup] section.
iniset_sudo $conf securitygroup enable_security_group true
iniset_sudo $conf securitygroup firewall_driver neutron.agent.linux.iptables_firewall.IptablesFirewallDriver

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

echo "Restarting neutron-linuxbridge-agent."
sudo systemctl restart neutron-linuxbridge-agent.service

#------------------------------------------------------------------------------
# Verifying
#------------------------------------------------------------------------------
# echo "Listing agents to verify successful launch of the neutron agents."

# echo "openstack network agent list"
# # openstack network agent list
# AUTH="source $CONFIG_DIR/admin-openstackrc.sh"
# node_ssh controller "$AUTH; openstack network agent list"
