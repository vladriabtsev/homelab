# Gitea

* [Gitea](https://about.gitea.com/)
* [Gitea github](https://github.com/go-gitea/gitea)
* [Awesome Gitea](https://gitea.com/gitea/awesome-gitea)
* [Gitea Helm Chart](https://gitea.com/gitea/helm-chart)

Services

* Gitea
* PostgreSQL HA
* Redis-Cluster

## Install

[Install on Kubernetes](https://docs.gitea.com/installation/install-on-kubernetes)

Installation
* helm repo add gitea-charts https://dl.gitea.com/charts/
* helm repo update
* kubectl create namespace gitea
* helm install gitea gitea-charts/gitea -n gitea
* helm uninstall gitea
* kubectl apply -f ./vkube-data/k3s-HA/apps/103-gitea/svc.yaml

vlad Q0 ???

[Gitea Helm Chart](https://gitea.com/gitea/helm-chart/)

[Configuration Cheat Sheet](https://docs.gitea.com/administration/config-cheat-sheet)
