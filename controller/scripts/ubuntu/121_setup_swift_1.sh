#!/usr/bin/env bash

set -o errexit -o nounset

TOP_DIR=$(cd $(cat "../TOP_DIR" 2>/dev/null||echo $(dirname "$0"))/.. && pwd)

source "$TOP_DIR/config/paths"
source "$CONFIG_DIR/credentials"
source "$LIB_DIR/functions.guest.sh"

exec_logfile

indicate_current_auto

#------------------------------------------------------------------------------
# Set up Block Storage service controller (cinder controller node)
#------------------------------------------------------------------------------

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Install components
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

echo "Installing Swift."
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall swift swift-account 
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall swift-container swift-object xfsprogs 
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall python3-swift python3-swiftclient
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall python3-keystoneclient python3-keystonemiddleware
sudo apt install -y -o DPkg::options::=--force-confmiss --reinstall swift-proxy python3-memcache

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Obtain the proxy service configuration file from the Object Storage repository
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

if [ -d "/etc/swift/" ]
then
   sudo chmod 777 /etc/swift/
#    sudo curl -o /etc/swift/swift.conf https://opendev.org/openstack/swift/raw/branch/unmaintained/yoga/etc/swift.conf-sample
   sudo cp "$CONFIG_DIR/swift.conf-sample" /etc/swift/swift.conf
   sudo chgrp swift /etc/swift/swift.conf
   sudo chmod 640 /etc/swift/swift.conf
else
   sudo mkdir /etc/swift/
   sudo chmod -R 777 /etc/swift/
#    sudo curl -o /etc/swift/swift.conf https://opendev.org/openstack/swift/raw/branch/unmaintained/yoga/etc/swift.conf-sample
   sudo cp "$CONFIG_DIR/swift.conf-sample" /etc/swift/swift.conf
   sudo chgrp swift /etc/swift/swift.conf
   sudo chmod 640 /etc/swift/swift.conf
fi

# sudo curl -o /etc/swift/proxy-server.conf https://opendev.org/openstack/swift/raw/branch/unmaintained/yoga/etc/proxy-server.conf-sample
sudo cp "$CONFIG_DIR/proxy-server.conf-sample" /etc/swift/proxy-server.conf
sudo chgrp swift /etc/swift/proxy-server.conf
sudo chmod 640 /etc/swift/proxy-server.conf``
