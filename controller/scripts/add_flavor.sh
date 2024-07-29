#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$CONFIG_DIR/openstack"
source "$LIB_DIR/functions.guest.sh"

source "$CONFIG_DIR/admin-openstackrc.sh"

openstack --os-region-name="$REGION" flavor create --id c1 --ram 256 --disk 1 --vcpus 1 --property hw_rng:allowed=True cirros256
openstack --os-region-name="$REGION" flavor create --id d1 --ram 512 --disk 5 --vcpus 1 --property hw_rng:allowed=True ds512M
openstack --os-region-name="$REGION" flavor create --id d2 --ram 1024 --disk 10 --vcpus 1 --property hw_rng:allowed=True ds1G
openstack --os-region-name="$REGION" flavor create --id d3 --ram 2048 --disk 10 --vcpus 2 --property hw_rng:allowed=True ds2G
openstack --os-region-name="$REGION" flavor create --id d4 --ram 4096 --disk 20 --vcpus 4 --property hw_rng:allowed=True ds4G
openstack --os-region-name="$REGION" flavor create --id 1 --ram 512 --disk 1 --vcpus 1 --property hw_rng:allowed=True m1.tiny
openstack --os-region-name="$REGION" flavor create --id 2 --ram 2048 --disk 20 --vcpus 1 --property hw_rng:allowed=True m1.small
openstack --os-region-name="$REGION" flavor create --id 3 --ram 4096 --disk 40 --vcpus 2 --property hw_rng:allowed=True m1.medium
openstack --os-region-name="$REGION" flavor create --id 4 --ram 8192 --disk 80 --vcpus 4 --property hw_rng:allowed=True m1.large
openstack --os-region-name="$REGION" flavor create --id 5 --ram 16384 --disk 160 --vcpus 8 --property hw_rng:allowed=True m1.xlarge
