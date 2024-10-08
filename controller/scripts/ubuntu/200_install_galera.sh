#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

#-------------------------------------------------------------------------------
# Controller setup
#-------------------------------------------------------------------------------

NODE_1_IP=$(hostname_to_ip controller1)
NODE_2_IP=$(hostname_to_ip controller2)
NODE_3_IP=$(hostname_to_ip controller3)
NODE_IP=$(get_node_ip_in_network "$(hostname)" "mgmt")
sudo apt-get install -y -o DPkg::options::=--force-confmiss --reinstall galera-4

conf=/etc/mysql/mariadb.conf.d/60-galera.cnf

iniset_sudo $conf galera wsrep_on ON
iniset_sudo $conf galera wsrep_provider /usr/lib/galera/libgalera_smm.so
iniset_sudo $conf galera wsrep_cluster_address "gcomm://$NODE_1_IP,$NODE_2_IP,$NODE_3_IP"
iniset_sudo $conf galera binlog_format row
iniset_sudo $conf galera default_storage_engine InnoDB
iniset_sudo $conf galera innodb_autoinc_lock_mode 2
iniset_sudo $conf galera bind-address 0.0.0.0
# any cluster name
iniset_sudo $conf galera wsrep_cluster_name "\"MariaDB_Galera_Cluster\""
# own IP address
iniset_sudo $conf galera wsrep_node_address "$NODE_IP"

# sudo systemctl restart mysql
