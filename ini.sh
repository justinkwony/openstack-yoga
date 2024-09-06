#!/usr/bin/env bash

files="
/etc/neutron/neutron.conf
/etc/neutron/dhcp_agent.ini
/etc/neutron/metadata_agent.ini
/etc/neutron/neutron_ovn_metadata_agent.ini
/etc/neutron/plugins/ml2/linuxbridge_agent.ini
/etc/neutron/plugins/ml2/ml2_conf.ini
/etc/neutron/plugins/ml2/openvswitch_agent.ini
"
for file in $files; do
    echo
    echo $file
    sudo grep -E '^[^#].+' $file
done
