#!/bin/bash

set -u # to verify variables are defined
: $ACC_EXEC
: $CPE_EXEC


echo $ACC_EXEC
echo $CPE_EXEC

$ACC_EXEC curl -X PUT -d '"tcp:127.0.0.1:6632"' http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr

 

sleep 10

 

$ACC_EXEC curl -X POST -d '{"port_name": "vxlanacc", "type": "linux-htb", "max_rate": "12000000", "queues": [{"max_rate": "4000000"}, {"min_rate": "8000000"}]}' http://localhost:8080/qos/queue/0000000000000001

 


#if [ $1 = "vcpe-1" ]; then

IPH11=$($CPE_EXEC grep -m 1 -B 9 h11 /var/lib/dhcp/dhcpd.leases | grep -m1 "" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
IPH12=$($CPE_EXEC grep -m 1 -B 9 h12 /var/lib/dhcp/dhcpd.leases | grep -m1 "" | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
sleep 10

echo "## 7. Configuracion QoS red residencial"

echo $IPH11
echo $IPH12

$ACC_EXEC curl -X POST -d '{"match": {"nw_dst": "'$IPH11'"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001
$ACC_EXEC curl -X POST -d '{"match": {"nw_dst": "'$IPH12'"}, "actions":{"queue": "0"}}' http://localhost:8080/qos/rules/0000000000000001

#elif [ $1 = "vcpe-2" ]; then
    #IP1=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h21-ip | grep 192.168.255`
    #IP2=`sudo vnx -f vnx/nfv3_home_lxc_ubuntu64.xml -x get-h22-ip | grep 192.168.255`
#       echo -e "\n---------------------------------------------------------"
#      echo -e "Configurando la QoS de la red residencial 2"
#       echo -e "---------------------------------------------------------"
#   sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.7"}, "actions":{"queue": "0"}}' http://localhost:8080/qos/rules/0000000000000001
#   sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "192.168.255.8"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001
#fi

 

#sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "'$IP1'"}, "actions":{"queue": "0"}}' http://localhost:8080/qos/rules/0000000000000001
#sudo docker exec -it $VNF1 curl -X POST -d '{"match": {"nw_dst": "'$IP2'"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001

 

#echo -e "\n-------------------------------------------------------------"
#echo "Reglas configuradas en $1"
#sudo docker exec -it $VNF1 bin/bash -c "curl -X GET http://localhost:8080/qos/queue/0000000000000001 > $1.json"
#echo -e "\n-------------------------------------------------------------"
#sudo docker exec -it $VNF1 bin/bash -c "cat $1.json || jq"
#echo -e "\n"