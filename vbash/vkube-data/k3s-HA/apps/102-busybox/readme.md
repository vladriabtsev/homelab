# Busybox

* [Busybox base image](https://hub.docker.com/_/busybox)
* [Debugging MinIO Installs](https://blog.min.io/debugging-minio-installs/)
* [Kubernetes Secrets: How to Create, Use, and Manage Secrets in Kubernetes](https://medium.com/@subhampradhan966/kubernetes-secrets-how-to-create-use-and-manage-secrets-in-kubernetes-a23663a81d26)

* `kubectl create namespace development`
* `kubectl create secret generic SECRET_NAME --from-literal=root-user=USER --from-literal=root-password=PASSWORD --dry-run -o yaml | kubectl apply -f -`
* `kubectl apply -k ./102-busybox/overlays/development`