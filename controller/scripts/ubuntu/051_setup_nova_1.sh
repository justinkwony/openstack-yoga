#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Install and configure controller node for Ubuntu
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Prerequisites
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Setting up database nova."
setup_database nova "$NOVA_DB_USER" "$NOVA_DBPASS"

echo "Setting up database nova_api."
setup_database nova_api "$NOVA_DB_USER" "$NOVA_DBPASS"

echo "Setting up first cell database."
# nova_cell0 is default name for first cell database
setup_database nova_cell0 "$NOVA_DB_USER" "$NOVA_DBPASS"

echo "Sourcing the admin credentials."
source "$CONFIG_DIR/admin-openstackrc.sh"

nova_admin_user=nova

# Wait for keystone to come up
wait_for_keystone

echo "Creating nova user and giving it the admin role."
openstack user create --domain default --password "$NOVA_PASS" "$nova_admin_user"
openstack role add --project "$SERVICE_PROJECT_NAME" --user "$nova_admin_user" "$ADMIN_ROLE_NAME"

echo "Creating the nova service entity."
openstack service create --name nova --description "OpenStack Compute" compute

echo "Creating nova endpoints."
openstack endpoint create --region "$REGION" compute public http://controller:8774/v2.1
openstack endpoint create --region "$REGION" compute internal http://controller:8774/v2.1
openstack endpoint create --region "$REGION" compute admin http://controller:8774/v2.1
