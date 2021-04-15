#!/usr/bin/env bash

# source https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-manifests/

kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/ns-and-sa.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/rbac/rbac.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/rbac/ap-rbac.yaml

kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/default-server-secret.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/nginx-config.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/ingress-class.yaml

kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/crds/k8s.nginx.org_virtualservers.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/crds/k8s.nginx.org_virtualserverroutes.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/crds/k8s.nginx.org_transportservers.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/crds/k8s.nginx.org_policies.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/crds/k8s.nginx.org_globalconfigurations.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/global-configuration.yaml
kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/deployment/nginx-ingress.yaml

if [ "${IS_AN_EKS_CLUSTER}" = "true" ]
then
    kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/service/loadbalancer-aws-elb.yaml
    curl https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/common/nginx-config.yaml > /tmp/cno-ingress-configmap; echo "  proxy-protocol: \"True\"" >> /tmp/cno-ingress-configmap ; echo "  real-ip-header: \"proxy_protocol\"" >> /tmp/cno-ingress-configmap ; echo "  set-real-ip-from: \"0.0.0.0/0\"" >> /tmp/cno-ingress-configmap
    kubectl apply -f /tmp/cno-ingress-configmap
    rm /tmp/cno-ingress-configmap
else
    kubectl apply -f https://raw.githubusercontent.com/nginxinc/kubernetes-ingress/v1.11.1/deployments/service/loadbalancer.yaml
fi