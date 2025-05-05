# Postgre SQL

* [](https://medium.com/@PlanB./postgresql-on-kubernetes-dos-don-ts-and-operator-solutions-e680a3b9237d)
* [How to Deploy PostgreSQL Statefulset in Kubernetes With High Availability](https://devopscube.com/deploy-postgresql-statefulset/)
* [Running PostgreSQL in Kubernetes (Basic)](https://github.com/marcel-dempers/docker-development-youtube-series/blob/master/storage/databases/postgresql/4-k8s-basic/README.md)
* [Examples for Using PGO, the Postgres Operator from Crunchy Data](https://github.com/CrunchyData/postgres-operator-examples/blob/main/README.md)
* [statefulset](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)
* [postgresql statefulset](https://devopscube.com/deploy-postgresql-statefulset/)
* [postgres statefulset](https://github.com/arianitu/postgres-statefulset)

General links
* [Postgres 17 Released, optimizations](https://www.youtube.com/watch?v=7Re4SXMTbZI)
* [optimizations](https://www.youtube.com/playlist?list=PLdTaEgcmPg9Kl539gyIFtWL0-cqk3m7v9)
* [PostgreSQL 16.4 Documentation](https://www.postgresql.org/docs/current/)
* [PostgreSQL Docker Community](https://github.com/docker-library/postgres)
* [Docker Official Images](https://github.com/docker-library/official-images)
* [operatorhub](https://operatorhub.io/)
  * [Crunchy Postgres for Kubernetes](https://operatorhub.io/operator/postgresql/v5/postgresoperator.v5.6.0)
  * [Postgres-Operator](https://operatorhub.io/operator/postgres-operator)
  * [CloudNativePG](https://operatorhub.io/operator/cloudnative-pg)
* [How to Deploy PostgreSQL Statefulset in Kubernetes With High Availability](https://devopscube.com/deploy-postgresql-statefulset/)
* [PostgreSql kubernetes](https://github.com/marcel-dempers/docker-development-youtube-series/tree/master/storage/databases/postgresql)
* [Running PostgreSQL in Kubernetes (Basic)](https://github.com/marcel-dempers/docker-development-youtube-series/tree/master/storage/databases/postgresql/4-k8s-basic)
* [Setting up Postgres with replication using Kubernetes](https://stacksoft.io/blog/postgres-statefulset/)

cd d:
cd D:/dev/vSharpStudio.pro/1dev-env/k8s-dev/postgre/

[bitnami postgresql helm charts](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)
[bitnami postgresql tags](https://hub.docker.com/r/bitnami/postgresql/tags)

192.168.2.233:5432 postgre:latest
192.168.2.233:30516 postgre:16
192.168.2.233:5430 postgre:15

####### Postgre 16.4.0

Install
* kubectl create namespace postgresql16
* helm install postgresql16 -f 16.yaml --namespace postgresql16 oci://registry-1.docker.io/bitnamicharts/postgresql
* kubectl port-forward --namespace postgresql16 svc/postgresql16 5431:5432
* PGPASSWORD="$POSTGRES_PASSWORD" 
* psql --host 127.0.0.1 -U postgres -d postgre -p 5431

helm uninstall postgresql16 --namespace postgresql16

PostgreSQL can be accessed via port 5432 on the following DNS names from within your cluster:

    postgresql16.postgresql16.svc.cluster.local - Read/Write connection

To get the password for "postgres" run:

    export POSTGRES_PASSWORD=$(kubectl get secret --namespace postgresql16 postgresql16 -o jsonpath="{.data.postgres-password}" | base64 -d)

To connect to your database run the following command:

    kubectl run postgresql16-client --rm --tty -i --restart='Never' --namespace postgresql16 --image docker.io/bitnami/postgresql:16.4.0-debian-12-r4 --env="PGPASSWORD=$POSTGRES_PASSWORD" \
      --command -- psql --host postgresql16 -U postgres -d postgre -p 5432

    > NOTE: If you access the container using bash, make sure that you execute "/opt/bitnami/scripts/postgresql/entrypoint.sh /bin/bash" in order to avoid the error "psql: local user with ID 1001} does not exist"

To connect to your database from outside the cluster execute the following commands:

    kubectl port-forward --namespace postgresql16 svc/postgresql16 5432:5432 &
    PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgre -p 5432


####### Postgre 15.4.0

helm install postgresql15 -f 15.yaml oci://registry-1.docker.io/bitnamicharts/postgresql

