# CNO helm chart

## Install CNO Control plane
```
helm repo add cno-repo https://beopencloud.github.io/cno
helm install cno cno-repo/cno -f values.yaml
```
## Values sample
```
cluster:
# kubernetes or openshift
  platform: kubernetes
# kubernetes api-server url
  apiUrl: https://kubernetes-api-server-url
expose:
# values: loadbalancer, nodeport, route or nginx-ingress
  type: nginx-ingress
# set if expose equal to route or nginx-ingress
  ingress:
    domain: dev.gocno.io
superadmin:
  password: admin
agentConfig:
  # cluster type eks, aks, gke, vanilla
  defaultClusterType: EKS
  cnoAgent:
    metricServer: true
```
