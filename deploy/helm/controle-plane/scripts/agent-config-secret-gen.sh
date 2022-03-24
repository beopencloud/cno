#!/usr/bin/env bash

waitForResourceCreated() {

    echo "waiting for resource $1 $2 ...";
    timeout=600;
    resource="";
    while [ -z $resource ] && [ $timeout -gt 0 ]; do
       resource=$(kubectl -n $NAMESPACE get $1 $2 -o jsonpath="{.metadata.name}" --ignore-not-found);
       timeout=$((timeout - 5));
       sleep 5s;
       if [ -z "${resource}" ];
       then
           printf "...";
       fi;
    done;
    if [ ! "${timeout}" -gt 0 ]; then
        echo "timeout: $1 $2 not found";
        exit 1;
    fi;
    echo "$1 $2 successfully deployed";

}

waitForResourceCreated secret cno-kafka-cluster-cluster-ca-cert;

waitForResourceCreated secret $DEFAULT_CLUSTER_ID;

kubectl -n $NAMESPACE get secret/cno-kafka-cluster-cluster-ca-cert -o jsonpath="{.data.ca\.crt}" | base64 -d > /tmp/cno-ca;
kubectl -n $NAMESPACE get secret/$DEFAULT_CLUSTER_ID -o jsonpath="{.data.user\.key}" | base64 -d > /tmp/cno-kafka-key;
kubectl -n $NAMESPACE  get secret/$DEFAULT_CLUSTER_ID -o jsonpath="{.data.user\.crt}" | base64 -d > /tmp/cno-kafka-cert;
kubectl -n $NAMESPACE delete secret cno-agent-config;
kubectl -n $NAMESPACE create secret generic cno-agent-config --from-literal=licence=$DEFAULT_CLUSTER_ID --from-file=caFile=/tmp/cno-ca --from-file=certFile=/tmp/cno-kafka-cert --from-file=keyFile=/tmp/cno-kafka-key;
kubectl -n $NAMESPACE annotate --overwrite=true secret cno-agent-config meta.helm.sh/release-namespace=$NAMESPACE;
kubectl -n $NAMESPACE annotate --overwrite=true secret cno-agent-config meta.helm.sh/release-name=$RELEASE_NAME;
kubectl -n $NAMESPACE label --overwrite=true secret cno-agent-config app.kubernetes.io/managed-by=Helm;
kubectl -n $NAMESPACE delete pod -l run=cno-agent
