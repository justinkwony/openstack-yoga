#!/usr/bin/env bash

files="
/etc/keystone/keystone.conf
/etc/neutron/dhcp_agent.ini
/etc/neutron/l3_agent.ini
/etc/neutron/metadata_agent.ini
/etc/neutron/neutron_ovn_metadata_agent.ini
/etc/neutron/neutron.conf
/etc/neutron/plugins/ml2/linuxbridge_agent.ini
/etc/neutron/plugins/ml2/ml2_conf.ini
/etc/neutron/plugins/ml2/openvswitch_agent.ini
/etc/nova/nova-compute.conf
/etc/nova/nova.conf
"
#/etc/memcached.conf
#/etc/mysql/mariadb.conf.d/99-openstack.cnf
#/etc/apache2/apache2.conf
#/etc/apache2/conf-available/cinder-wsgi.conf
#/etc/apache2/conf-available/openstack-dashboard.conf
#/etc/apache2/sites-enabled/keystone.conf
#/etc/apache2/sites-enabled/placement-api.conf
#/etc/barbican/barbican.conf
#/etc/cinder/cinder.conf
#/etc/default/etcd
#/etc/glance/glance-api.conf
#/etc/heat/heat.conf
#/etc/openstack-dashboard/local_settings.py
#/etc/placement/placement.conf
#/etc/swift/proxy-server.conf
#/etc/swift/swift.conf
#/etc/trove/trove-guestagent.conf
#/etc/trove/trove.conf

for file in $files; do
    echo
    echo $file
    sudo grep -E '^[^#].+' $file
done
