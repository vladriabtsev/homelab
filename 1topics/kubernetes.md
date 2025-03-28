<!-- markdownlint-disable MD004 -->
# Kubernetes

<!-- @import "[TOC]" {cmd="toc" depthFrom=1 depthTo=6 orderedList=false} -->

<!-- code_chunk_output -->

- [Kubernetes](#kubernetes)
  - [kubectl](#kubectl)
  - [Disaster recovery plan](#disaster-recovery-plan)
  - [Minikube](#minikube)
  - [Secrets](#secrets)
  - [Storage](#storage)
  - [Gateways](#gateways)
  - [dashboard](#dashboard)
  - [Docker](#docker)
    - [NET in Docker](#net-in-docker)
    - [Kubernetes in Docker (Kind)](#kubernetes-in-docker-kind)

<!-- /code_chunk_output -->

https://cinaq.com/blog/2020/05/25/highly-available-kubernetes-with-batteries-for-small-business/

Virtual IP/Failover https://www.youtube.com/watch?v=bXQ0HvsWI60 
https://github.com/acassen/keepalived 
https://keepalived.readthedocs.io/en/latest/configuration_synopsis.html
https://vexxhost.com/resources/tutorials/highly-available-web-servers-keepalived-floating-ips-ubuntu-16-04/
https://www.evidian.com/products/high-availability-software-for-application-clustering/how-a-virtual-ip-address-works/

Kubernetes https://www.youtube.com/watch?v=X48VuDVv0do
Docker https://www.youtube.com/watch?v=3c-iBn73dDE
Prometheus https://www.youtube.com/watch?v=h4Sl21AKiDg
Docker and Kubernetes https://www.youtube.com/watch?v=bhBSlnQcq2k
Istio https://www.youtube.com/watch?v=voAyroDb6xk
Loft https://www.youtube.com/watch?v=tt7hope6zU0
https://loft.sh/

https://kubernetes.io/blog/2020/05/21/wsl-docker-kubernetes-on-the-windows-desktop/
https://github.com/kata-containers/packaging/tree/master/kata-deploy#kubernetes-quick-start
https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

## kubectl

[kubectl Quick Reference](https://kubernetes.io/docs/reference/kubectl/quick-reference/)

[Kubernetes Objects and Kubectl Command Cheatsheet](https://spacelift.io/blog/kubernetes-cheat-sheet)

``` bash
kubectl get pods -n=cattle-system -o=yaml

```

## Disaster recovery plan

https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster
https://velero.io/
https://www.baculasystems.com/blog/kubernetes-backup/
https://www.bluematador.com/blog/kubernetes-disaster-prevention-and-recovery
https://containerjournal.com/topics/disaster-recovery-for-kubernetes/
https://rancher.com/blog/2020/disaster-recovery-preparedness-kubernetes-clusters
https://thenewstack.io/how-to-make-up-for-kubernetes-disaster-recovery-shortfalls/

## Minikube

https://github.com/kubernetes/minikube

## Secrets

* [Kubernetes Secrets – How to Create, Use, and Manage](https://spacelift.io/blog/kubernetes-secrets)
* [Kubernetes Secrets: How to Create, Use, and Manage Secrets in Kubernetes](https://medium.com/@subhampradhan966/kubernetes-secrets-how-to-create-use-and-manage-secrets-in-kubernetes-a23663a81d26)
* [](https://medium.com/@ravipatel.it/mastering-kubernetes-secrets-a-comprehensive-guide-b0304818e32b)

## Storage

https://longhorn.io/
https://www.youtube.com/watch?v=BnHMAJ8azBU
https://github.com/longhorn/longhorn
https://kubernetes.io/docs/concepts/storage/volumes/

- hostPath
- iscsi https://github.com/kubernetes/examples/tree/master/volumes/iscsi
- local
- nfs https://github.com/kubernetes/examples/tree/master/staging/volumes/nfs
  https://www.youtube.com/watch?v=Sj0MVk0jM_4  
  https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
  https://github.com/kubernetes-sigs/nfs-ganesha-server-and-external-provisioner
  https://www.youtube.com/watch?v=AavnQzWDTEk

- persistentVolumeClaim
- projected
- secret 
- flexvolume https://github.com/microsoft/K8s-Storage-Plugins
Using subPath

## Gateways

https://thenewstack.io/why-do-you-need-istio-when-you-already-have-kubernetes/
https://istio.io/latest/docs/reference/config/networking/gateway/
https://www.envoyproxy.io/

## dashboard

https://k8dash.io/

## Docker

### NET in Docker

https://www.youtube.com/watch?v=kgfg8r6_zPk
https://devspace.sh/
https://www.youtube.com/watch?v=_f8QfKx4rws
https://www.shipa.io/
https://www.youtube.com/watch?v=sstOXCQ-EG0
https://devblogs.microsoft.com/dotnet/cloud-native-learning-resources-for-net-developers/
https://dzone.com/articles/top-20-dockerfile-best-practices?edition=665391&utm_medium=email&utm_source=dzone&utm_content=Top%2020%20Dockerfile%20Best%20Practices&utm_campaign=

### Kubernetes in Docker (Kind)

https://dzone.com/articles/goodbye-minikube?edition=663395
https://kind.sigs.k8s.io/docs/user/quick-start/
https://kind.sigs.k8s.io/docs/user/ingress/
