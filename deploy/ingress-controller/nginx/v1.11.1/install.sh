#!/usr/bin/env bash

if [ "${IS_AN_EKS_CLUSTER}" = "true" ]
then
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.45.0/deploy/static/provider/aws/deploy.yaml
else
    kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.45.0/deploy/static/provider/cloud/deploy.yaml
fi
kubectl -n ingress-nginx patch deployments ingress-nginx-controller --type "json" -p '[{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"report-ingress-status"},{"op":"add","path":"/spec/template/spec/containers/0/args/-","value":"external-service ingress-nginx-controller"}]'