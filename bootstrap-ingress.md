# Nginx Ingress Controller

**Important** CNO is designed to work with all Ingress Controllers installed in a Production way:

1. You should have an external IP allocated to the ingress controller that receives all HTTP incoming requests.
2. You should attach a DNS multidomain zone (e.g., *.apps.exmaple.com) to the Ingress Controller external IP.
3. You should create a wildcard certificate *.apps.exmaple.com.

## Create ingress-nginx namespace

```
kubectl create ns ingress-nginx
```

## Intallation

Here is a minimal NGINX Ingress controller installation with helm. To install helm, follow [Helm documentaion](https://helm.sh/docs/intro/install/).

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.setAsDefaultIngress=true -n ingress-nginx
```

Don't forget to configure correctly [your wildcard certificate and enable SSL passthrough](https://kubernetes.github.io/ingress-nginx/user-guide/tls/).
