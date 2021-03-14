
# Configure  kubeconfig

### Option 1: Configure Kubeconfig with your Cloud Provider CLI

##### Azure Kubernetes Service

```
export AZSUBSCRIPTION=xxxxxxx
export RESOURCE_GROUP="xxxxxxxx"
export AKS_CLUSTER_NAME="xxxxxx"

az account set --subscription $AZSUBSCRIPTION1
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME
```

Find more information on [Azure Docs](https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az_aks_get_credentials)

##### Amazon Elastic Kubernetes

```
export AWS_REGION=xxxxxxx
export EKS_CLUSTER_NAME="xxxxxx"

aws update Cluster aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER_NAME
```
Find more information on [AWS Docs](https://docs.aws.amazon.com/eks/latest/userguide/cluster-endpoint.html)

##### GKE CLI

```
export GCP_ZONE=xxxxxxx
export GCP_PROJECT_NAME=xxxxxxx
export GKE_CLUSTER_NAME="xxxxxx"

gcloud container clusters get-credentials $GKE_CLUSTER_NAME --zone $GCP_ZONE --project $GCP_PROJECT_NAME

```

Find more information on [Google Cloud Platform Docs](https://cloud.google.com/sdk/gcloud/reference/container/clusters/get-credentials)


##### RedHat OpenShift platform

Log in to the CLI using the oc login command and enter the required information when prompted.
```
oc login
```

Find more information on [Red Hat OpenShift Docs](https://docs.openshift.com/container-platform/4.6/cli_reference/openshift_cli/getting-started-cli.html#cli-logging-in_cli-developer-commands)

### Option 2: Configure Kubeconfig manually

If you installed kubernetes on bare Metal, via kubeadm or with any other distribution (e.g. Rancher...) you can follow  Kubernetes documentaion via [kubernetes.io](https://kubernetes.io/fr/docs/tasks/access-application-cluster/configure-access-multiple-clusters/)
