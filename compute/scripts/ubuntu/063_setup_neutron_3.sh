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

if [ -e /etc/init.d/neutron-linuxbridge-agent ]; then
    echo "Restarting neutron-linuxbridge-agent."
    sudo systemctl restart neutron-linuxbridge-agent
fi

if [ -e /etc/init.d/neutron-openvswitch-agent ]; then
    echo "Restarting neutron-openvswitch-agent."
    sudo systemctl restart neutron-openvswitch-agent
fi

#------------------------------------------------------------------------------
# Verifying
#------------------------------------------------------------------------------
# echo "Listing agents to verify successful launch of the neutron agents."

# echo "openstack network agent list"
# # openstack network agent list
# AUTH="source $CONFIG_DIR/admin-openstackrc.sh"
# node_ssh controller "$AUTH; openstack network agent list"
