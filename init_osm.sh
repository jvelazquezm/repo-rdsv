#!/bin/bash
# Execute as ". init_osm.sh"
# Script to init k8s machine

export OSMNS
export KID

# Get cluster info
KID=$(osm k8scluster-list --literal | grep _id | sed -r 's/.{9}//')
export KID=$(osm k8scluster-list --literal | grep _id | sed -r 's/.{9}//')
sleep 5
# Get namespace
OSMNS=$(osm k8scluster-show --literal $KID | grep -A1 projects_read | sed '1d' | sed -r 's/.{6}//')
export OSMNS=$(osm k8scluster-show --literal $KID | grep -A1 projects_read | sed '1d' | sed -r 's/.{6}//')
sleep 5
#Create k8s repo
osm repo-add --type helm-chart helmchartrepo https://jvelazquezm.github.io/repo-rdsv
sleep 2
#Add OSM Packages
osm nfpkg-create pck/accessknf_vnfd.tar.gz
osm nfpkg-create pck/cpeknf_vnfd.tar.gz
osm nspkg-create pck/renes_ns.tar.gz
sleep 10
#Create renes instance
osm ns-create --ns_name renes1 --nsd_name renes --vim_account dummy_vim
sleep 45
#Save pod names in variables
ACCPOD=$(kubectl get pods -n $OSMNS --no-headers -o custom-columns=":metadata.name" | grep access)
CPEPOD=$(kubectl get pods -n $OSMNS --no-headers -o custom-columns=":metadata.name" | grep cpe)

