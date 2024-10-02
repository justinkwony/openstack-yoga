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
# Install and configure a compute node for Ubuntu
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Install and configure components
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Installing nova for compute node."
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall nova-compute

echo "Configuring nova for compute node."

nova_admin_user=nova
placement_admin_user=placement

conf=/etc/nova/nova.conf

MY_MGMT_IP=$(get_node_ip_in_network "$(hostname)" "mgmt")

# Configure [DEFAULT] section.
iniset_sudo $conf DEFAULT transport_url "rabbit://openstack:$RABBIT_PASS@controller"
iniset_sudo $conf DEFAULT my_ip "$MY_MGMT_IP"
# iniset_sudo $conf DEFAULT use_neutron true
# iniset_sudo $conf DEFAULT firewall_driver nova.virt.firewall.NoopFirewallDriver

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
iniset_sudo $conf vnc server_listen 0.0.0.0
iniset_sudo $conf vnc server_proxyclient_address '$my_ip'

# resolve the host name "controller"
iniset_sudo $conf vnc novncproxy_base_url http://controller:6080/vnc_auto.html

# Configure [glance] section.
iniset_sudo $conf glance api_servers http://controller:9292

# Configure [oslo_concurrency] section.
iniset_sudo $conf oslo_concurrency lock_path /var/lib/nova/tmp

# Configure [placement] section.
echo "Configuring Placement services."
iniset_sudo $conf placement region_name RegionOne
iniset_sudo $conf placement project_domain_name Default
iniset_sudo $conf placement project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf placement auth_type password
iniset_sudo $conf placement user_domain_name Default
iniset_sudo $conf placement auth_url http://controller:5000/v3
iniset_sudo $conf placement username "$placement_admin_user"
iniset_sudo $conf placement password "$PLACEMENT_PASS"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# change ownership of /var/lib/nova
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

sudo chown -R nova.nova /var/lib/nova

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Finalize installation
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Configure nova-compute.conf
conf=/etc/nova/nova-compute.conf
echo -n "Hardware acceleration for virtualization: "
if sudo egrep -q '(vmx|svm)' /proc/cpuinfo; then
    echo "available."
    iniset_sudo $conf libvirt virt_type kvm
else
    echo "not available."
    iniset_sudo $conf libvirt virt_type qemu
fi
echo "Config: $(sudo grep virt_type $conf)"

echo "Restarting nova services."
sudo systemctl restart nova-compute

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Add the compute node to the cell database
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
echo "continue on controller node, run 053_setup_nova_3.sh"
