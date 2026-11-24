# Apps

## Install by kustomize

* [kustomize](https://kustomize.io/)
* [kustomize on github](https://github.com/kubernetes-sigs/kustomize)
* [Declarative Management of Kubernetes Objects Using Kustomize](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)

`kubectl kustomize <kustomization_directory>`
`kubectl apply -f`

* `kubectl create namespace NAME`
* Apply `kubectl apply -k <kustomization directory>`

* Apps
  * MsSQL
    * 2019
      * `kubectl create namespace mssql2019`
      * `kubectl apply -k ./db/mssql/overlays/development/2019`
      * Host: `mssql2019.local(192.168.100.117)` Username: `testuser` Password: `passWord1`
    * 2022
      * `kubectl create namespace mssql2022`
      * `kubectl apply -k ./db/mssql/overlays/development/2022`
      * Host: `mssql2022.local(192.168.100.118)` Username: `testuser` Password: `passWord1`
    * 2025
      * `kubectl create namespace mssql2025`
      * `kubectl apply -k ./db/mssql/overlays/development/2025`
      * Host: `mssql2025.local(192.168.100.119)` Username: `testuser` Password: `passWord1`
  * Postgre
    * 16
      * `kubectl create namespace pg16`
      * `kubectl apply -k ./db/postgresql/overlays/development/16`
      * Host: `pg16.local(192.168.100.112)` Username: `testuser` Password: `passWord1`
    * 17
      * `kubectl create namespace pg17`
      * `kubectl apply -k ./db/postgresql/overlays/development/17`
      * Host: `pg17.local(192.168.100.113)` Username: `testuser` Password: `passWord1`
    * 18
      * `kubectl create namespace pg18`
      * `kubectl apply -k ./db/postgresql/overlays/development/18`
      * Host: `pg18.local(192.168.100.114)` Username: `testuser` Password: `passWord1`
    * pg-admin
      * `kubectl create namespace pgadmin`
      * `kubectl apply -k ./db/pg-admin/overlays/development`
      * Host: `pgadmin.local(192.168.100.111)` Username: `vlad.riabtsev@live.ca` Password: `passWord1`

