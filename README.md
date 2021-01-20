* [Get Started]()
* [ Architecture](#Architecture)
* [Component](#Component)
    - [cno UI](#cno_UI)
    - [cno API]()
    - [cno Agent]()
    - [cno Openshift-operator]()
    - [cno CD-operator]()
    - [cno K8s-operator]()
* [Installing](#Installing)
    - [Kind Installation]()
    - [Installing CNO via Helm]()
        * [Installation]()
        * [Checks]()
    - [Manual Installation]()
        * [Installing Kafka]()
            - [Installing Kafka Operator]()
            - [Deploying a Kafka Operator]()
            - [Creating the Onbording super-admin]()
        * [Installing keycloak]()
            - [Installing keycloak operator]()
            - [deploiying keycloak cluster]()
        * [Installing mysql DB]()
            - [Create the database and the service]()
            - [Create the PV/PVC that will associated]()
        * [Installing cno operator]()
            - [Deploying using the cno operator image]()
            - [Creating cluster role(+binding)]()
        * [Installing cno agent]()
        * [Installing cno api]()

* [Contributing](#Contributing)
## Get Started
Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.
## Architecture
CNO Architecture ![Architecture](/image/architecture.png)
## Component
CNO is an open source project mainly composed of 7 modules.
1. cno UI
2. cno API
3. cno Agent
4. cno Openshift-operator
5. cno CD-operator
6. cno K8s-operator
7. CLI
## Installing
1. Kind Installation
* Clone the operator repository
```bash
git clone https://gitlab.beopenit.com/cloud/cno-operator.git
```
* Install the operator
```
make install
```
```
make deploy
```
2. Installing CNO via Helm
## Installation
```bash
helm install cno .
```
## Checks
```bash
helm get manifest cno
```
3. Manual Installation
## Installing kafka
### Installing kafka Operator
```bash
kubectl create namespace kafka
kubectl apply -f ./files/kafkaOperator.yaml -n kafka
```
### Deploying Kafka Cluster
```yaml
cat <<EOF | kubectl -n kafka apply -f -
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  kafka:
    version: 2.5.0
    replicas: 3
    listeners:
      external:
        type: loadbalancer
        authentication:
          type: tls
        overrides:
          bootstrap:
            address: bootstrap.kafka.cloud.beopenit.com
          brokers:
          - broker: 0
            advertisedHost: broker-0.kafka.cloud.beopenit.com
          - broker: 1
            advertisedHost: broker-1.kafka.cloud.beopenit.com
          - broker: 2
            advertisedHost: broker-2.kafka.cloud.beopenit.com
      tls:
        authentication:
          type: tls
    authorization:
      type: simple
      superUsers:
        - CN=onboarding
    config:
      offsets.topic.replication.factor: 3
      transaction.state.log.replication.factor: 3
      transaction.state.log.min.isr: 2
      log.message.format.version: "2.5"
    storage:
      type: ephemeral
  zookeeper:
    replicas: 3
    storage:
      type: ephemeral
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF
```
### Creating the Onboarding super-admin
```yaml
cat <<EOF | kubectl -n kafka apply -f -
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaUser
metadata:
  name: onboarding
  labels:
    strimzi.io/cluster: my-cluster
spec:
  authentication:
    type: tls
  authorization:
    type: simple
    acls: []
EOF
```
## Installing keycloak
### Installing keycloak operator
```
kubectl apply -f ./files/keycloak/crds/ -n keycloak
```
### deploying keycloak cluster
```yaml
cat <<EOF | kubectl apply -n keycloak -f -
apiVersion: keycloak.org/v1alpha1
kind: Keycloak
metadata:
  name: cloud-keycloak
  labels:
    app: sso
spec:
  instances: 3
  extensions:
    - https://github.com/aerogear/keycloak-metrics-spi/releases/download/1.0.4/keycloak-metrics-spi-1.0.4.jar
  externalAccess:
    enabled: false
  podDisruptionBudget:
    enabled: True
EOF
```
Another method
```
kubectl apply -f ./files/keycloak/templates/clusterkeycloak.yaml
```
## Installing Mysql DB
### Create the Database and the Service
```yaml
cat <<EOF | kubectl apply -n keycloak -f -
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  ports:
    - port: 3306
  selector:
    app: mysql
  clusterIP: None
---
apiVersion: apps/v1 
kind: Deployment
metadata:
  name: mysql
spec:
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
        - image: mysql:5.6
          name: mysql
          env:
            # Use secret in real usage
            - name: MYSQL_ROOT_PASSWORD
              value: password
          ports:
            - containerPort: 3306
              name: mysql
          volumeMounts:
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql
      volumes:
        - name: mysql-persistent-storage
          persistentVolumeClaim:
            claimName: mysql-pv-claim

EOF
```
### Create the PV/PVC that will associated
```yaml
cat <<EOF | kubectl apply -n keycloak -f -
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv-volume
  labels:
    type: local
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "2"
    "helm.sh/hook-delete-policy": hook-succeded
spec:
  storageClassName: manual
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/mnt/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  annotations:
    "helm.sh/hook": pre-install
    "helm.sh/hook-weight": "1"
spec:
  storageClassName: manual
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 20Gi

EOF
``` 
## Installing cno Operator
### Deploying using the cno operator image
```bash
kubectl apply -f ./files/cnoOperator/crds/
``` 
### Creating Cluster role(+binding)
```bash
kubectl apply -f clusterRole.yaml -f clusterRoleBinding.yaml -f service_account.yaml
```
## Installing cno Agent 
## Installing cno Api
```
kubectl apply -f ./files/onboarding-api/templates/onboarding-api.yaml
``` 
## Contributing
To Contribute to the CNO project, please follow this [Contributor's Guide](https://github.com/beopencloud/cno/tree/main/contributor_guide)


