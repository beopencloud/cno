 # CNO<br/>Cloud Native Onboarding

**CNO is your Operations Center for Kubernetes &ndash; a single management platform for Admins in a hybrid / multi-cloud ecosystem; a common experience for multiple Ops & Dev teams.**
 # Build commande

 ` bash

    cd deploy/helm/data-plane
    helm dependencies update
    helm package .
    helm repo index --url https://beopencloud.github.io/cno --merge index.yaml .
    mv door-agent-*.tgz ../../../docs
    cp new index content to ../../../docs
 `

CNO core components run on Kubernetes, with remote agents in each of the other Kubernetes clusters in its scope. All CNO features are exposed through a REST API, a command-line tool, and a web User Interface.

Through CNO, you can take advantage of the Kubernetes ecosystem and set up the best Onboarding Experience for your Teams. 

-   Website: [gocno.io](http://www.gocno.io)
-   Full Documentation : [https://docs.gocno.io/](https://docs.gocno.io/about/what-is-cno)
-   Community : [CNO's slack](https://gocno.slack.com)

**Your feedback is valuable:** We are particularly attentive to your experience with CNO. 
If you face any issue during your journey on CNO, don't hesitate to get in touch with us at [cno@beopenit.com](mailto:cno@beopenit.com) or directly create an issue in this project.

## Summary
* [Key features and advantages](#Key-features-and-advantages)

* [Audience](#audience)

* [Core Concepts](#core-concepts)

* [Getting Started](#getting-started)

* [Support & Contributions Guidelines](#support--contributions-guidelines)

* [Roadmap](#roadmap)


## Key features and advantages

- Centralize all your Kubernetes clusters in a single platform: public or on-premise.

- Add, Delete, Update, and Monitor all your Kubernetes clusters in the CNO Hub.

- Define and Apply Kubernetes Implementation Framework for your company through Tagging Strategy, Resource Quota Strategy, and IAM Strategy.

- Onboard all your teams into CNO and let them define their projects, onboard their team members &ndash; on multi-cloud environments.

- Deploy your applications faster by choosing the strategy that fits your use-case: Blue/Green, Canary, or A/B Testing

## Audience
### What uses-cases CNO covers?

Introducing Kubernetes is not easy for companies. Due to its natural complexity and youth, aligning people, hardware needs, and business goals is a real challenge.

**CNO** helps you to build the adoption program to minimize resistance and **aligns cloud-native technology with Business.**

It effectively combines three key elements: 
- The best onboarding experience for your teams; 
- A reliable and consistent continuous deployment of your applications to market;
- The security involvement during onboarding and the continuous deployment of the applications.

### Who can benefit from CNO?

**Every professional involved in delivering applications**  either in development or production environments, can benefit from CNO's actions: I.T. managers, project owners, network administrators, developers, etcetera.

You can see  **CNO**  as a  **Common Language**: from Ops to Developers to Project Managers. We believe they all should be able to efficiently collaborate in a single place.

- If you are an Ops, DevOps, DevSecOps, or you love dancing with kubectl: 

You can perform your Kube-oriented actions and even more challenging things directly from the built-in command-line cnoctl.
    
- Suppose you only want to work with Kubernetes in specific scenarios but don't want to bother knowing all the documentation details. 

In that case, you can perform pre-defined homogenous actions Kubernetes offers through the User Interface. Imagine it as a soft layer translating Kubernetes into incredible designs.
 
## Core concepts

Only four concepts, i.e., four steps, to achieve onboarding and deploying at scale.

CNO core components run on Kubernetes, with remote agents in each of the other Kubernetes clusters in its scope. All CNO features are exposed through a REST API, a command-line tool, and a web User Interface.

### CNO Clusters(Hub)

Hide the complexity of multi-cloud or multi-cluster Kubernetes infrastructure management.
CNO Hub centralizes management, governance, and monitoring of your Kubernetes clusters on any cloud from a single Console. 
May it be public or on-premise.

[More about CNO Hub >](https://docs.gocno.io/concepts/cno-hub/)

### CNO Projects(Onboard)

Quickly onboard and manage your team's or organization's projects within a unifying management platform.

CNO Onboard is the platform's flagship feature, providing a turnkey framework for onboarding all your teams and projects across multi-cloud environments. 

How does it work? Each Project Owner takes control of their projects by choosing their work environment and setting up teams with specific fields of action according to the professions.

[More about CNO Onboard >](https://docs.gocno.io/concepts/cno-onboard/) 

### CNO Deploy

Choose the fastest way to deliver applications across your multiple environments.

Take advantage of CNO Deploy with advanced deployment strategies such as Canary, Blue Green & A/B testing in your production environment.

[More about CNO Deploy >](https://docs.gocno.io/concepts/cno-deploy/) 

### CNO Members(Secure)

Learn how to ensure an entire lifecycle of Kubernetes security for all your clusters and containerized cloud-native applications.

CNO Secure helps you scan your infrastructure and ensure your clusters are compliant with standards like CIS, PCI DSS, NIST, MITRE ATTACK…

[More about CNO Secure >](https://docs.gocno.io/concepts/cno-secure/) 

## Getting Started

You can refer to our documentation to try CNO:

[Quickstart > ](https://docs.gocno.io/start/quickstart/)

[Install CNO's CLI >](https://docs.gocno.io/start/cnocli/)

[Tutorial: Multi-Cloud Management >](https://docs.gocno.io/tutorials/multi-cloud-management/)

[Tutorial: Onboarding Projects and Teams >](https://docs.gocno.io/tutorials/onboard-project-team/)

[Tutorial: Continuous Deployments with CNO >](https://docs.gocno.io/tutorials/continuous-deployment/)

## Support & Contributions Guidelines

Let's be humble: CNO is at its v1; thus, it's far from perfect yet. But with your help, we know we can get better! 

You get an entire experienced team dedicated to CNO, and sincerely happy to hop up for any questions or troubles you might get during your CNO journey.

### Contributions

You can push your issues or contributions to GitHub. 

At the top right of the github repository, click on the "Fork" button. This will clone the repository onto yours.

#### Best Practices Git :
- Create a descriptive topic branch.
- Make your change to the code.
- Check that the change is good.
- Commit your change to the topic branch. Treat commit messages as an email that describes what you changed and why.
- The commit message describes the details of the commit.
- Push your new topic branch back up to your GitHub fork.

#### Submitting a pull request :
- Go back to your fork on GitHub, GitHub noticed that you pushed a new topic branch up and presents you with a big green button to check out your changes and open a Pull Request to the original project.
- Click that green button and give a title and description of the Pull Request.
- Put a good description that helps the original project owner what you were trying to do.
- Create a pull request (click on "Create pull request").

#### Specific contributions
- To contribute to CNO's API, please refer to [CNO's API Contribution Guide](https://github.com/beopencloud/cno/blob/main/contributor_guide/cno-api_contributions.md)
- To contribute to CNO's Agent, please refer to [CNO's Agent Contribution Guide](https://github.com/beopencloud/cno/blob/main/contributor_guide/cno-agent_contributions.md)
- To contribute to CNO's Kubernetes Operator, please refer to [CNO's K8S Operator Contribution Guide](https://github.com/beopencloud/cno/blob/main/contributor_guide/cno-k8s-operator_contributions.md)
- To contribute to CNO's Notification System, please refer to [CNO's Notification Contribution Guide](https://github.com/beopencloud/cno/blob/main/contributor_guide/cno-notification_contributions.md)

### Support

You can contact us through the mail adress [cno@beopenit.com](mailto:cno@beopenit.com) (we answer in a matter of hours)

You can directly send a message in CNO's slack [here](https://gocno.slack.com)

## Roadmap

For 2022, here are our main KPIs:
- Improve the actual product thanks to the community, our testers, and our clients' feedback
- Take CNO Secure to the next level with three new features: Scan, Compliance, and Policies.
- Take CNO Deploy to the next level with two new strategies: A/B Testing and Canary.
- Prepare the SaaS version of CNO for enhanced adoption.
- You might also get to hear from us on the serverless market at some point, but one thing at a time :) 

Hope to hear from you! 

With love,
CNO and BeOpen IT teams <3 
