# navigate

CIVO Navigate Workshop with Cloudflare Origin CA Issuer


## Create a local k3d cluster to run your Infrastructure as Code

The `k3d` cluster will run on your local machine and will automatically get argocd installed to it. 
```sh
k3d cluster create kubefirst --agents "1" --agents-memory "4096m" \
    --volume $PWD/2024-austin/manifests/bootstrap-k3d.yaml:/var/lib/rancher/k3s/server/manifests/bootstrap-k3d.yaml

# create a secret that will be leveraged by crossplane's terraform provider



# wait for argocd pods in k3d to be healthy
watch kubectl get pods -A

# get the argocd root password
# visit the argocd ui

# install crossplane and the terraform provider tooling to make magic
kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/bootstrap/bootstrap.yaml

# apply the registry to create new infra and bootstrap it
kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/cloudflare/2024-austin/registry-cloudflare/registry.yaml

# watch the registry in argocd ui

civo k8s config --region lon1 dublin --save
civo k8s config --region nyc1 denver --save

#deprecated, test new provision
# goes to development namespace in workloads
apiVersion: cert-manager.k8s.cloudflare.com/v1
kind: OriginIssuer
metadata:
  name: cloudflare-origin-issuer
  namespace: development
spec:
  requestType: OriginECC
  auth:
    serviceKeyRef:
      key: origin-ca-api-key
      name: cloudflare-secrets

# link the dublin cluster to the denver cluster, dublin is the source cluster"
kubectx dublin
linkerd --context=denver multicluster link --cluster-name denver |
  kubectl --context=dublin apply -f -

# apply to the dublin cluster development namespace to show traffic switching
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: dublin-metaphor-development-split
  namespace: development
spec:
  service: dublin-metaphor-development
  backends:
  - service: dublin-metaphor-development
    weight: 90
  - service: denver-metaphor-development-denver
    weight: 10

---------
# warning: remove traffic split in dublin before applying one in denver or you can fall into an infinite loop
# link the denver cluster to the dublin cluster, denver is the source cluster"
kubectx denver
linkerd --context=dublin multicluster link --cluster-name dublin |
  kubectl --context=denver apply -f -

# apply to the denver cluster development namespace to show traffic switching
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: denver-metaphor-development-split
  namespace: development
spec:
  service: denver-metaphor-development
  backends:
  - service: denver-metaphor-development
    weight: 50
  - service: dublin-metaphor-development-dublin
    weight: 50

```


---

# CIVO Navigate Workshops CIVO dns

### prerequisites
- k3d
- kubectl
- linkerd
- civo token
- dns

### clone the `navigate` git repository
```sh
git clone https://github.com/kubefirst/navigate
cd navigate
```

### create a local `k3d` cluster to provision cloud infrastructure with gitops
We'll provision a local k3d cluster that will need a `CIVO_TOKEN` added as a kubernetes secret. This `k3d` cluster will also have a few additional [manifests](../manifests/bootstrap-k3d.yaml) that install argocd to the new cluster with a few default configurations we'll take advantage of.
```sh
k3d cluster create kubefirst --agents "1" --agents-memory "4096m" \
    --volume $PWD/2024-austin/manifests/bootstrap-k3d.yaml:/var/lib/rancher/k3s/server/manifests/bootstrap-k3d.yaml
```

### add your `CIVO_TOKEN`, `CLOUDFLARE_API_TOKEN`,  and `CLOUDFLARE_ORIGIN_CA_KEY` for provisioning cloud infrastructure and managing DNS
The `CIVO_TOKEN` will be used by the crossplane terraform provider to allow for provisioning of CIVO cloud infrastructure as well as for external-dns to create and adjust DNS records in your CIVO cloud account. The `CLOUDFLARE_API_TOKEN` will be used to manage DNS records in your Cloudflare zone and `CLOUDFLARE_ORIGIN_CA_KEY` will be used by the Cloudflare Origin CA Issuer controller to get certificates for TLS communication of the metaphor service.
```sh
kubectl -n crossplane-system create secret generic crossplane-secrets \
  --from-literal=CIVO_TOKEN=$CIVO_TOKEN \
  --from-literal=TF_VAR_civo_token=$CIVO_TOKEN \
  --from-literal=TF_VAR_cloudflare_api_token=$CLOUDFLARE_API_TOKEN \
  --from-literal=TF_VAR_cloudflare_origin_issuer_token=$CLOUDFLARE_ORIGIN_CA_KEY
```

### wait for argocd pods in k3d to be running
```sh
watch kubectl get pods -A
```
### get the argocd root password
```sh
kubectl -n argocd get secret/argocd-initial-admin-secret -ojsonpath='{.data.password}' | base64 -D | pbcopy
```
### visit the argocd ui
```sh
kubectl -n argocd port-forward svc/argocd-server 8888:80 
open http://localhost:8888
```

### bootstrap the `k3d` cluster with crossplane and install the terraform provider
```sh
kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/bootstrap/bootstrap.yaml
```

### apply the registry to provision new cloud infrastructure and bootstrap the cloud clusters
```sh
kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/registry/registry.yaml
```

### watch the registry in argocd ui
once the $cluster-infrastrucutre sync waves have completed, its a good time to get the kubeconfig files for the two clusters so we can interact with them
```sh
civo k8s config --region nyc1 north --save
civo k8s config --region lon1 south --save
```

### what just happened?
we just created to new CIVO kubernetes clusters in multiple regions using Infrastructure as Code. Once the new clusters were ready, we used the Argo CD gitops engine to install a handfull of applications to make them ready to serve application traffic on the internet leveraging your dns zone. 
(working...)

### explore metaphor, your new demo application running in both clusters
```sh
open https://metaphor.com
```

### link the north cluster with the south
this command will take the necessary information from each kubeconfig and install a `Link` resource that will allow for traffic switching using the linkerd-smi `TrafficSplit`
```sh
kubectx north
linkerd --context=south multicluster link --cluster-name south |
  kubectl --context=north apply -f -
```

### traffic splitting between your mirrored services
```sh
cat <<EOF | kubectl apply -f -
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: north-metaphor-development-split
  namespace: development
spec:
  service: north-metaphor-development
  backends:
  - service: north-metaphor-development
    weight: 0
  - service: south-metaphor-development-south
    weight: 100
EOF
```

### link the south cluster with the north

this command will take the necessary information from each kubeconfig and install a `Link` resource that will allow for traffic switching using the linkerd-smi `TrafficSplit`
```sh
kubectx south
linkerd --context=north multicluster link --cluster-name north |
  kubectl --context=south apply -f -
```

### traffic splitting between your mirrored services
```sh
cat <<EOF | kubectl apply -f -
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: south-metaphor-development-split
  namespace: development
spec:
  service: south-metaphor-development
  backends:
  - service: south-metaphor-development
    weight: 0
  - service: north-metaphor-development-north
    weight: 100
EOF
```