## Table of Contents
* [Getting Started](#Getting)
* [Process](#Process)
* [Submitting a pull Request](#Submitting)

### Getting Started
Thank you for considering contributing to our AGENT CNO project.  
To participate in this process, you only need an account at Github.com.  
If you don't have an account yet, here is the link to register on [Github.com](https://github.com/).

### Process
#### Fork the project  
At the top right, you will find the "Fork" button.  
Click it and wait a few moments while GitHub takes care of cloning this repository into your repositories.
#### Requirements
Install
- [golang](https://golang.org/dl/) 1.14+
- [docker](https://docs.docker.com/get-docker/) 17.03+
- [kubctl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) 1.14.1+
- [Operator-sdk](https://sdk.operatorframework.io/docs/install-operator-sdk/)
- Acces to a kubernetes 1.14.4 + cluster
- Server Kafka
#### Pulling the dependencies
```
 go mod tidy
``` 
#### Best practice Git
- Create a descriptive topic branch.
- Make our change to the code.
- Check that the change is good.
- Commit your change to the topic branch.
    Treat commit messages as an email that describes what you changed and why.  
    The commit message describes the details of the commit.  
- Push your new topic branch back up to our GitHub fork.

### Submitting a Pull Request
If we go back to our fork on GitHub, GitHub noticed that we pushed a new topic branch up and presented us with a big green button to check out our changes and open a Pull Request to the original project.  
- Click that green button and give a title and description of the Pull Request.  
    Put a good description that helps the original project owner what you were trying to do.  
- Create a pull request (click on "Create pull request").


