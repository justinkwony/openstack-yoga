#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

#------------------------------------------------------------------------------
# Install the Image Service (glance).
#------------------------------------------------------------------------------
sudo apt -y install etcd

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Prerequisites
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

MGMT_IP=$(get_node_ip_in_network "$(hostname)" "mgmt")

conf=/etc/default/etcd

iniset_sudo $conf no_section ETCD_NAME "controller"
# iniset_sudo $conf no_section ETCD_DATA_DIR "/var/lib/etcd/default.etcd"
iniset_sudo $conf no_section ETCD_DATA_DIR "/var/lib/etcd"
iniset_sudo $conf no_section ETCD_LISTEN_PEER_URLS "http://0.0.0.0:2380"
iniset_sudo $conf no_section ETCD_LISTEN_CLIENT_URLS "http://$MGMT_IP:2379"
#[Clustering]
iniset_sudo $conf no_section ETCD_INITIAL_CLUSTER_STATE "new"
iniset_sudo $conf no_section ETCD_INITIAL_CLUSTER_TOKEN "etcd-cluster-01"
iniset_sudo $conf no_section ETCD_INITIAL_CLUSTER "controller=http://$MGMT_IP:2380"
iniset_sudo $conf no_section ETCD_INITIAL_ADVERTISE_PEER_URLS "http://$MGMT_IP:2380"
iniset_sudo $conf no_section ETCD_ADVERTISE_CLIENT_URLS "http://$MGMT_IP:2379"

echo "Restarting etcd service."
sudo systemctl enable etcd
sudo systemctl start etcd
