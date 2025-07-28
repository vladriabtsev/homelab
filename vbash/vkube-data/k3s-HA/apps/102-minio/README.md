# [MinIO](https://min.io/)

* [MinIO Quickstart Guide](https://github.com/minio/minio)
* [MinIO Client Quickstart Guide](https://github.com/minio/mc)
* [MinIO Operator](https://github.com/minio/operator/blob/master/README.md)
* [MinIO Object Storage for Kubernetes](https://min.io/docs/minio/kubernetes/upstream/index.html)
* [NFS Minio Operator](https://github.com/greenstatic/nfs-minio-operator) - sample of operator
* [DirectPV](https://github.com/minio/directpv)

Services

* S3

## Install

### Synology

[NFS](https://kb.synology.com/en-af/DSM/help/DSM/AdminCenter/file_winmacnfs_nfs?version=7)

Note:

* When mounting, the parameter -o vers=2, -o vers=3 or -o vers=4 can be added to the mount command in order to specify which NFS version should be used.
* When you use NFSv4 to mount the shared folder, please note the following. Otherwise, the file operations associated with the username will fail.
  * NFS client must enable idmapd.
  * NFSv4 domain settings in the idmapd.conf file on your NFS client must be consistent with the NFSv4 domain field on Synology NAS.

NFS user for minio: minio-user, qS4G+Zg9

NFS rule for shared folder

* Hostname: * # 192.168.100.0/24
* Privilege: Read/Write
* Squash: Map all users to admin

[How to access files on Synology NAS within the local network (NFS)](https://kb.synology.com/en-ca/DSM/tutorial/How_to_access_files_on_Synology_NAS_within_the_local_network_NFS)

[Test connection](https://linux.die.net/man/5/nfs)

* `sudo apt install nfs-common`
* `sudo mkdir -p /mnt/minio-volume`
* `sudo mount -t nfs [IPADDRESS]:[REMOTEVOLUME] [MOUNTPATH]`, `sudo mount -t nfs 192.168.100.221:/volume1/minio-volume /mnt/minio-volume`
* `df -h`, `du -sh /mnt/minio-volume`, `sudo touch /mnt/minio-volume/general.test`, `ls -l /mnt/minio-volume/general.test`
* `sudo umount /mnt/minio-volume`

### Kubernetes

* `kubectl create namespace minio`
* `kubectl apply -f ./102-minio/storage.yaml`
* `kubectl create secret generic SECRET_NAME --from-literal=root-user=USER --from-literal=root-password=PASSWORD --dry-run -o yaml | kubectl apply -f -`
* `helm install minio oci://registry-1.docker.io/bitnamicharts/minio --namespace minio`
* `helm delete minio`

[Setup MinIO Object Storage on Kubernetes. With Self-Signed certificates.](https://appdev24.com/pages/62/setup-minio-object-storage-on-kubernetes)

[Easy Guide: Setting Up Minio with MicroK8s Kubernetes(bitnami)](https://medium.com/@kapincev/easy-guide-setting-up-minio-with-microk8s-kubernetes-321048d901ac)

[Bitnami Object Storage based on MinIO(R)](https://github.com/bitnami/charts/tree/main/bitnami/minio)

[Object Storage in your Kubernetes cluster using MinIO](https://medium.com/@martin.hodges/object-storage-in-your-kubernetes-cluster-using-minio-ad838decd9ce)

[What is MinIO and How to Configure It in Kubernetes + RabbitMQ](https://faun.pub/what-is-minio-and-how-to-configure-it-in-kubernetes-18072ac80fb2)

Minio blogs

* [MinIO as Helm Chart Repository](https://blog.min.io/helm-chart-repository/)
* [YouTube Summaries: Kubernetes and the MinIO Operator](https://blog.min.io/youtube-summaries-kubernetes-and-the-minio-operator/)
* [How to deploy MinIO with ArgoCD in Kubernetes](https://blog.min.io/deploy-minio-with-argocd-in-kubernetes/)
* [Streamline Certificate Management with MinIO Operator](https://blog.min.io/certificate-management-minio-operator/)
* [CI/CD Deploy with MinIO distributed cluster on Kubernetes](https://blog.min.io/ci-cd-distributed-cluster-kubernetes/)
* [https://blog.min.io/minio-nginx-letsencrypt-certbot/](How to Use Nginx, LetsEncrypt and Certbot for Secure Access to MinIO)
* [Debugging MinIO Installs](https://blog.min.io/debugging-minio-installs/)
* [Exploring Kubernetes v1.30: Enhancements Relevant to MinIO Deployments](https://blog.min.io/kubernetes-v1-30-enhancements/)


[Deploy the MinIO Operator](https://min.io/docs/minio/kubernetes/upstream/operations/installation.html)

[Deploy and Manage MinIO Storage on Kubernetes](https://computingforgeeks.com/deploy-and-manage-minio-storage-on-kubernetes/)

[MinIO S3](https://github.com/sleighzy/k3s-minio-deployment)

[Configure NFS as Kubernetes Persistent Volume Storage]()

[Install on Kubernetes](https://docs.gitea.com/installation/install-on-kubernetes)

NFS volume

[NFS volume examples](https://github.com/kubernetes/examples/tree/master/staging/volumes/nfs)

Installation
* helm repo add gitea-charts https://dl.gitea.com/charts/
* helm repo update
* kubectl create namespace gitea
* helm install gitea gitea-charts/gitea -n gitea
* helm uninstall gitea
* kubectl apply -f ./103-gitea/svc.yaml

vlad Q0

[Gitea Helm Chart](https://gitea.com/gitea/helm-chart/)

[Configuration Cheat Sheet](https://docs.gitea.com/administration/config-cheat-sheet)
