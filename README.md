 
# CNO<br/>Cloud Native Onboarding 

Onboard, Deploy, Manage and Secure microservices on Kubernetes.

CNO is an open source platform to onboard easily and securely organizational teams on multi-cloud Kubernetes clusters from a single console.

*  [Installation](#Installation)
*  [Configuration](#Configuration)

# Installation

## **Install CNO CLI**

The CLI can be installed with a curl script, brew or by downloading the binary from the releases page. Once installed you'll get the cnoctl command.

## Install with curl:

```
curl -sSL https://raw.githubusercontent.com/beopencloud/cno/main/scripts/cnoctl.sh | sh
```

## Install with brew on MacOs:

```
brew tap beopencloud/cno
```

```
brew install cnoctl
```

## Install from release:

In the cnoctl release page (https://github.com/beopencloud/cno/releases) download, unarchive the version needed and move the binary to your system PATH.

Example for version v0.0.1 on MacOs:

```
wget https://github.com/beopencloud/cno/releases/download/v0.0.1/cnoctl_0.0.1_Darwin_x86_64.tar.gz
```
```
tar -xzf cnoctl_0.0.1_Darwin_x86_64.tar.gz
```
```
mv cnoctl /usr/local/bin/
```

## Verify cnoctl installation

Check that cnoctl is properly installed by getting the command help:

Example for version v0.0.1 on MacOs:

```
cnoctl --help
```

## **Quick CNO Installation with CNOCTL**

To install CNO you need Kubernetes v1.16 or higher.
Once cnoctl is installed, to install CNO run the following command:
```
cnoctl init --type aks --domain cno-dev.beopenit.com --ingress-type nginx
```
The supported flags are:
* --type: The kubernetes in which cno is been install type: vanilla, aks, eks, gke (default "vanilla")
* --domain: The wirldcard domain configured in the cluster
* --ingress-type: The ingress type used in the cluster: nodeport, nginx, router, loadbalancer
* --namespace: cno install namespace (default "cno-system")
* --version: cno version to install (default "1.0.0-rc")
* --with-dataplane: install cno with a default dataplane (default true)
* --psp: is pod policy security enabled on your cluster.

## **CNO Installation with Kustomize**

To install CNO, you need Kubernetes v1.16 or higher. Clone the cno repository:
```
git clone [https://github.com/beopencloud/cno.git](https://github.com/beopencloud/cno.git)
```
Go to the control-plane Kustomize directory:
```
cd deploy/kustomize/control-plane
```
Prerequisites:

Edit the following files for configuration:

1.  Put the api server url of your cluster on base/cno-config.env [REQUIRED]
 ```
vi base/cno-config.env
```
2.  Edit the root password of CNO db base/cno-db-secret.env [OPTIONAL]
  ```
vi base/cno-db-secret.env
```
 
3.  You can set images name/version of CNO’s components if you have a private registry and want to do an installation in disconnected mode [OPTIONAL]
```
vi  base/cno-images-config.env
```
4. Set the CNO admin user password on file base/cno-secret.env [OPTIONAL]
```
vi base/cno-secret.env
```
5.  You must have an ingress or route controller correctly installed and configured
- You must have an ingress or route controller correctly installed and configured
- Edit the following file and set your ingress or route controller domain
```
vi base/cno-ingress-route-config.env
```
6. ONLY FOR LoadBalancer exposition type. [REQUIRED]
- Deploy a service LoadBalancer for cno-api and another for the kafka with the following command
```
kubectl create namespace cno-system
kubectl create -n cno-system -f overlays/loadbalancer/prerequisite.yaml
```
- After that, wait for the allocation of external IPs of the services
```
kubectl -n cno-system get svc
```
- Edit the following file and set the IP addresses of kafka_boostrap and cno-api services
```
vi base/cno-loadbalancer-config.env
```
7. ONLY FOR NodPort exposition type. [REQUIRED]
- Deploy a service NodPort for cno-api and another for the kafka with the following command
```
kubectl create namespace cno-system
kubectl create -n cno-system -f overlays/nodeport/prerequisite.yaml
```
- Get the nodePort of the cno-api and the kafka_boostrap service
```
kubectl -n cno-system get svc
```
- Edit the following file and set an external IP node of your cluster and the nodePort of kafka_boostrap and cno-api services
```
vi base/cno-nodeport-config.env
```
After that you can install cno with this following generic commande.
```
Kubectl apply -k overlays/ingress|loadbalancer|nodeport/psp|no-psp
```
**NB: For Openshift the generic command for installation is:**
```
Kubectl apply -k overlays/openshif/tingress|loadbalancer|nodeport/psp|no-psp
```
Or if your kubectl version is not compatible with the kustomize, you can install the latest version of kustomize with this command.
```
curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
```
And use the following command to install CNO
```
Kustomize build overlays/ingress|loadbalancer|nodeport/psp|no-psp | kubectl apply -f -
```
For example if you want to install CNO with LoadBalancer exposition type on a cluster with Pod Security Policy activated, you have to run the following command:
```
Kubectl apply -k overlays/loadbalancer/psp
Or
kustomize build overlays/loadbalancer/psp | kubectl apply -f -
```
after that wait until the pods are running then connect to the dashboard with the following accesses.
url: 
-  For Ingress or Route exposition type: https://cno.YOUR_DOMAIN
- For Loadbalancer exposition type: [http://external_ip_addr_of_cno-ui_service](http://external_ip_addr_of_cno-ui_service)
-   For NodePort exposition type: http://node_ip:node_port
Username : admin
password : get it on file base/cno-secret.env (default: beopenit)
** NB: For Openshift the generic command for installation is: **
```
Kubectl apply -k overlays/openshif/tingress|loadbalancer|nodeport/psp|no-psp
Or
kustomize build overlays/openshif/ingress|loadbalancer|nodeport/psp|no-psp | kubectl apply -f -
```

# Configuration

## Cloud Providers:
CNO Hub, the hub of Kubernetes clusters, helps you centralize the management, governance, and monitoring of your entire Kubernetes ecosystem. You can register clusters into CNO Hub in two different ways: Standard registration and Cloud-based registration. 

**Standard Registration**, you can add any existing Kubernetes clusters like VMware Tanzu, RedHat OpenShift or Rancher RKE. To do so, go directly to Day 2 Operations with CNO Hub.


**Cloud-based Registration**, CNO Hub can register automatically your Kubernetes clusters from AWS, Azure or GCP. To do so, you need to create cloud providers into CNO first. You can create cloud providers via CNOCTL with the following commands:

#### AWS
```
cnoctl adm create provider eks [name] [--flags]
```
The supported arguments are:
* name: The name of the cloud provider you want to create | [REQUIRED]

The supported flags are:
* --default-region: The region of the provider | [REQUIRED] 
* --access-key: Access key for EKS cloud provider | [REQUIRED]
* --secret-key: Secret key for EKS cloud provider | [REQUIRED]
* --session-token: Session Token for EKS cloud provider | [REQUIRED]

#### AZURE


```cnoctl adm create provider aks [name] [--flags]```

The supported arguments are:
* name: The name of the cloud provider you want to create | [REQUIRED]

The supported flags are:
* --client-id: The client-id for AKS provider | [REQUIRED] 
* --client-secret: The client secret for AKS provider | [REQUIRED]
* --subscription-id: The subscription id for AKS provider | [REQUIRED]
* --tenant-id: The tenant id of the AKS provider | [REQUIRED]

#### GCP


```cnoctl adm create provider gke [name] [--flags]```

The supported arguments are:
* name: The name of the cloud provider you want to create | [REQUIRED]

The supported flags are:
* --json-file: The JSON file that contains the configuration of the GKE provider | [REQUIRED] 

## LDAP Configuration

This section provides how to configure your ldap identity provider to validate usernames and passwords using bind authentication. 

```
cnoctl adm create ldap [--flags ]
```

The supported flags are:
* --url: The URL of your LDAP account | [REQUIRED]
* --Port: The port of the LDAP account (389 for LDAP, 634 for LDAPs)| [REQUIRED]
* --cn: The common name for the LDAP server | [REQUIRED]
* --basedn: The base domain name | [REQUIRED]
* --admin-password: define the LDAP admin password | [REQUIRED]


## Configure Messaging 

To configure SMTP settings to send emails or notifications to CNO users, you have to create a messaging account through CNOCTL.

```
cnoctl adm create smtp [--flags]
```
The supported flags are:
* --email: The sender email of your organization | [REQUIRED]
* --smtp-password: The sender email account password | [REQUIRED]
* --smtp-server:  SMTP address server. | [REQUIRED]
* --smtp-port: The port of the email providers' servers. | [REQUIRED]