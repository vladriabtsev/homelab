# [cert-manager](https://github.com/cert-manager/cert-manager)

## Let's Encrypt

[Let's Encrypt Challenge Types](https://letsencrypt.org/docs/challenge-types/)

[How to get free SSL/TLS certificates with Let’s Encrypt and Certbot](https://linuxconfig.org/how-to-get-free-ssl-tls-certificates-with-lets-encrypt-and-certbot)

[Quick and Easy Local SSL Certificates for Your Homelab!](https://www.youtube.com/watch?v=qlcVx-k-02E)
[Nginx Proxy Manager](https://nginxproxymanager.com/)

* DNS-01 challenge allows you to issue wildcard certificates.
  * kk

DSM office. Control Panel->Login Portal->Advanced->Reverse Proxy:

* Create proxy record
  * Reverse Proxy Name: `vladnet for Let's Encrypt`
  * Source Protocol: `HTTP`
  * Source Hostname: `vladnet.ca`
  * Source Port: `80`
  * Destination Protocol: `HTTP`
  * Destination Hostname: `192.168.100.104`
  * Destination Port: `80`

## cert-manager

Latest: 1.16.3
Previous: 1.15.5

[Free SSL Certs in Kubernetes! Cert Manager Tutorial](https://www.youtube.com/watch?v=DvXkD0f-lhY)
[The Let's Encrypt ACME](https://letsencrypt.org/getting-started/)

* [Installing cert-manager with Helm](https://cert-manager.io/docs/installation/helm/)
* [Uninstalling](https://cert-manager.io/docs/installation/helm/#uninstalling)
  * Check that all cert-manager resources that have been created by users have been deleted `kubectl get Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders,Challenges --all-namespaces` ???
  * remove all Issuers,ClusterIssuers,Certificates,CertificateRequests,Orders and Challenges resources from the cluster `kubectl delete crd issuers.cert-manager.io clusterissuerscert-manager.io certificates.cert-manager.io certificaterequests.cert-manager.io orders.acme.cert-manager.io challenges.acme.cert-manager.io` ???
  * Uninstall `helm uninstall cert-manager -n cert-manager`
  * Namespace Stuck in Terminating State `kubectl delete apiservice v1beta1.webhook.cert-manager.io`
* Upgrade: `helm upgrade --reset-then-reuse-values --version <version> <release_name> jetstack/cert-manager`

* Restore: `???`
* Backup: `???`

