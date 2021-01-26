## CNO, Cloud Native Onboarding.
Onboard, Deploy, Manage and Secure microservices on Kubernetes.

* [Get Started]()
* [Prerequistes](#Prerequistes)
* [Architecture](#Architecture)
* [Component](#Component)
* [Installation](#Installation)
* [Contributing](#Contributing)
## Get Started

CNO (Cloud Native Onboarding) is an open source platform to onboard easily and securely development teams on multi-cloud Kubernetes clusters from a single console.

## Prerequistes
1. [Install Helm](https://helm.sh/docs/intro/install/)
2. [Install go](https://golang.org/doc/install) v1.14+
3. [Install docker](https://docs.docker.com/engine/install/ubuntu/) v17.03+
4. [Install kubectl](https://kubernetes.io/fr/docs/tasks/tools/install-kubectl/) v1.14.1+

## Architecture
CNO Architecture ![Architecture](/image/externals.png)
## Component
CNO is an open source project mainly composed of 7 modules.
1. [cno UI](https://github.com/beopencloud/cno-ui-template)
2. [cno API](https://github.com/beopencloud/cno-api)
3. [cno Agent](https://github.com/beopencloud/cno-agent)
4. [cno Openshift-operator](https://github.com/beopencloud/cno-openshift-operator)
5. [cno CD-operator](https://github.com/beopencloud/cno-cd)
6. [cno K8s-operator](https://github.com/beopencloud/cno-kubernetes-operator)
7. [cno Notification](https://github.com/beopencloud/cno-notification)
7. [cno Client](https://github.com/beopencloud/cnoctl)
## Clone this project
```
git clone https://github.com/beopencloud/cno.git
cd cno
```
## Installation
### Installation Community Mode
#### 1. Installing kafka
#####   Installing kafka operator
```
kubectl create namespace cno
kubectl apply -f ./files/kafkaStrimzi/crds/kafkaOperator.yaml -n cno
```
##### Deploying a kafka cluster
```
kubectl apply -f ./deploy/kafka/kafka.yaml
```
##### Creating the onboarding super-admin
```
kubectl apply -f ./deploy/kafka/onboardingSuperAdmin.yaml
```
#### 2. Installing Keycloak
##### Installing keycloak Operator 
``` 
kubectl apply -f ./deploy/keycloak/crds/ -n cno
```
##### Deploying keycloak Cluster
```
kubectl apply -f ./deploy/keycloak/keycloak.yaml
```
#### 3. Installing MysqlDB
##### Create the DataBase and the Service
```
kubectl apply -f ./deploy/mysqlDB/mysqlDB.yaml
``` 
##### Create PVC that will associated
```
kubectl apply -f ./deploy/mysqlDB/pvc.yaml
```
#### 4. Installing CNO Operator
##### Deploying using the cno operator image
```
kubectl apply -f ./deploy/operator/cnoOperator/
```
##### Creating a Cluster Role(+binding)
```
kubectl apply -f ./deploy/operator/templates/
```
#### Installing Mysql Operator
```
helm repo add presslabs https://presslabs.github.io/charts
helm install --name mysql-operator presslabs/mysql-operator 
```
#### Installing CNO API
```
kubectl apply -f ./deploy/onboarding-api/onboarding-api.yaml
```
#### Installing CNO UI
```
kubectl apply -f ./deploy/onboarding-ui/onboarding-ui.yaml
```




### Installation CNO via Helm
##### 1. Installation
```bash
helm install cno .
```
##### 2. Checks
```bash
helm get manifest cno
```
### Installation via CNO Operator
1. Execute this command
```
curl -L https://raw.githubusercontent.com/beopencloud/releases/v0.0.0/release0.sh | sh -
```

## Contributing
To Contribute to the CNO project, please follow this [Contributor's Guide](https://github.com/beopencloud/cno/tree/main/contributor_guide)


