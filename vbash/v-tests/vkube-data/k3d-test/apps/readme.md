# Apps

## Install by kustomize

* [kustomize](https://kustomize.io/)
* [kustomize on github](https://github.com/kubernetes-sigs/kustomize)
* [Declarative Management of Kubernetes Objects Using Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)

`kubectl kustomize <kustomization_directory>`
`kubectl apply -f`

* `kubectl create namespace NAME`
* Apply `kubectl apply -k <kustomization directory>`

Apps

* MsSQL
  * 2017
    * `kubectl create namespace mssql2017`
    * `kubectl apply -k ./db/mssql/overlay/development/2017`
  * 2019
    * `kubectl create namespace mssql2019`
    * `kubectl apply -k ./db/mssql/overlay/development/2019`
  * 2022
    * `kubectl create namespace mssql2022`
    * `kubectl apply -k ./db/mssql/overlay/development/2022`