#!/bin/bash

# Script to init k8s machine

# MTU config
sudo ip link set dev eth1 mtu 1400

# Repo download
mkdir shared
cd shared
git clone https://github.com/jvelazquezm/repo-rdsv.git
cd repo-rdsv

# Run the residential net scenario
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -t
# Run the server scenario
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
xhost +