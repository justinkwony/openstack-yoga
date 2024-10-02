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
# Install the components, neutron-openvswitch-agent # from 2024.1
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Installing additional packages for Self-service networks."
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-server neutron-plugin-ml2
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-openvswitch-agent
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall neutron-l3-agent neutron-dhcp-agent neutron-metadata-agent

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the server component
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

conf=/etc/neutron/neutron.conf
echo "Configuring $conf."

# Configure [DEFAULT] section.
iniset_sudo $conf DEFAULT core_plugin ml2
iniset_sudo $conf DEFAULT service_plugins router
iniset_sudo $conf DEFAULT auth_strategy keystone
# iniset_sudo $conf DEFAULT allow_overlapping_ips true

echo "Configuring RabbitMQ message queue access."
iniset_sudo $conf DEFAULT transport_url "rabbit://openstack:$RABBIT_PASS@controller"

# Configure nova related parameters
iniset_sudo $conf DEFAULT notify_nova_on_port_status_changes true
iniset_sudo $conf DEFAULT notify_nova_on_port_data_changes true

# Configure [database] section.
iniset_sudo $conf database connection "mysql+pymysql://$NEUTRON_DB_USER:$NEUTRON_DBPASS@controller/neutron"

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

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Modular Layer 2 (ML2) plug-in
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring the Modular Layer 2 (ML2) plug-in."
conf=/etc/neutron/plugins/ml2/ml2_conf.ini

# Edit the [ml2] section.
iniset_sudo $conf ml2 type_drivers flat,vlan,vxlan
iniset_sudo $conf ml2 tenant_network_types vxlan
iniset_sudo $conf ml2 mechanism_drivers openvswitch,l2population
iniset_sudo $conf ml2 extension_drivers port_security

# Edit the [ml2_type_flat] section.
iniset_sudo $conf ml2_type_flat flat_networks provider

# Edit the [ml2_type_vxlan] section.
iniset_sudo $conf ml2_type_vxlan vni_ranges 1:1000

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure the Open vSwitch agent
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Configuring Open vSwitch agent."
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
