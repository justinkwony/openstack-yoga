#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$CONFIG_DIR/openstack"
source "$LIB_DIR/functions.guest.sh"

source "$CONFIG_DIR/admin-openstackrc.sh"

openstack security group create sg_base
openstack security group rule create --protocol tcp --dst-port 22:22 sg_base
openstack security group rule create --protocol icmp sg_base
