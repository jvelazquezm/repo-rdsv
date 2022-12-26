#!/bin/bash

# Script to init k8s machine

# MTU config
sudo ip link set dev eth1 mtu 1400

# Repo download
# mkdir shared
# cd shared
# git clone https://github.com/jvelazquezm/repo-rdsv.git
# cd repo-rdsv

#Private repository configuration

microk8s enable registry
sudo echo -e '{\n"insecure-registries" : ["192.168.56.11:32000"]\n}' | sudo tee -a /etc/docker/daemon.json
sudo systemctl restart docker

cd img/vnf-img/
docker build . -t 192.168.56.11:32000/vnf-img-private:latest
cd ../..
docker push 192.168.56.11:32000/vnf-img-private:latest

sudo sed  '/\[plugins."io.containerd.grpc.v1.cri".registry.mirrors]/a \ \ \ \ \ \ \[plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.56.11:32000"]\n        endpoint = ["http://192.168.56.11:32000"]' /var/snap/microk8s/current/args/containerd-template.toml >> tmp
sudo cp tmp /var/snap/microk8s/current/args/containerd-template.toml
sudo rm tmp

microk8s stop
microk8s start

# Run the residential net scenario
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -t
# Run the server scenario
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -t
xhost +