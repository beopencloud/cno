

# Nginx Ingress Controller


**Important** CNO is designed to work with all Ingress Controllers installed in a Production way.  It means you should have an external IP allocated to the ingress-controller which receive all HTTP incoming requests. Then, you should attach a DNS multidomain zone (e.g. *.apps.exmaple.com) to the Ingress Controller external IP. Finally you should create a wildcard certificate *.apps.exmaple.com.  


## Create ingress-system namespace
```
kubectl create ns ingress-system
```

## Intallation

Here is a minimal NGINX Ingress controller instllation with helm. To install helm, follow [Helm documentaion](https://helm.sh/docs/intro/install/).

```
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx --set controller.setAsDefaultIngress=true -n ingress-system
```

Don't forget to configure correctly [your wildcard certificate and enable SSL passthrough](https://kubernetes.github.io/ingress-nginx/user-guide/tls/).
