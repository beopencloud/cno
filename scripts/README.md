# User Guide
## Install

    GO111MODULE=on go get github.com/beopenitcloud/cnoctl
    
###### NB:
Make sure you have $GOPATH/bin in your path or move $GOPATH/bin/cno binary in a folder of your path 

## Commandes
### config
This command allows you to config the cno cli so that it can communicate correctly with the sso and the cno api

Flags:

|        name          |        description                             |           value example          |
|----------------------|------------------------------------------------|----------------------------------|
| server-url           |   application api URL                          | https://cno.beopenit.com         |
| organization         |   name of the organization                     | default                         |

Use:
    
    cnoctl config --server-url=https://cno.beopenit.com --organization=default


###### NB:
If an flags is not set, the cli will invite you to enter his value 
### get
This command have tho others subcommand: env and project
#### get project
This command displays the list of projects to which you have access.

Flags:

|        name        |        description                          |
|--------------------|---------------------------------------------|
| username           |   your username                             |
| password           |   your password                             |

Use:
    
    cnoctl get project

#### get env
This command displays the list of environment of a project.

Flags:

|        name        |        description                          |
|--------------------|---------------------------------------------|
| project            |   name of the project                       |
| username           |   your username                             |
| password           |   your password                             |

Use:
    
    cnoctl get env --project=<your-project>

NB:
If project flag is empty the cli will use the current project.

### use
This command have an other subcommand: env

#### use env
This command allows you to have a valid kubeconfig allowing you to interact with the cluster on which the environment is deployed.
The generated kubeconfig contains a certificate with your username as CN signed by the cluster k8s.
Which will allow the k8s cluster to identify you. 

Flags:

|        name        |        description                          |
|--------------------|---------------------------------------------|
| project            |   id of the project                         |
| env (-e)           |   id of the environment you want to use  |
| username           |   your username                             |
| password           |   your password                             |

Use:

    cnoctl use env --project=<your-project>  --e <your-env>
    
###### NB:
- If env flag not set, the cli will invite you to select an environment from the list of project environments to which you have access
- If project flags is empty the cli will use the current project if it exist. if not the cli will invite you to select the project 

# Developer's Guide

## Create and publish a new release
1. Create a new tag and publish them

        git tag -a v0.1.0 -m "First release"
        git push origin v0.1.0

2. Create a github access token and export GITHUB_TOKEN variable

        export GITHUB_TOKEN=<acces-token>
        
3. Create and publish the release

        goreleaser --rm-dist