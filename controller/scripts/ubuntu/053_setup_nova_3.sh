#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"
source "$CONFIG_DIR/admin-openstackrc.sh"

exec_logfile

indicate_current_auto

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Add the compute node to the cell database
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo -n "Confirming that the compute host is in the database."
echo
source $CONFIG_DIR/admin-openstackrc.sh
openstack compute service list --service nova-compute
until openstack compute service list --service nova-compute | grep 'compute.*up' >/dev/null 2>&1; do
    sleep 2
    echo -n .
done
openstack compute service list --service nova-compute

echo
echo "Discovering compute hosts."
echo "Run this command on controller every time compute hosts are added to the cluster."
sudo su -s /bin/sh -c "nova-manage cell_v2 discover_hosts --verbose" nova

#------------------------------------------------------------------------------
# Verify operation
#------------------------------------------------------------------------------

echo "Verifying operation of the Compute service."

echo "openstack compute service list"
openstack compute service list

echo "Checking the cells and placement API are working successfully."
echo "on controller node: nova-status upgrade check"
sudo nova-status upgrade check
