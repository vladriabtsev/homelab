# Traefik expose dashboard

[Definitions](https://doc.traefik.io/traefik/reference/dynamic-configuration/kubernetes-crd/#definitions)

Dashboard:
* Create Traefik Service `kubectl expose deploy traefik -n kube-system --name traefik-svc`
* Patch traefik service type to nodeport 
  * `kubectl patch svc -n kube-system traefik-svc --type='json' -p='[{"op": "replace", "path": "/spec/type", "value":"NodePort"}]'`
  * `kubectl patch svc -n kube-system traefik-svc --type='json' -p='[{"op": "replace", "path": "/spec/ports/1/nodePort", "value":31000}]'`
* Check Dashboard nodeport `kubectl get svc -n kube-system traefik-svc`
* Access Dashboard http://localhost:31000/dashboard/


* [Wildcard Certificates with Traefik + cert-manager + Let's Encrypt in Kubernetes Tutorial](https://gist.github.com/dmancloud/b22a50c662194e216317710efa4d4ed8)
