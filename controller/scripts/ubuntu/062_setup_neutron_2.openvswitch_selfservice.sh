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
# Install the components, neutron-openvswitch-agent # from 2023.1
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Installing additional packages for Self-service networks."
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-server neutron-plugin-ml2
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-openvswitch-agent
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent

#------------------------------------------------------------------------------
# Networking Option 2: Self-service networks
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
iniset_sudo $conf DEFAULT service_plugins router
iniset_sudo $conf DEFAULT auth_strategy keystone
# iniset_sudo $conf DEFAULT allow_overlapping_ips true

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

# Linuxbridge in experimental section.  Not in install-guide:
# iniset_sudo $conf experimental linuxbridge true

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Modular Layer 2 (ML2) plug-in
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the Modular Layer 2 (ML2) plug-in."
conf=/etc/neutron/plugins/ml2/ml2_conf.ini

# Edit the [ml2] section.
iniset_sudo $conf ml2 type_drivers flat,vlan,vxlan
iniset_sudo $conf ml2 tenant_network_types vxlan
iniset_sudo $conf ml2 mechanism_drivers openvswitch,l2population
# The Linux bridge agent only supports VXLAN overlay networks.
iniset_sudo $conf ml2 extension_drivers port_security

# Edit the [ml2_type_flat] section.
iniset_sudo $conf ml2_type_flat flat_networks provider,in_net_1

# Edit the [ml2_type_vxlan] section.
iniset_sudo $conf ml2_type_vxlan vni_ranges 1:1000

# # Edit the [securitygroup] section.
# iniset_sudo $conf securitygroup enable_ipset true

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Open vSwitch agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring Open vSwitch agent."
conf=/etc/neutron/plugins/ml2/openvswitch_agent.ini

# Edit the [ovs] section.
# set_iface_list
# PROVIDER_BRIDGE_NAME=$(ifnum_to_ifname 1)
# echo "PROVIDER_BRIDGE_NAME=$PROVIDER_BRIDGE_NAME"
# iniset_sudo $conf ovs bridge_mappings provider:$PROVIDER_BRIDGE_NAME,in_net_1:enp0s9
iniset_sudo $conf ovs bridge_mappings provider:br-provider,in_net_1:br-in_net_1
OVERLAY_INTERFACE_IP_ADDRESS=$(get_node_ip_in_network "$(hostname)" "mgmt")
iniset_sudo $conf agent local_ip $OVERLAY_INTERFACE_IP_ADDRESS

# Edit the [agent] section.
iniset_sudo $conf agent enable_vxlan true
iniset_sudo $conf agent l2_population true

# Edit the [securitygroup] section.
iniset_sudo $conf securitygroup enable_security_group true
iniset_sudo $conf securitygroup firewall_driver openvswitch

echo "Ensuring that the kernel supports network bridge filters."
if ! sudo sysctl net.bridge.bridge-nf-call-iptables; then
    sudo modprobe br_netfilter
    echo "# bridge support module added by Ram N Sangwan" >> /etc/modules
    echo br_netfilter >> /etc/modules
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the layer-3 agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the layer-3 agent."
conf=/etc/neutron/l3_agent.ini
iniset_sudo $conf DEFAULT interface_driver openvswitch

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the DHCP agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the DHCP agent."
conf=/etc/neutron/dhcp_agent.ini
iniset_sudo $conf DEFAULT interface_driver openvswitch
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
