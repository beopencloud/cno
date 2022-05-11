#!/usr/bin/env bash

external_uri="";

getLoadBalancerIp() {

    serviceName=$1;
    timeout=300;
    external_uri="";
    while [ -z $external_uri ] && [ $timeout -gt 0 ]; do
        echo "Waiting for $serviceName endpoint...";
        timeout=$((timeout - 5));
        external_uri=$(kubectl -n ${NAMESPACE} get svc $serviceName -o=jsonpath="{.status.loadBalancer.ingress[0].ip}" --ignore-not-found);
        [ -z "$external_uri" ] && external_uri=$(kubectl -n ${NAMESPACE} get svc $serviceName -o=jsonpath="{.status.loadBalancer.ingress[0].hostname}" --ignore-not-found);
        [ -z "$external_uri" ] && external_uri=$(kubectl -n ${NAMESPACE} get svc $serviceName -o=jsonpath="{.spec.externalIPs[0]}" --ignore-not-found);
        [ -z "$external_uri" ] && sleep 10;
    done;
    if [ ! "${timeout}" -gt 0 ];
    then
        echo "timeout to get $serviceName loadbalancer IP adress";
        exit 1;
    fi;
    echo "$serviceName Endpoint ready-" && echo $external_uri;

}

getLoadBalancerIp cno-api;
kubectl -n ${NAMESPACE} set env deployment cno-api SERVER_URL=http://$external_uri;
kubectl -n ${NAMESPACE} set env deployment cno-ui API_URL=http://$external_uri;

getLoadBalancerIp cno-ui;
kubectl -n ${NAMESPACE} set env deployment cno-api UI_URL=http://$external_uri;

getLoadBalancerIp cno-kafka-cluster-kafka-external-bootstrap;
kubectl -n ${NAMESPACE} set env deployment cno-api DEFAULT_EXTERNAL_BROKERS_URL=$external_uri:9094;
