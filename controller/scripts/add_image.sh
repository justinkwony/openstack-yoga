#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$CONFIG_DIR/openstack"
source "$LIB_DIR/functions.guest.sh"

source "$CONFIG_DIR/admin-openstackrc.sh"

openstack image create --file "/home/stack/openstack-yoga/controller/scripts/img/jammy-server-cloudimg-amd64.img" \
    --disk-format qcow2 --container-format bare \
    --public "Ubuntu 22.04.4"
