read -t 1  -p "========================= 001_apt_init"; echo
./001_apt_init.sh
# read -t 10 -p "========================= 051_setup_nova_1"; echo
# ./051_setup_nova_1.sh
# read -t 10 -p "========================= 052_setup_nova_2"; echo
# ./052_setup_nova_2.sh
read -t 10 -p "========================= 053_setup_nova_3"; echo
./053_setup_nova_3.sh
read -t 10 -p "========================= 061_setup_neutron_1"; echo
./061_setup_neutron_1.openvswitch.sh
read -t 10 -p "========================= 062_setup_neutron_2"; echo
./062_setup_neutron_2.openvswitch_provider.sh
# read -t 10 -p "========================= 063_setup_neutron_3"; echo
# ./063_setup_neutron_3.sh
# read -t 10 -p "========================= 064_setup_neutron_4"; echo
# ./064_setup_neutron_4.sh
# read -t 10 -p "========================= 065_setup_neutron_5"; echo
# ./065_setup_neutron_5.sh
# read -t 10 -p "========================= 121_setup_swift_1"; echo
# ./121_setup_swift_1.sh
# read -t 10 -p "========================= 122_setup_swift_2"; echo
# ./122_setup_swift_2.sh
# read -t 10 -p "========================= 123_setup_swift_3"; echo
# ./123_setup_swift_3.sh
