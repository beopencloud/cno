# CNO 

CNO is a unified platform that simplifies the adoption and use of Kubernetes in a multi-cloud ecosystem.

## Prerequisites
  - A Kubernetes Cluster This Kubernetes cluster will host CNO's control plane and is the only cluster not managed within CNO.
  - Supported Kubernetes Version: Kubernetes 1.20, 1.21. 1.22.

## Get Repo Info

```
helm repo add cno-repo https://beopencloud.github.io/cno
helm repo update 
```

__Value content example__

    cluster:
    # kubernetes or openshift
      platform: kubernetes
    # kubernetes api-server url
      apiUrl: https://kubernetes-api-server-url
    expose:
    # values: loadbalancer, nodeport, route or nginx-ingress
      type: nginx-ingress
    # set if expose equal to route or nginx-ingress
      ingress:
        domain: dev.gocno.io
    superadmin:
      password: admin
    agentConfig:
      # cluster type eks, aks, gke, vanilla
      defaultClusterType: EKS
      cnoAgent:
        metricServer: true

## Install Chart

```
helm install cno cno-repo/cno -f values.yaml --namespace cno-system --create-namespace
```

## Uninstall Chart

```
helm uninstall cno
```


## Configuration 

To see all configurable options with detailed comments, visit the chart's values.yaml, or run these configuration commands:

```
 helm show values cno-repo/cno
```

#### Set cluster type and api-server url 
 
```yaml
 cluster:
   platform: <platform>
   apiUrl: <api-server url>
   ...
 ```
#### Expose type
- __Loadbalancer__
    ```yaml
    expose:
      type: loadbalancer
    ```
- __NodePort__
    ```yaml
    expose:
      type: nodeport
    ```
- __nginx-ingress (to test)__
    ```yaml
    expose:
      type: nginx-ingress
      ingress:
        domain: <your domain>
    ```
- __openshift route (to test)__
    ```yaml
    expose:
      type: route
    ```
#### Default super admin (after created it not possible to update password)
the username of default super admin is _admin_

- __Set password__
    ```yaml
    superadmin:
      password: admin
    ```
- __Pass password on secret__
    ```shell
    kubectl create secret generic cno-super-admin \
    --from-literal=PASSWORD=admin \
    --namespace cno-system 
    ```
    ```yaml
    superadmin:
      secret:
        name: cno-super-admin
        key: PASSWORD
    ```
- __Kafka Config__
  
   - __Kafka ephemeral__
  
    ```yaml
    kafkaConfig:
      externalBrokersUrl: <internal access to kafka>
      storage:
        type: ephemeral
      ...
    ```
   - __Kafka persistent__
    ```yaml
    kafkaConfig:
      externalBrokersUrl: <internal access to kafka>
      storage:
        type: persistent-claim
        persistentVolumeClaim:
          deleteClaim: true
          size: 1Gi
      ...
    ```

> **_NOTE:_**  if you don't have storageclass, you have to create two pvc named _data-cno-kafka-cluster-zookeeper-0_ and _data-cno-kafka-cluster-kafka-0_.

#### Mysql database Config
You can deploy mysql database with CNO or use an existing mysql database
- ##### Deploy mysql database with CNO
    ```yaml
    databaseConfig:
      internalDatabase: true
      type: MYSQL
      host: cno-api-mysql
      database: cnoapi
      port: 3306
      secret:
        name: cno-db-credentals
      ...
    ```
- ##### Use an existing mysql database with CNO
    ```shell
    kubectl create secret generic cno-db-credentals \
    --from-literal=DB_USERNAME=<username> \
    --from-literal=DB_PASSWORD=<password> \
    --namespace cno-system 
    ```
    ```yaml
    databaseConfig:
      internalDatabase: false
      type: MYSQL
      host: <host>
      database: <database name>
      port: "port"
      secret:
        name: cno-db-credentals
      ...
    ```
#### Default data-plane
- ##### Don't deploy data-plane
    ```yaml
    agentConfig:
      defaultCluster: false   
    ```
- ##### Deploy data-plane
Set metricServer to false if you already have metric server installed in the cluster.

  ```yaml
    agentConfig:
      defaultCluster: true
      metricServer: true
      ...
  ```