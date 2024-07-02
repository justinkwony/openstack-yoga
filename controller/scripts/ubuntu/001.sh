./1_apt_init.sh
read -t 10 -p "========================= 2_apt_upgrade"; echo
./2_apt_upgrade.sh
read -t 10 -p "========================= 3_install_mysql"; echo
./3_install_mysql.sh
read -t 10 -p "========================= 4_install_rabbitmq"; echo
./4_install_rabbitmq.sh
read -t 10 -p "========================= 5_install_memcached"; echo
./5_install_memcached.sh
read -t 10 -p "========================= 6_setup_keystone_1"; echo
./6_setup_keystone_1.sh
read -t 10 -p "========================= 7_setup_keystone_2"; echo
./7_setup_keystone_2.sh
read -t 10 -p "========================= 8_setup_glance_1"; echo
./8_setup_glance_1.sh
read -t 10 -p "========================= 9_setup_glance_2"; echo
./9_setup_glance_2.sh
read -t 10 -p "========================= 10_setup_placement_1"; echo
./10_setup_placement_1.sh
read -t 10 -p "========================= 11_setup_placement_2"; echo
./11_setup_placement_2.sh
read -t 10 -p "========================= 12_setup_nova_1"; echo
./12_setup_nova_1.sh
read -t 10 -p "========================= 13_setup_nova_2"; echo
./13_setup_nova_2.sh
read -t 10 -p "========================= 14_setup_nova_3"; echo
./14_setup_nova_3.sh
read -t 10 -p "========================= 15_setup_nova_4"; echo
./15_setup_nova_4.sh
read -t 10 -p "========================= 16_setup_neutron_1"; echo
./16_setup_neutron_1.sh
read -t 10 -p "========================= 17_setup_neutron_2"; echo
./17_setup_neutron_2.sh
read -t 10 -p "========================= 18_setup_neutron_3"; echo
./18_setup_neutron_3.sh
read -t 10 -p "========================= 19_setup_neutron_4"; echo
./19_setup_neutron_4.sh
read -t 10 -p "========================= 20_setup_horizon"; echo
./20_setup_horizon.sh
read -t 10 -p "========================= 21_setup_cinder_1"; echo
./21_setup_cinder_1.sh
read -t 10 -p "========================= 22_setup_cinder_2"; echo
./22_setup_cinder_2.sh
read -t 10 -p "========================= 23_setup_cinder_3"; echo
./23_setup_cinder_3.sh
read -t 10 -p "========================= 24_setup_heat_1"; echo
./24_setup_heat_1.sh
read -t 10 -p "========================= 25_setup_heat_2"; echo
./25_setup_heat_2.sh
read -t 10 -p "========================= 26_setup_swift_1"; echo
./26_setup_swift_1.sh
read -t 10 -p "========================= 27_setup_swift_2"; echo
./27_setup_swift_2.sh
