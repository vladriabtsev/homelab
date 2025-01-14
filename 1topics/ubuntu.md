## nodes

sudo passwd USERNAME

sudo apt-get update
sudo apt-get upgrade

lsb_release -a # ubuntu version

<command> | more # 'space' for next page. 'q' - exit
<command> | less # 'PgUp' and 'PgDown'. 'q' - exit
uname -a # kernel version
ip -4 addr show # ip address edit /etc/netplan/01-netcfg.yaml or similar file
netstat -tulpn # open ports
df -ah # disk space
du -sh home # size of directory
ncdu # disk usage
systemctl status # services
ps aux | grep nginx # CPU usage
top
htop
ls /mnt
mount /dev/sda2 /mnt # mounts
/etc/fstab
man <command>

## postgre sql
https://hevodata.com/learn/postgresql-cluster/
https://www.postgresql.org/docs/current/sql-cluster.html
https://www.postgresql.org/docs/14/high-availability.html

## vim
https://www.youtube.com/watch?v=IiwGbcd8S7I
https://www.youtube.com/watch?v=XA2WjJbmmoM


## Microk8s
sudo snap install microk8s --classic --channel=1.20 # 1.19
sudo microk8s add-node
run generated command on other node to connect cluster

Working from Windows: 
  - Copy .kube\config in user's folder on Windows: https://microk8s.io/docs/working-with-kubectl 
  - Install kubectl for Windows. Run kubectl. Fore trubleshooting: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/

sudo watch microk8s kubectl get pods -A -o wide

get version
microk8s.kubectl get no

### Secrets
https://kubernetes.io/docs/tasks/inject-data-application/distribute-credentials-secure/
https://kubernetes.io/docs/concepts/configuration/secret/
kubectl create secret generic nfs-secret --from-literal='username=my-app' --from-literal='password=39528$vdg7Jb'
kubectl get secret nfs-secret
kubectl edit secrets nfs-secret

### External load balancer
https://github.com/metallb/metallb
https://metallb.universe.tf/usage/
sudo microk8s enable metallb 

kubectl get pod -n metallb-system
kubectl get pod -o wide -n metallb-system
kubectl get all -n metallb-system
kubectl get service
kubectl describe service nginx

kubectl get deployment -A
kubectl get deployment controller -n metallb-system -o yaml
kubectl get configmap config -n metallb-system -o yaml

### Deployment
https://kubernetes.io/docs/concepts/workloads/controllers/deployment/

### Storage
sudo microk8s enable storage

sudo watch microk8s kubectl get pods -A -o wide  # ^C^C to cancel

https://www.mirantis.com/blog/introduction-to-yaml-creating-a-kubernetes-deployment/
https://kubernetes.io/docs/reference/kubernetes-api/

### Registry
kubectl apply -f volume-hostpath-mck8s4-virt.yml
kubectl get pv
microk8s enable registry

#### Nginx
https://hub.docker.com/_/nginx
kubectl apply -f C:\dev\ops\kubernetes\deployments\nginx.yaml
kubectl get deployments
http://192.168.2.19/
kubectl delete -f nginx.yaml
### Dashboard
sudo microk8s enable dashboard
### DNS
sudo microk8s enable dns
### Istio
sudo microk8s enable istio
### iSCSI volume
