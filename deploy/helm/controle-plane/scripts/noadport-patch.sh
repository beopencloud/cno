#!/bin/bash

nodeport="";

getNodePort() {
    nodeport="";
    serviceName=$1;
    timeout=300;
    while [ -z $nodeport ] && [ $timeout -gt 0 ]; do
        echo "Waiting for $serviceName endpoint...";
        timeout=$((timeout - 5));
        nodeport=$(kubectl -n ${NAMESPACE} get svc $serviceName -o=jsonpath="{.spec.ports[0].nodePort}" --ignore-not-found);
        [ -z "$nodeport" ] && sleep 10;
    done;
    if [ ! "${timeout}" -gt 0 ];
    then
        echo "timeout to get $serviceName nodePort";
        exit 1;
    fi;
    echo "$serviceName Endpoint ready-" && echo $nodeport;

};



getNodePort cno-api;
kubectl -n ${NAMESPACE} set env deployment cno-api SERVER_URL=http://${NODEPORT_IP_ADDRESS}:$nodeport;
kubectl -n ${NAMESPACE} set env deployment cno-ui API_URL=http://${NODEPORT_IP_ADDRESS}:$nodeport;

getNodePort cno-ui;
kubectl -n ${NAMESPACE} set env deployment cno-api UI_URL=http://${NODEPORT_IP_ADDRESS}:$nodeport;

getNodePort cno-kafka-cluster-kafka-external-bootstrap;
kubectl -n ${NAMESPACE} set env deployment cno-api DEFAULT_EXTERNAL_BROKERS_URL=http://${NODEPORT_IP_ADDRESS}:$nodeport;