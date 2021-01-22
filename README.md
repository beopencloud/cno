## CNO, Cloud Native Onboarding.
Onboard, Deploy, Manage and Secure microservices on Kubernetes.

* [Get Started]()
* [ Architecture](#Architecture)
* [Component](#Component)
* [Installing](#Installing)
* [Contributing](#Contributing)
## Get Started

CNO (Cloud Native Onboarding) is an open source platform to onboard easily and securely development teams on multi-cloud Kubernetes clusters from a single console.

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
### Automatique Installation: Kind
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


