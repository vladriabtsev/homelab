# Argo CD

## Test

### Test kube-vip with nginx

[HA Kubernetes Cluster with RKE2 & kube-vip](https://gist.github.com/dmancloud/70573c89961c692e4faf6f1fd1c04087)

[kube-vip - Service LoadBalancer using leader election (ARP)](https://gist.github.com/dmancloud/3bdb3fdf2eaa3e2d42428f4a90de67a9)

Verify Loadbalancer Is Working

* kubectl create deploy nginx --image=nginx:stable-alpine
* kubectl expose deploy nginx --port=80 -type-LoadBalancer
* kubectl get service
* curl http://<IP_Address>

### Test kube-vip with argocd

* Service: argocd-server
* Get services `kubectl get service -n argocd` and find argocd-server ClusterIP

From cluster node:

* `curl http://argocd-server-cluster-ip`
* `curl -k https://argocd-server-cluster-ip`

From external LAN PC:

* Not working: `curl http://argocd-server-cluster-ip`, ClusterIP is accessible only from cluster only

kubectl expose deploy argocd-server --port=80 -type-LoadBalancer



* [Argo CD Git Webhook Configuration](https://gist.github.com/dmancloud/9075440f64ab262d10093b1a8d724fd2)
* [ArgoCD Installation on Kubernetes : Step-by-Step Guide](https://www.youtube.com/watch?v=fBd_tz6BALU)
* [ArgoCD Installation Part 2 - Quick Start](https://gist.github.com/dmancloud/7a024aa0e47fd39bd0db6e80a4aae842)
