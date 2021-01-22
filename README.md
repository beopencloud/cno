* [Get Started]()
* [ Architecture](#Architecture)
* [Component](#Component)
* [Installing](#Installing)
* [Contributing](#Contributing)
## Get Started
Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.
## Architecture
CNO Architecture ![Architecture](/image/architecture.png)
## Component
CNO is an open source project mainly composed of 7 modules.
1. [cno UI](https://gitlab.beopenit.com/cloud/onboarding-ui)
2. [cno API](https://gitlab.beopenit.com/cloud/onboarding-api)
3. [cno Agent](https://gitlab.beopenit.com/cloud/cno-agent)
4. [cno Openshift-operator](https://gitlab.beopenit.com/cloud/onboarding-operator-openshift)
5. [cno CD-operator](https://gitlab.beopenit.com/cloud/cno-cd)
6. [cno K8s-operator](https://gitlab.beopenit.com/cloud/onboarding-operator-kubernetes)
7. CLI
## Installing
### Installation Community Mode
#### Installing kafka
##### Installing kafka operator
```
kubectl create namespace kafka
kubectl apply -f ./files/kafkaStrimzi/crds/kafkaOperator.yaml -n kafka
```
##### Deploying a kafka cluster
```
kubectl apply -f ./deploy/kafka/kafka.yaml
```
##### Creating the onboarding super-admin
```
kubectl apply -f ./deploy/kafka/onboardingSuperAdmin.yaml
```
#### Installing Keycloak
##### Installing keycloak Operator 
kubectl apply -f ./files/keycloak/crds/ -n keycloak
##### Deploying keycloak Cluster
```
kubectl apply -f ./deploy/keycloak/keycloak.yaml
```
#### Installing MysqlDB
##### Create the DataBase and the Service
```
kubectl apply -f ./deploy/mysqlDB/mysqlDB.yaml
``` 
##### Create PVC that will associated
```
kubectl apply -f ./deploy/mysqlDB/pvc.yaml
```
#### Installing CNO API
```

```
#### Installing CNO UI
```

```
#### Installing CNO Notification
```

```




### Installing CNO via Helm
1. Installation
```bash
helm install cno .
```
2. Checks
```bash
helm get manifest cno
```

## Contributing
To Contribute to the CNO project, please follow this [Contributor's Guide](https://github.com/beopencloud/cno/tree/main/contributor_guide)


