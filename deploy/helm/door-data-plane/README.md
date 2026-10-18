## DOOR data-plane helm chart

## Prerequisites
- Kubernetes: 1.20, 1.21, 1.22

- ```shell
   kubectl create namespace door-system
  ```
## Get Repo Info

```
helm repo add door-repo https://beopencloud.github.io/cno
helm repo update 
```

## Install Chart DOOR data-plane

```
helm install door door-repo/door-agent --namespace door-system --create-  namespace
```

## Uninstall DOOR data-plane

```
helm uninstall door-agent --namespace door-system
kubectl delete namespace door-system
```

## Configuration
```shell
kubectl create secret generic my-licence \
--from-literal=uuid=<uuid licence>
--from-file=user.key=<user.key>
--from-file=user.crt=<user.crt>
--from-file=ca.crt=<ca.crt>
--namespace door-system
```

- __DOOR API infos__

```yaml
global:
  # door-api config
  doorAPI:
    protocol: http
    # internalServiceName: door-api-svc
    externalUrl: api.door.io
    ...
```

- __Config DOOR Agent__

Set metricServer to false if you already have metric server installed in the cluster.

```yaml
doorAgent:
  metricServer: true
  image:
    name: docker.io/beopenit/door-agent
    version: v1.0.0
  kafka:
    brokers: <kafka brokers>
  licence:
    secret:
      name: my-licence
```

- __Optional door-agent settings (v3.0.16)__

All of them default to the previous rendering.

```yaml
doorAgent:
  # defaultCluster=true only: set to false to drop the door-api-check initContainer
  # (door-api not deployed in this cluster).
  waitForDoorApi: true
  # Scheduling of the door-agent Deployment, rendered only when set.
  nodeSelector:
    workload-tier: heavy
  tolerations: []
  affinity: {}
  kafka:
    # Secrets of the kafka-user and kafka-ca volumes. Empty keeps the historical names
    # (door-kafka-superadmin / the licence Secret when defaultCluster=false, and
    # door-kafka-cluster-cluster-ca-cert).
    userSecret: door-agent-do-kafka-user
    caSecret: door-agent-do-kafka-ca
```
