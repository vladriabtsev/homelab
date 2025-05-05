# DNS

[PiHole on kubernetes](https://github.com/MoJo2600/pihole-kubernetes/blob/main/classic)

## Pi-hole

[Highly available Pi-hole setup in Kubernetes with secure DNS over HTTPS DoH](https://chriskirby.net/highly-available-pi-hole-setup-in-kubernetes-with-secure-dns-over-https-doh/)

[Run pi-hole in kubernetes cluster](https://kaievans.co/posts/iNGVk)

* `kubectl create namespace pihole`
* `kubectl -n pihole create secret generic pihole-admin --from-literal='password=[THE SUPER SECRET PASSWORD]'`
* `helm repo add mojo2600 https://mojo2600.github.io/pihole-kubernetes/`
* `helm repo update`
* `helm install pihole mojo2600/pihole -f ./111-pi-hole/values.yaml -n pihole`
* `helm upgrade -i pihole mojo2600/pihole -f ./111-pi-hole/values.yaml`
* `kubectl apply -f ./111-pi-hole/svc.yaml`
* `helm uninstall pihole -n pihole`

[Synology Pi-hole Docker and VLANs (Ubiquiti UniFi / Macvlan)](https://www.youtube.com/watch?v=Ne__c12Cp2g)

[Pi-hole v6 - Configuration and Overview](https://www.youtube.com/watch?v=mnry95ay0Bk)

[The ULTIMATE Pi-hole Setup? (Pi-hole, Unbound, Nebula Sync, Keepalived)](https://www.youtube.com/watch?v=6sznCZ7ttbI)

[Install Pi-hole on kubernetes](https://github.com/sean-foley/pihole-k8-public)

[external-dns](https://github.com/kubernetes-sigs/external-dns/tree/master)

[pi-hole](https://github.com/pi-hole/pi-hole/#one-step-automated-install)

[Pi-hole](https://pi-hole.net/)

[Network-wide ad blocking with Pi-hole, Kubernetes, and Raspberry Pi](https://github.com/santisbon/pi-hole-k8s)

[Pi-Hole Using Your Own Recursive DNS Server](https://gist.github.com/dmancloud/8d3e706bbe47cb1fb920583cab900336)