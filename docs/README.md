# Cno helm chart

# Install CNO Control plane
```
helm repo add cno-repo https://github.com/beopencloud/cno/tree/release/v1.0.0/deploy/helm/releases
helm install cno cno-repo/cno -f values.yaml
```
