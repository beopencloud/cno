* [Get Started]()
* [ Architecture](#Architecture)
* [Component](#Component)
    - [cno UI]()
    - [cno API]()
    - [cno Agent]()
    - [cno Openshift-operator]()
    - [cno CD-operator]()
    - [cno K8s-operator]()
* [Installing](#Installing)
    - [Kind Installation]()
    - [Installing CNO via Helm]()
    - [Manual Installation]()
        * [Installing Kafka]()
            - [Installing Kafka Operator]()
            - [Deploying a Kafka Operator]()
            - [Creating the Onbording super-admin]()
* [Contributing](#Contributing)
## Get Started
Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s, when an unknown printer took a galley of type and scrambled it to make a type specimen book.
## Architecture

## Component
CNO is an open source project mainly composed of 4 modules.
1. cno UI
2. cno API
3. cno Agent
4. cno Openshift-operator
5. cno CD-operator
6. cno K8s-operator
7. CLI
## Installing
1. Kind Installation
2. Installing CNO via Helm
3. Manual Installation
## Installing kafka
### Installing kafka Operator
```bash
kubectl create namespace kafka
kubectl apply -f ./files/kafkaOperator.yaml -n kafka
```
### Deploying Kafka Cluster
```
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

  
## Contributing


