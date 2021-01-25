## CNO, Cloud Native Onboarding.
Onboard, Deploy, Manage and Secure microservices on Kubernetes.

* [Get Started]()
* [ Architecture](#Architecture)
* [Component](#Component)
* [Installation](#Installation)
* [Contributing](#Contributing)
## Get Started

CNO (Cloud Native Onboarding) is an open source platform to onboard easily and securely development teams on multi-cloud Kubernetes clusters from a single console.

## Architecture
CNO Architecture ![Architecture](/image/architecture.png)
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
1. Execute this commande
```
curl -L https://raw.githubusercontent.com/beopencloud/releases/v0.0.0/release0.sh | sh -
```

## Contributing
To Contribute to the CNO project, please follow this [Contributor's Guide](https://github.com/beopencloud/cno/tree/main/contributor_guide)


