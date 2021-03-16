# Bootstrap a Kubernetes Cluster

#### Amazon Elastic Kubernetes Service (EKS)

It's easier to create a cluster with eksctl cli. At first, you need to install [eksctl](https://eksctl.io/introduction/#installation), then bootrap your eks cluster the following command:

```
export AWS_REGION="francecentral"
export EKS_CLUSTER_NAME="demo"
export EKS_VERSION="1.19"

eksctl create cluster \
--name $EKS_CLUSTER_NAME \
--version $EKS_VERSION \
--region $AWS_REGION \
--nodegroup-name linux-nodes \
--nodes 1 \
--nodes-min 1 \
--nodes-max 3 \
--with-oidc \
--ssh-access \
--managed'''
```
Update the current context of your local kubeconfig
```
aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
```

You can also install a Kubernetes cluster with [AWS CLI or via AWS console](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html)

#### Azure Kubernetes Service (AKS)
```
export RESOURCE_GROUP="democno"
export REGION="francecentral"
export CLUSTER_NAME="demo"
export AKS_VERSION="1.19.7"

az group create -g $RESOURCE_GROUP -l $REGION
az aks create --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --kubernetes-version $AKS_VERSION \
    --node-vm-size Standard_D2_v2 \
    --node-count 2 \
    --generate-ssh-keys  \
    --network-plugin kubenet \
    --network-policy calico
```
Update the current context of your local kubeconfig 
```
az aks get-credentials --resource-group $RESOURCE_GROUP --name $CLUSTER_NAME
```

#### Google Kubernetes Engine (GKE)


```
export GCP_ZONE=xxxxxxx
export GKE_CLUSTER_NAME="xxxxxx"
export GKE_VERSION="1.19"
export GCP_PROJECT_NAME=xxxxxxx

gcloud services enable container.googleapis.com
gcloud config set project $GCP_PROJECT_NAME
gcloud container clusters create $GKE_CLUSTER_NAME \
    --enable-autoupgrade \
    --enable-autoscaling --min-nodes=1 --max-nodes=10 --num-nodes=1 \
    --zone=$GCP_ZONE --cluster-version=$GKE_VERSION
```
Update the current context of your local kubeconfig 
```
gcloud container clusters get-credentials $GKE_CLUSTER_NAME --zone us-central1-c --project $GCP_PROJECT_NAME
```
#### OpenShift

#### Minishift

#### Kubeadm
