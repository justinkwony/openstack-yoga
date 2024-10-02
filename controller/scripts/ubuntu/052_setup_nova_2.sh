#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$CONFIG_DIR/openstack"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Install and configure controller node for Ubuntu
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Install and configure components
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Installing nova for controller node."
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall nova-api nova-conductor nova-novncproxy nova-scheduler

echo "Configuring nova for controller node."

nova_admin_user=nova
placement_admin_user=placement

conf=/etc/nova/nova.conf

MY_MGMT_IP=$(hostname_to_ip controller)

# Configure [DEFAULT] section.
iniset_sudo $conf DEFAULT transport_url "rabbit://openstack:$RABBIT_PASS@controller:5672"
iniset_sudo $conf DEFAULT my_ip "$MY_MGMT_IP"
# iniset_sudo $conf DEFAULT use_neutron true
# iniset_sudo $conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

# Configure [api_database] section.
iniset_sudo $conf api_database connection "mysql+pymysql://$NOVA_DB_USER:$NOVA_DBPASS@controller/nova_api"

# Configure [database] section.
iniset_sudo $conf database connection "mysql+pymysql://$NOVA_DB_USER:$NOVA_DBPASS@controller/nova"

# Configure [api] section.
iniset_sudo $conf api auth_strategy keystone

# Configure [keystone_authtoken] section.
iniset_sudo $conf keystone_authtoken www_authenticate_uri http://controller:5000
iniset_sudo $conf keystone_authtoken auth_url http://controller:5000/
iniset_sudo $conf keystone_authtoken memcached_servers controller:11211
iniset_sudo $conf keystone_authtoken auth_type password
iniset_sudo $conf keystone_authtoken project_domain_name Default
iniset_sudo $conf keystone_authtoken user_domain_name Default
iniset_sudo $conf keystone_authtoken project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf keystone_authtoken username "$nova_admin_user"
iniset_sudo $conf keystone_authtoken password "$NOVA_PASS"

# Configure [service_user] section.
iniset_sudo $conf service_user send_service_user_token true
iniset_sudo $conf service_user auth_url http://controller:5000
# iniset_sudo $conf service_user auth_url https://controller/identity
iniset_sudo $conf service_user auth_strategy keystone
iniset_sudo $conf service_user auth_type password
iniset_sudo $conf service_user project_domain_name Default
iniset_sudo $conf service_user project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf service_user user_domain_name Default
iniset_sudo $conf service_user username "$nova_admin_user"
iniset_sudo $conf service_user password "$NOVA_PASS"

# Configure [vnc] section.
iniset_sudo $conf vnc enabled true
iniset_sudo $conf vnc server_listen '$my_ip'
iniset_sudo $conf vnc server_proxyclient_address '$my_ip'

# Configure [glance] section.
iniset_sudo $conf glance api_servers http://controller:9292

# Configure [oslo_concurrency] section.
iniset_sudo $conf oslo_concurrency lock_path /var/lib/nova/tmp

# option from the [DEFAULT] section."
# sudo grep "^log_dir" $conf
# sudo sed -i "/^log_dir/ d" $conf

# Configure [placement] section.
iniset_sudo $conf placement region_name RegionOne
iniset_sudo $conf placement project_domain_name Default
iniset_sudo $conf placement project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf placement auth_type password
iniset_sudo $conf placement user_domain_name Default
iniset_sudo $conf placement auth_url http://controller:5000/v3
iniset_sudo $conf placement username "$placement_admin_user"
iniset_sudo $conf placement password "$PLACEMENT_PASS"

echo "Populating the nova-api databases."
sudo su -s /bin/sh -c "nova-manage api_db sync" nova

echo "Registering the cell0 database."
sudo su -s /bin/sh -c "nova-manage cell_v2 map_cell0" nova

echo "Creating the cell1 cell."
sudo su -s /bin/sh -c "nova-manage cell_v2 create_cell --name=cell1 --verbose" nova

echo "Populating the nova database."
sudo su -s /bin/sh -c "nova-manage db sync" nova

echo "Verifying nova cell0 and cell1 are registered correctly."
sudo su -s /bin/sh -c "nova-manage cell_v2 list_cells" nova

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Sourcing the admin credentials."
source "$CONFIG_DIR/admin-openstackrc.sh"

# Wait for keystone to come up
wait_for_keystone

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Finalize installation
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Restarting nova services."
declare -a nova_services=(nova-api nova-scheduler nova-conductor nova-novncproxy)

for nova_service in "${nova_services[@]}"; do
    echo "Restarting $nova_service."
    sudo systemctl restart "$nova_service"
    sudo systemctl enable "$nova_service"
done

#------------------------------------------------------------------------------
# Verify the Compute controller installation (not in install-guide)
#------------------------------------------------------------------------------

echo -n "Verifying operation of the Compute service."
echo
until openstack service list 2>/dev/null; do
    sleep 1
    echo -n .
done
echo

echo "Checking nova endpoints."
openstack catalog list

echo "Checking nova images."
openstack image list
