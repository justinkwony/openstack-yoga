read -t 1  -p "========================= 001_apt_init"; echo
./001_apt_init.sh
read -t 10 -p "========================= 002_apt_upgrade"; echo
./002_apt_upgrade.sh
read -t 10 -p "========================= 011_install_mysql"; echo
./011_install_mysql.sh
read -t 10 -p "========================= 012_install_rabbitmq"; echo
./012_install_rabbitmq.sh
read -t 10 -p "========================= 013_install_memcached"; echo
./013_install_memcached.sh
read -t 10 -p "========================= 014_install_etcd"; echo
./014_install_etcd.sh
read -t 10 -p "========================= 021_setup_keystone_1"; echo
./021_setup_keystone_1.sh
read -t 10 -p "========================= 022_setup_keystone_2"; echo
./022_setup_keystone_2.sh
read -t 10 -p "========================= 031_setup_glance_1"; echo
./031_setup_glance_1.sh
read -t 10 -p "========================= 032_setup_glance_2"; echo
./032_setup_glance_2.sh
read -t 10 -p "========================= 041_setup_placement_1"; echo
./041_setup_placement_1.sh
read -t 10 -p "========================= 042_setup_placement_2"; echo
./042_setup_placement_2.sh
read -t 10 -p "========================= 051_setup_nova_1"; echo
./051_setup_nova_1.sh
read -t 10 -p "========================= 052_setup_nova_2"; echo
./052_setup_nova_2.sh
# read -t 10 -p "========================= 053_setup_nova_3"; echo
# ./053_setup_nova_3.sh
# read -t 10 -p "========================= 054_setup_nova_4"; echo
# ./054_setup_nova_4.sh
read -t 10 -p "========================= 061_setup_neutron_1"; echo
./061_setup_neutron_1.sh
read -t 10 -p "========================= 062_setup_neutron_2"; echo
./062_setup_neutron_2.openvswitch_provider.sh
echo "========================= continue on storage, compute node"; echo
