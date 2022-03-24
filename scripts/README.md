# Quick Installation

## Prerequisites

Kubernetes **v1.16** or higher is supported by CNO.

**Important** Make sure your kubectl CLI is correctly configured. If you need help to configure Kubernetes environnement, follow [kubectl configuration ](configure-kube.md) documentation.

**Important** If you are a beginner and don't have a Kubernetes cluster ready to use, you can follow [Bootstrap kubernetes Cluster on any cloud provider in 1 minute](bootstrap-kube.md) documentation.


#### Define your Ingress Controller multidomain.


```
export INGRESS_DOMAIN=apps.example.com
```
If your INGRESS_DOMAIN is **apps.example.com**, CNO will create **cno.apps.example.com** ingress ressource.

Your Ingress Controller needs to support SSL passthrough. Most Ingress controllers (NGINX, OpenShift Router and Traefic) support SSL passthrough. Make sure that SSL passthrough parameter is activated in your Kubernetes Ingress Controller or OpenShift Router.

**Important** If you are a beginner and don't have an ingress controller in your Kubernetes  cluster ready to use, you can follow [Install NGINX INGRESS Controller](bootstrap-ingress.md) documentation.

##### AWS Elastic Kubernetes Service (EKS) and Azure Kubernetes Service (AKS)

If you installed CNO in a Kubernetes cluster with PSP (Pod Security Policy) activated such as EKS and AKS, run the following command.

```
export CNO_POD_POLICY_ACTIVITED=true
```

### Install CNO

> if your cluster has PSPs, set the CNO_POD_POLICY_ACTIVITED variable to true before install:

```
export CNO_POD_POLICY_ACTIVITED=true
```

#### 1. install using ingress to expose applications

> You must provide a domain name for the ingress resources

> Replace \<namespace> with the desired target namespace. default is cno-system

```
export INGRESS_DOMAIN=cluster1.beopenit.com"
export CNO_VERSION=1.0.0-rc
curl -sSL https://raw.githubusercontent.com/beopencloud/cno/$CNO_VERSION/scripts/control-plane/install.sh | sh -s -- -n <namespace>
```

#### 2. install using service type LoadBalancer to expose applications

> Replace \<namespace> with the desired target namespace. default is cno-system

```
export CNO_VERSION=1.0.0-rc
curl -sSL https://raw.githubusercontent.com/beopencloud/cno/$CNO_VERSION/scripts/control-plane/install-lb.sh | sh -s -- -n <namespace>
```

#### 3. install using service type NodePort to expose applications

> You must give an address to use as the enpoint for the nodeports eg. LOADBALANCER_IP=x.x.x.x. Could be one of the cluster nodes or a loadbalancer IP.

> Replace \<namespace> with the desired target namespace. default is cno-system

```
export CNO_VERSION=1.0.0-rc
export LOADBALANCER_IP=x.x.x.x
curl -sSL https://raw.githubusercontent.com/beopencloud/cno/$CNO_VERSION/scripts/control-plane/install-nodeport.sh | sh -s -- -n <namespace>
```
####  Enjoy

You can login to your CNO console via cno.$INGRESS_DOMAIN if you installed with ingress, or via the loadbalancer annd odeport addresses.
You will see CNO URL and credentials into post installation outpout.

```
============================================================
  INFO CNO installation success.
     cno.apps.example.com  CNO Credentials USERNAME: admin    PASSWORD: xxxxxxxxxxxxxxxx
============================================================
```

Now you can start onboarding your IT teams, projects and add clusters into CNO HUB.

# Register a cluster into CNO Hub

1. In the CNO Console, go to the clusters Hub page.
2. Select Add Cluster.
3. Enter a name for the cluster.
4. Enter the cluster type (***EKS, AKS , GKE, Kubernetes or OpenShift***) and click on Add Cluster
5. Copy outpout commands and install CNO agent in your new cluster.
