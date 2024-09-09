sudo apt remove -y --purge neutron-server neutron-plugin-ml2
sudo apt remove -y --purge neutron-linuxbridge-agent neutron-openvswitch-agent neutron-l3-agent
sudo apt remove -y --purge neutron-dhcp-agent neutron-metadata-agent

sudo rm -rf /etc/neutron/ /var/lib/neutron/ /var/log/neutron /var/cache/neutron

sudo apt autoremove -y
