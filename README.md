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
    - [Automatique Installation: Kind]()
    - [Installing CNO via Helm]()
        * [Installation]()
        * [Checks]()
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
1. Automatique Installation: Kind
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


