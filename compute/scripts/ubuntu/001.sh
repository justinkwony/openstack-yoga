./1_apt_init.sh
read -t 10 -p "========================= 2_apt_upgrade"; echo
./2_apt_upgrade.sh
read -t 10 -p "========================= 3_setup_nova_1"; echo
./3_setup_nova_1.sh
read -t 10 -p "========================= 4_setup_nova_2"; echo
./4_setup_nova_2.sh
read -t 10 -p "========================= 5_setup_neutron_1"; echo
./5_setup_neutron_1.sh
read -t 10 -p "========================= 6_setup_neutron_2"; echo
./6_setup_neutron_2.sh
read -t 10 -p "========================= 7_setup_neutron_3"; echo
./7_setup_neutron_3.sh
read -t 10 -p "========================= 8_setup_neutron_4"; echo
./8_setup_neutron_4.sh
read -t 10 -p "========================= 9_setup_swift_1"; echo
./9_setup_swift_1.sh
read -t 10 -p "========================= 10_setup_swift_2"; echo
./10_setup_swift_2.sh
read -t 10 -p "========================= 11_setup_swift_3"; echo
./11_setup_swift_3.sh
