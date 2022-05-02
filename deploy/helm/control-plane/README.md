## CNO control-plane helm chart

### Requirements
- Kubernetes: 1.20, 1.21, 1.22
- Install metrics server (optional): if not installed, and you want to install CN0 control-plane with data-plane

### Configuration

#### Set cluster type and api-server url 
 
```yaml
 cluster:
   platform: <platform>
   apiUrl: <api-server url>
   ...
 ```
#### Expose type
- ##### Loadbalancer
    ```yaml
    expose:
      type: loadbalancer
    ```
- ##### NodePort
    ```yaml
    expose:
      type: nodeport
    ```
- ##### nginx-ingress (to test)
    ```yaml
    expose:
      type: nginx-ingress
      ingress:
        domain: <your domain>
    ```
- ##### oenshift route (to test)
    ```yaml
    expose:
      type: route
    ```
#### Default super admin (after created it not possible to update password)
the username of default super admin is _admin_

- ##### Set password
    ```yaml
    superadmin:
      password: admin
    ```
- ##### Pass password on secret
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
#### Kafka Config
- #### Kafka ephemeral
    ```yaml
    kafkaConfig:
      externalBrokersUrl: <internal access to kafka>
      storage:
        type: ephemeral
      ...
    ```
- #### Kafka persistent
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

### Install CNO

```shell
git clone https://github.com/beopencloud/cno.git
cd cno/deploy/helm/cno/control-plane
helm dependency update ./
helm install cno ./ --namespace cno-system --create-namespace
```
### Deploy CNO UI
Edit API_URL to put external CNO API url in API_URL
```shell
kubectl -n cno-system set env deployment/cno-ui API_URL=test-cluster
```

### Uninstall CNO

```
helm uninstall cno --namespace cno-system 
kubectl delete namespace cno-system
```
