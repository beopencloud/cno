## BOOR data-plane helm chart

## Prerequisites
- Kubernetes: 1.20, 1.21, 1.22

- ```shell
   kubectl create namespace boor-system
  ```
## Get Repo Info

```
helm repo add boor-repo https://beopencloud.github.io/boor
helm repo update 
```

## Install Chart BOOR data-plane

```
helm install boor boor-repo/boor-agent --namespace boor-system --create-  namespace
```

## Uninstall BOOR data-plane

```
helm uninstall boor-agent --namespace boor-system
kubectl delete namespace boor-system
```

## Configuration
```shell
kubectl create secret generic my-licence \
--from-literal=uuid=<uuid licence>
--from-file=user.key=<user.key>
--from-file=user.crt=<user.crt>
--from-file=ca.crt=<ca.crt>
--namespace boor-system
```

- __BOOR API infos__

```yaml
global:
  # boor-api config
  boorAPI:
    protocol: http
    # internalServiceName: boor-api-svc
    externalUrl: api.boor.io
    ...
```

- __Config BOOR Agent__

Set metricServer to false if you already have metric server installed in the cluster.

```yaml
boorAgent:
  metricServer: true
  image:
    name: docker.io/beopenit/boor-agent
    version: v1.0.0
  kafka:
    brokers: <kafka brokers>
  licence:
    secret:
      name: my-licence
```
