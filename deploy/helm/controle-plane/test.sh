#!/usr/bin/env bash
timeout=300;
external_ip="";
while [ -z $external_ip ] && [ $timeout -gt 0 ]; do
    echo "Waiting for end point...";
    timeout=$((timeout - 5));
    external_ip=$(kubectl -n default get svc cno-ui -o=jsonpath="{.spec.ports[0].nodePort}");
    [ -z "$external_ip" ] && sleep 10;
done;
if [ ! "${timeout}" -gt 0 ];
    then echo "timeout to get loadbalancer IP adress";
    exit 1;
fi;
echo "End point ready-" && echo $external_ip;
#kubectl -n default set env deployment/cno-api SERVER_URL=$external_ip