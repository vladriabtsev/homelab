# Kubernetes Manifests for Jenkins Deployment

[Setup Jenkins On Kubernetes](https://www.jenkins.io/doc/book/installing/kubernetes/)

[How to Install Jenkins in Kubernetes with Kaniko for Container Building](https://www.youtube.com/watch?v=qSK3HNirASU)

[Kubernetes CI/CD Pipeline Using Jenkins | DevOps Tutorial/Project - 2023](https://www.youtube.com/watch?v=q4g7KJdFSn0)

[Jenkins Integration with Slack : Increase Visibility Into Your Jenkins Job Status](https://www.youtube.com/watch?v=LebdNtD2Rz4)

[](https://www.jenkins.io/doc/book/installing/kubernetes/#install-jenkins-with-helm-v3)
* helm repo add jenkinsci https://charts.jenkins.io
* helm repo update
* helm install [RELEASE_NAME] oci://ghcr.io/jenkinsci/helm-charts/jenkins [flags]
* helm uninstall [RELEASE_NAME]
* helm upgrade [RELEASE_NAME] jenkins/jenkins [flags]

Refer https://devopscube.com/setup-jenkins-on-kubernetes-cluster/ for step by step process to use these manifests.


