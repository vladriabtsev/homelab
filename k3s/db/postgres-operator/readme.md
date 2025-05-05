# Postgres Operator from Crunchy Data

[Installation](https://access.crunchydata.com/documentation/postgres-operator/latest/quickstart)

Install:

* cd D:\dev\vSharpStudio.pro\1dev-env\k8s-dev\postgres-operator
* kubectl apply -k install/namespace
* kubectl apply --server-side -k install/default
* kubectl apply -k postgres

Uninstall:

* kubectl delete -k install/default
* kubectl delete -k install/singlenamespace
* delete StatefulSets, Pod, Job, Namespace

* [Get up and running with Postgres](https://www.crunchydata.com/developers)
* [Examples for Using PGO, the Postgres Operator from Crunchy Data](https://github.com/CrunchyData/postgres-operator-examples)
* [Crunchy Postgres for Kubernetes](https://access.crunchydata.com/documentation/postgres-operator/latest)