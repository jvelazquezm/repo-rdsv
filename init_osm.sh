#!/bin/bash
# Execute as ". init_osm.sh"
# Script to init k8s machine

export OSMNS
export KID

# MTU config
sudo ip link set dev eth1 mtu 1400

# Repo download
#mkdir shared
#cd shared
#git clone https://github.com/jvelazquezm/repo-rdsv.git
#cd repo-rdsv

# Get cluster info
KID=$(osm k8scluster-list --literal | grep _id | sed -r 's/.{9}//')
export KID=$(osm k8scluster-list --literal | grep _id | sed -r 's/.{9}//')
sleep 10

# Get namespace
OSMNS=$(osm k8scluster-show --literal $KID | grep -A1 projects_read | sed '1d' | sed -r 's/.{6}//')
export OSMNS=$(osm k8scluster-show --literal $KID | grep -A1 projects_read | sed '1d' | sed -r 's/.{6}//')
sleep 10

#Create k8s repo
osm repo-add --type helm-chart helmchartrepo https://jvelazquezm.github.io/repo-rdsv
sleep 2

#Add OSM Packages
osm nfpkg-create pck/accessknf_vnfd.tar.gz
osm nfpkg-create pck/cpeknf_vnfd.tar.gz
osm nfpkg-create pck/arpwatchknf_vnfd.tar.gz
osm nspkg-create pck/renes_ns.tar.gz
sleep 10

#Create renes instance
osm ns-create --ns_name renes1 --nsd_name renes --vim_account dummy_vim
osm ns-create --ns_name renes2 --nsd_name renes --vim_account dummy_vim
sleep 45

