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
# Install the components, neutron-linuxbridge-agent # yoga, zed
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Installing additional packages for Provider networks."
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-server neutron-plugin-ml2
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-linuxbridge-agent
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-dhcp-agent neutron-metadata-agent

#------------------------------------------------------------------------------
# Networking Option 1: Provider networks
#------------------------------------------------------------------------------

echo "Configuring neutron for controller node."
function get_database_url {
    local db_user=$NEUTRON_DB_USER
    local database_host=controller

    echo "mysql+pymysql://$db_user:$NEUTRON_DBPASS@$database_host/neutron"
}

database_url=$(get_database_url)

echo "Setting database connection: $database_url."
conf=/etc/neutron/neutron.conf
echo "Configuring $conf."

# Configure [database] section.
iniset_sudo $conf database connection "$database_url"

# Configure [DEFAULT] section.
iniset_sudo $conf DEFAULT core_plugin ml2
iniset_sudo $conf DEFAULT service_plugins ""
iniset_sudo $conf DEFAULT auth_strategy keystone
# iniset_sudo $conf DEFAULT dhcp_agents_per_network 2

echo "Configuring RabbitMQ message queue access."
iniset_sudo $conf DEFAULT transport_url "rabbit://openstack:$RABBIT_PASS@controller"

neutron_admin_user=neutron

# Configuring [keystone_authtoken] section.
iniset_sudo $conf keystone_authtoken www_authenticate_uri http://controller:5000
iniset_sudo $conf keystone_authtoken auth_url http://controller:5000
iniset_sudo $conf keystone_authtoken memcached_servers controller:11211
iniset_sudo $conf keystone_authtoken auth_type password
iniset_sudo $conf keystone_authtoken project_domain_name default
iniset_sudo $conf keystone_authtoken user_domain_name default
iniset_sudo $conf keystone_authtoken project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf keystone_authtoken username "$neutron_admin_user"
iniset_sudo $conf keystone_authtoken password "$NEUTRON_PASS"

# Configure nova related parameters
iniset_sudo $conf DEFAULT notify_nova_on_port_status_changes true
iniset_sudo $conf DEFAULT notify_nova_on_port_data_changes true

nova_admin_user=nova

# Configure [nova] section.
iniset_sudo $conf nova auth_url http://controller:5000
iniset_sudo $conf nova auth_type password
iniset_sudo $conf nova project_domain_name default
iniset_sudo $conf nova user_domain_name default
iniset_sudo $conf nova region_name "$REGION"
iniset_sudo $conf nova project_name "$SERVICE_PROJECT_NAME"
iniset_sudo $conf nova username "$nova_admin_user"
iniset_sudo $conf nova password "$NOVA_PASS"

# lock_path
iniset_sudo $conf oslo_concurrency lock_path /var/lib/neutron/tmp

# Linuxbridge in experimental section. Not in install-guide:
# iniset_sudo $conf experimental linuxbridge true

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Modular Layer 2 (ML2) plug-in
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the Modular Layer 2 (ML2) plug-in."
conf=/etc/neutron/plugins/ml2/ml2_conf.ini

# Edit the [ml2] section.
iniset_sudo $conf ml2 type_drivers flat,vlan
iniset_sudo $conf ml2 tenant_network_types ""
iniset_sudo $conf ml2 mechanism_drivers linuxbridge
iniset_sudo $conf ml2 extension_drivers port_security

# Edit the [ml2_type_flat] section.
iniset_sudo $conf ml2_type_flat flat_networks provider

# # Edit the [ml2_type_vlan] section.
# iniset_sudo $conf ml2_type_vlan network_vlan_ranges provider

# Edit the [securitygroup] section.
iniset_sudo $conf securitygroup enable_ipset true

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Linux bridge agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring Linux Bridge agent."
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
    echo "# bridge support module added by Ram N Sangwan" >> /etc/modules
    echo br_netfilter >> /etc/modules
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the DHCP agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the DHCP agent."
conf=/etc/neutron/dhcp_agent.ini
iniset_sudo $conf DEFAULT interface_driver linuxbridge
iniset_sudo $conf DEFAULT dhcp_driver neutron.agent.linux.dhcp.Dnsmasq
iniset_sudo $conf DEFAULT enable_isolated_metadata true
# iniset_sudo $conf DEFAULT use_namespaces False

# # Not in install-guide:
# iniset_sudo $conf DEFAULT dnsmasq_config_file /etc/neutron/dnsmasq-neutron.conf

# cat << DNSMASQ | sudo tee /etc/neutron/dnsmasq-neutron.conf
# # Override --no-hosts dnsmasq option supplied by neutron
# addn-hosts=/etc/hosts

# # Log dnsmasq queries to syslog
# log-queries

# # Verbose logging for DHCP
# log-dhcp
# DNSMASQ

#------------------------------------------------------------------------------
# Set up OpenStack Networking (neutron) for controller node.
#------------------------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the metadata agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the metadata agent."
conf=/etc/neutron/metadata_agent.ini
iniset_sudo $conf DEFAULT nova_metadata_host controller
iniset_sudo $conf DEFAULT metadata_proxy_shared_secret "$METADATA_SECRET"

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
iniset_sudo $conf neutron service_metadata_proxy true
iniset_sudo $conf neutron metadata_proxy_shared_secret "$METADATA_SECRET"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Finalize installation
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Populating the database."
sudo neutron-db-manage \
    --config-file /etc/neutron/neutron.conf \
    --config-file /etc/neutron/plugins/ml2/ml2_conf.ini \
    upgrade head

echo "Restarting nova services."
sudo systemctl restart nova-api.service

echo "Restarting neutron-server."
sudo systemctl restart neutron-server.service

echo "Restarting neutron-linuxbridge-agent."
sudo systemctl restart neutron-linuxbridge-agent.service

echo "Restarting neutron-dhcp-agent."
sudo systemctl restart neutron-dhcp-agent.service

echo "Restarting neutron-metadata-agent."
sudo systemctl restart neutron-metadata-agent.service

#------------------------------------------------------------------------------
# Verifying OpenStack Networking (neutron) for controller node.
#------------------------------------------------------------------------------
source "$CONFIG_DIR/admin-openstackrc.sh"

# Wait for keystone to come up
wait_for_keystone

echo -n "Verifying operation."
until openstack network agent list >/dev/null 2>&1; do
    sleep 1
    echo -n .
done
echo

openstack network agent list
