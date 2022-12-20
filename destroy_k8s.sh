#!/bin/bash

# Destroy the residential net scenario
sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -P
# Destroy the server scenario
sudo vnx -f vnx/nfv3_server_lxc_ubuntu64.xml -P

