# Kubernetes Manifests for Jenkins Deployment

[Setup Jenkins On Kubernetes](https://www.jenkins.io/doc/book/installing/kubernetes/)

[How to Install Jenkins in Kubernetes with Kaniko for Container Building](https://www.youtube.com/watch?v=qSK3HNirASU)

[Kubernetes CI/CD Pipeline Using Jenkins | DevOps Tutorial/Project - 2023](https://www.youtube.com/watch?v=q4g7KJdFSn0)

[Jenkins Integration with Slack : Increase Visibility Into Your Jenkins Job Status](https://www.youtube.com/watch?v=LebdNtD2Rz4)

[Install Jenkins with Helm v3](https://www.jenkins.io/doc/book/installing/kubernetes/#install-jenkins-with-helm-v3)
* helm repo add jenkinsci https://charts.jenkins.io
* helm repo update
* helm install [RELEASE_NAME] oci://ghcr.io/jenkinsci/helm-charts/jenkins [flags]
* helm uninstall [RELEASE_NAME]
* helm upgrade [RELEASE_NAME] jenkins/jenkins [flags]

Refer https://devopscube.com/setup-jenkins-on-kubernetes-cluster/ for step by step process to use these manifests.

[Kubernetes Jenkins Deployment](https://www.jenkins.io/doc/book/installing/kubernetes/)

* `kubectl create namespace devops-tools`
* kubectl get nodes
* `kubectl create -f ./vkube-data/k3s-ha/apps/109-jenkins/jenkins-01-serviceAccount.yaml`
* `kubectl create -f ./vkube-data/k3s-ha/apps/109-jenkins/jenkins-02-volume.yaml`
* `kubectl create -f ./vkube-data/k3s-ha/apps/109-jenkins/jenkins-03-deployment.yaml`
* `kubectl create -f ./vkube-data/k3s-ha/apps/109-jenkins/jenkins-04-service.yaml`
* Check jenkins container log for: 'Please use the following password to proceed to installation'
* Enter admin password in WEB UI
* Create first admin user

Development

* [Jenkins User Documentation](https://www.jenkins.io/doc/)
* [Using Jenkins agents](https://www.jenkins.io/doc/book/using/using-agents/)
* [Build a .NET Web App with Jenkins](https://www.jenkins.io/doc/tutorials/build-a-dotnet-web-app-with-jenkins/)
* [.NET SDK Support](https://www.jenkins.io/doc/pipeline/steps/dotnet-sdk/)
* [How to build and deploy a .Net application with Jenkins and AWS using devops automations?](https://jrichardsz.medium.com/how-to-build-and-deploy-a-net-application-with-jenkins-and-aws-using-devops-automations-518952b6c313)
* [CI/CD for .NET MVC Using Jenkins](https://dzone.com/articles/cicd-in-aspnet-mvc-using-jenkins)
* [Linking Jenkins and Docker on Windows with WSL – The Simple Way](https://www.guvi.in/blog/linking-jenkins-and-docker-on-windows-with-wsl/)