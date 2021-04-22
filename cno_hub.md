# Description for use cluster features in CNO

## I. Register an existing cluster

1. Platform supported 

    - Amazon Elastic Kubernetes Service (EKS)
    - Google Kubernetes Engine (GKE)
    - Azure Kubernetes Service (AKS)
    - RedHat Hat OpenShift Container Platform
    - VMware Tanzu
    - Rancher
    - Scaleway Kubernetes Kapsule
    - Any other kubernetes distribution

2. Step to register an existing cluster

To access to CNO HUB you can follow [CNO UI](https://cno.cno-dev.beopenit.com/). Once on the CNO interface, you must click on ``` CNOHub ``` at the top right on the dashboard to access the registration space of an existing cluster. After this we can see other interface, at the top left click on 
``` 
Add new Cluster to CNOHub 
```
![CNOHub](image/addcluster.png)

When you finish to click on this target we can see a other interface in which there are two fields. For register an existing cluster you must click on ` Advanced Registration `.

![Register Cluster](image/Registrer.PNG)

After this picture you can see the interface which permit to you to register your cluster in the part cluster form.But you must to have your cluster before this step.

![Advanced register](image/Advanced.PNG)

On this interface you can put the name of your cluster, his Api server URL and the cluster type. All the fields are required. If you finish to inform these field you can click on ` Add `.

After clicking on ` Add ` a new window opens, copy outpout commands in order to install the CNO agent to the cluster created.


## II. Creating a Cluster form CNO Hub

1. Platform supported

This part of the creation of the cluster support at the moment the AWS EKS platform.

2. Register an existing Cluster

We resume on the part where we had two options opposite to know Advanced Registration and Add New cluster on CNO Hub. For create a cluster form CNO Hub you must click on `  Add New cluster on CNO Hub `. See the following picture

![CreateCluster](image/Cnohub_create.PNG)

After click on the button **Test** to access on the interface where you can see more cluster existing with their cloud providers and two button at the top right:
> Add existing cluster

or

> Add new cluster

![cluter on CNO Hub](image/ExistingORnewcluster.PNG)

### Add existing cluster

For this part we go to use the button Add existing cluster; for the second we can talk about it in the end session of our documention that concerns **Add cloud providers**.

Now, we select before the cloud provider available :

![cluter on CNO Hub](image/chooseCloudProvider.PNG)

After selection, the two options are highlighted. We click on *Add existing cluster* and this interface appears :

![add cluster](image/addExistingcluster.PNG)

On this interface we must to choose a cloud provider.Then you choice the cluster that existing on this cloud provider and click on ` Add `. Here this is AWS that it's available for this moment.

### Add new cluster

Here we want to create a new cluster and register it to CNO Hub. When you click on button `Add new Cluster` this interface come:

![add new cluster](image/AddNewCluster.PNG)

**Halt** When you click on add new cluster, you are asked to choose a cloud provider. However, before choosing a cloud, you must have added a cloud provider. How to add a cloud provider we will see in the last part.


## III. Add cloud providers

1. Platform supported

This part also support at the moment the AWS EKS platform.

2. Add your cloud provider

To add a cloud provider, we go to the left menu in the parameters section. We click on ` parameters ` then on ` cloud provider `

![parameters](image/CloudProvider.PNG)

On the interface that appeared we will see at the top right the button *Add New Cloud Provider*. 
We click on this and we have another interface:

![add new cloud](image/addCloudProvider.PNG)

For the addition of the cloud, here it is only AWS that is available. Then we fill in the rest of the required fields to finally validate by pressing the add button.
