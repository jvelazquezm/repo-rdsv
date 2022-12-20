#!/bin/bash

export KUBECTL="kubectl"

deployment_id() {
    echo `osm ns-list | grep $1 | awk '{split($0,a,"|");print a[3]}' | xargs osm vnf-list --ns | grep $2 | awk '{split($0,a,"|");print a[2]}' | xargs osm vnf-show --literal | grep name | grep $2 | awk '{split($0,a,":");print a[2]}' | sed 's/ //g'`
}

OSMACC=$(deployment_id $1 "access")
OSMCPE=$(deployment_id $1 "cpe")
echo $OSMACC
echo $OSMCPE

export VACC="deploy/$OSMACC"
export VCPE="deploy/$OSMCPE"

ACC_EXEC="$KUBECTL exec -n $OSMNS $VACC --"
CPE_EXEC="$KUBECTL exec -n $OSMNS $VCPE --"


if [ $1 = "renes1" ]; then

    $ACC_EXEC curl -X PUT -d '"tcp:10.255.0.2:6632"' http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr

    sleep 10

    $ACC_EXEC curl -X POST -d '{"port_name": "vxlanint", "type": "linux-htb", "max_rate": "6000000", "queues": [{"max_rate": "2000000"}, {"min_rate": "4000000"}]}' http://localhost:8080/qos/queue/0000000000000001

    IPH11=$($CPE_EXEC dhcp-lease-list | grep h11 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
    IPH12=$($CPE_EXEC dhcp-lease-list | grep h12 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
    
    sleep 10

    echo "## 7. Configuracion QoS red residencial 1"

    echo $IPH11
    echo $IPH12

    $ACC_EXEC curl -X POST -d '{"match": {"nw_src": "'$IPH11'"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001
    $ACC_EXEC curl -X POST -d '{"match": {"nw_src": "'$IPH12'"}, "actions":{"queue": "0"}}' http://localhost:8080/qos/rules/0000000000000001

elif [ $1 = "renes2" ]; then

    $ACC_EXEC curl -X PUT -d '"tcp:10.255.0.4:6632"' http://localhost:8080/v1.0/conf/switches/0000000000000001/ovsdb_addr

    sleep 10

    $ACC_EXEC curl -X POST -d '{"port_name": "vxlanint", "type": "linux-htb", "max_rate": "6000000", "queues": [{"max_rate": "2000000"}, {"min_rate": "4000000"}]}' http://localhost:8080/qos/queue/0000000000000001

    IPH21=$($CPE_EXEC dhcp-lease-list | grep h21 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
    IPH22=$($CPE_EXEC dhcp-lease-list | grep h22 | grep -E -o "([0-9]{1,3}[\.]){3}[0-9]{1,3}")
    sleep 10

    echo "## 7. Configuracion QoS red residencial 2"

    echo $IPH21
    echo $IPH22

    $ACC_EXEC curl -X POST -d '{"match": {"nw_src": "'$IPH21'"}, "actions":{"queue": "1"}}' http://localhost:8080/qos/rules/0000000000000001
    $ACC_EXEC curl -X POST -d '{"match": {"nw_src": "'$IPH22'"}, "actions":{"queue": "0"}}' http://localhost:8080/qos/rules/0000000000000001
fi