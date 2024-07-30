read -t 1  -p "========================= 001_apt_init"; echo
./001_apt_init.sh
read -t 10 -p "========================= 111_setup_cinder_1"; echo
./111_setup_cinder_1.sh
read -t 10 -p "========================= 112_setup_cinder_2"; echo
./112_setup_cinder_2.sh
read -t 10 -p "========================= 113_setup_cinder_3"; echo
./113_setup_cinder_3.sh
read -t 10 -p "========================= 114_setup_cinder_4"; echo
./114_setup_cinder_4.sh
# read -t 10 -p "========================= 121_setup_swift_1"; echo
# ./121_setup_swift_1.sh
# read -t 10 -p "========================= 122_setup_swift_2"; echo
# ./122_setup_swift_2.sh
# read -t 10 -p "========================= 123_setup_swift_3"; echo
# ./123_setup_swift_3.sh
