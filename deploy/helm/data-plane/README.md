## CNO data-plane helm chart

### Requirements
- Kubernetes: 1.20, 1.21, 1.22

```shell
kubectl create namespace cno-system
```
### Configuration
```shell
kubectl create secret generic my-licence \
--from-literal=uuid=<uuid licence>
--from-file=user.key=<user.key>
--from-file=user.crt=<user.crt>
--from-file=ca.crt=<ca.crt>
--namespace cno-system
```

#### Config CNO API infos

```yaml
global:
  # cno-api config
  cnoAPI:
    protocol: http
    # internalServiceName: cno-api-svc
    externalUrl: api.cno.io
    ...
```

#### Config CNO Agent
Set metricServer to false if you already have metric server installed in the cluster.

```yaml
cnoAgent:
  metricServer: true
  image:
    name: docker.io/beopenit/cno-agent
    version: 1.0.0-rc
  kafka:
    brokers: <kafka brokers>
  licence:
    secret:
      name: my-licence
```

#### Install CNO data-plane

```yaml
git clone https://github.com/beopencloud/cno.git
cd cno/deploy/helm/control-plane
helm install cno-agent ./ --namespace cno-system
```
#### Uninstall CNO data-plane

```
helm uninstall cno-agent --namespace cno-system
kubectl delete namespace cno-system
```
