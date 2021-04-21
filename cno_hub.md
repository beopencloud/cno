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

To access the CNO HUB you have to follow [CNO UI](https://cno.cno-dev.beopenit.com/). Once on the CNO interface, you must click on ``` CNOHub ``` at the top right on the dashboard to access the registration space of an existing cluster. After this we can see other interface, at the top left click on 
``` 
Add new Cluster to CNOHub 
```
![CNOHub](image/addcluster.png)

When you finish to click on this target we can see a other interface in wich there two fields. For register an existing cluster you must click on ` Advanced Registration `.

![Register Cluster](image/Registrer.PNG)

After this picture you can see the interface which permit to you to register your cluster form.But you must to have your cluster before this step.

![Advanced register](image/Advanced.PNG)

On this interface you can put the name of your cluster, his Api server URL and the cluster type. All the fields are required. If you finish to inform these field you can click on ` Add `.

After clicking on ` Add ` a new window opens so that we can add the CNO agent to the cluster created.


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

For this part we go to use the button Add existing cluster; for the second we can talk about it in the end session of our documention that concerns **Add cloud providers**.

Now, we select before the cloud provider available :

![cluter on CNO Hub](image/chooseCloudProvider.PNG)

After selection, the two options are highlighted. We click on *Add existing cluster*

