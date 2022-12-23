#!/bin/bash

# Requires the following variables
# KUBECTL: kubectl command
# OSMNS: OSM namespace in the cluster vim
# VACC: "pod_id" or "deploy/deployment_id" of the access vnf
# VCPE: "pod_id" or "deploy/deployment_id" of the cpd vnf
# HOMETUNIP: the ip address for the home side of the tunnel
# VNFTUNIP: the ip address for the vnf side of the tunnel
# VCPEPUBIP: the public ip address for the vcpe
# VCPEGW: the default gateway for the vcpe

set -u # to verify variables are defined
: $KUBECTL
: $OSMNS
: $VACC
: $VCPE
: $VARP
: $HOMETUNIP
: $VNFTUNIP
: $VCPEPUBIP
: $VCPEGW

if [[ ! $VACC =~ "helmchartrepo-accesschart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <access_deployment_id>: $VACC"
    exit 1
fi

if [[ ! $VCPE =~ "helmchartrepo-cpechart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <cpe_deployment_id>: $VCPE"
    exit 1
fi

if [[ ! $VARP =~ "helmchartrepo-arpwatchchart"  ]]; then
    echo ""       
    echo "ERROR: incorrect <arpwatch_deployment_id>: $VARP"
    exit 1
fi

ACC_EXEC="$KUBECTL exec -n $OSMNS $VACC --"
CPE_EXEC="$KUBECTL exec -n $OSMNS $VCPE --"
ARP_EXEC="$KUBECTL exec -n $OSMNS $VARP --"

# Router por defecto en red residencial
VCPEPRIVIP="192.168.255.1"

# Router por defecto inicial en k8s (calico)
K8SGW="169.254.1.1"

## 1. Obtener IPs de las VNFs
echo "## 1. Obtener IPs de las VNFs"
IPACCESS=`$ACC_EXEC hostname -I | awk '{print $1}'`
echo "IPACCESS = $IPACCESS"
IPCPE=`$CPE_EXEC hostname -I | awk '{print $1}'`
echo "IPCPE = $IPCPE"
IPARP=`$ARP_EXEC hostname -I | awk '{print $1}'`
echo "IPCPE = $IPARP"

## 2. Iniciar el Servicio OpenVirtualSwitch en cada VNF:
echo "## 2. Iniciar el Servicio OpenVirtualSwitch en cada VNF"
$ACC_EXEC service openvswitch-switch start
$CPE_EXEC service openvswitch-switch start
$ARP_EXEC service openvswitch-switch start

## 3. En VNF:access agregar un bridge y configurar IPs y rutas
echo "## 3. En VNF:access agregar un bridge y configurar IPs y rutas"

echo "## 3.1 Configurar controlador ryu con QoS"
$ACC_EXEC ovs-vsctl add-br brint
$ACC_EXEC ovs-vsctl set bridge brint protocols=OpenFlow13
$ACC_EXEC ovs-vsctl set-fail-mode brint secure
$ACC_EXEC ovs-vsctl set bridge brint other-config:datapath-id=0000000000000001
$ACC_EXEC ovs-vsctl set-controller brint tcp:127.0.0.1:6633
$ACC_EXEC ovs-vsctl set-manager ptcp:6632
$ACC_EXEC ryu-manager ryu.app.rest_qos ryu.app.rest_conf_switch /usr/lib/python3/dist-packages/ryu/app/qos_simple_switch_13.py &

echo "## 3.2 Configurar IPs y rutas"
$ACC_EXEC ifconfig net1 $VNFTUNIP/24
$ACC_EXEC ip link add vxlanacc type vxlan id 0 remote $HOMETUNIP dstport 4789 dev net1
$ACC_EXEC ip link add vxlanint1 type vxlan id 1 remote $IPARP dstport 8742 dev eth0
$ACC_EXEC ovs-vsctl add-port brint vxlanacc
$ACC_EXEC ovs-vsctl add-port brint vxlanint1
$ACC_EXEC ifconfig vxlanacc up
$ACC_EXEC ifconfig vxlanint1 up
$ACC_EXEC ip route add $IPARP/32 via $K8SGW

## 4. Tuneles ARP
echo "## 4. Configurar tuneles ARP"


$ARP_EXEC ovs-vsctl add-br brint

$ARP_EXEC ip link add vxlanint1 type vxlan id 1 remote $IPACCESS dstport 8742 dev eth0
$ARP_EXEC ip link add vxlanint2 type vxlan id 2 remote $IPCPE dstport 8742 dev eth0
$ARP_EXEC ovs-vsctl add-port brint vxlanint1
$ARP_EXEC ovs-vsctl add-port brint vxlanint2
$ARP_EXEC ifconfig vxlanint1 up
$ARP_EXEC ifconfig vxlanint2 up
$ARP_EXEC ip route add $IPACCESS/32 via $K8SGW
$ARP_EXEC ip route add $IPCPE/32 via $K8SGW


## 5. En VNF:cpe agregar un bridge y configurar IPs y rutas
echo "## 5. En VNF:cpe agregar un bridge y configurar IPs y rutas"
$CPE_EXEC ovs-vsctl add-br brint
$CPE_EXEC ifconfig brint $VCPEPRIVIP/24
$CPE_EXEC ovs-vsctl add-port brint vxlanint2 -- set interface vxlanint2 type=vxlan options:remote_ip=$IPARP options:key=2 options:dst_port=8742
$CPE_EXEC ifconfig brint mtu 1400
$CPE_EXEC ifconfig net1 $VCPEPUBIP/24
$CPE_EXEC ip route add $IPARP/32 via $K8SGW
$CPE_EXEC ip route del 0.0.0.0/0 via $K8SGW
$CPE_EXEC ip route add 0.0.0.0/0 via $VCPEGW

## 6. Configurar arpwatch
echo "## 6. Configurar arpwatch"
$ARP_EXEC sed -i '24c\INTERFACES="eth0"' /etc/default/arpwatch
$ARP_EXEC /etc/init.d/arpwatch start

$CPE_EXEC sed -i '24c\INTERFACES="brint net1 eth0"' /etc/default/arpwatch
$CPE_EXEC /etc/init.d/arpwatch start

## 7. En VNF:cpe iniciar Servidor DHCP
echo "## 7. En VNF:cpe iniciar Servidor DHCP"
$CPE_EXEC sed -i 's/homeint/brint/' /etc/default/isc-dhcp-server
$CPE_EXEC service isc-dhcp-server restart

## 8. En VNF:cpe activar NAT para dar salida a Internet
echo "## 8. En VNF:cpe activar NAT para dar salida a Internet"
$CPE_EXEC /usr/bin/vnx_config_nat brint net1