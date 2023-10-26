## CNO data-plane helm chart

## Prerequisites
- Kubernetes: 1.20, 1.21, 1.22

- ```shell
   kubectl create namespace cno-system
  ```
## Get Repo Info

```
helm repo add cno-repo https://beopencloud.github.io/cno
helm repo update 
```

## Install Chart CNO data-plane

```
helm install cno cno-repo/cno-agent --namespace cno-system --create-  namespace
```

## Uninstall CNO data-plane

```
helm uninstall cno-agent --namespace cno-system
kubectl delete namespace cno-system
```

## Configuration
```shell
kubectl create secret generic my-licence \
--from-literal=uuid=<uuid licence>
--from-file=user.key=<user.key>
--from-file=user.crt=<user.crt>
--from-file=ca.crt=<ca.crt>
--namespace cno-system
```

- __CNO API infos__

```yaml
global:
  # cno-api config
  cnoAPI:
    protocol: http
    # internalServiceName: cno-api-svc
    externalUrl: api.cno.io
    ...
```

- __Config CNO Agent__

Set metricServer to false if you already have metric server installed in the cluster.

```yaml
cnoAgent:
  metricServer: true
  image:
    name: docker.io/beopenit/cno-agent
    version: v1.0.0
  kafka:
    brokers: <kafka brokers>
  licence:
    secret:
      name: my-licence
```
