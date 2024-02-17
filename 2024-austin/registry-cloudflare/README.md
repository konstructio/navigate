# navigate

CIVO Navigate Workshop with Cloudflare Origin CA Issuer


## Create a local k3d cluster to run your Infrastructure as Code

The `k3d` cluster will run on your local machine and will automatically get argocd installed to it. 
```sh
k3d cluster create kubefirst --agents "1" --agents-memory "4096m" \
    --volume $PWD/2024-austin/manifests/bootstrap-k3d.yaml:/var/lib/rancher/k3s/server/manifests/bootstrap-k3d.yaml

# create a secret that will be leveraged by crossplane's terraform provider
kubectl -n crossplane-system create secret generic crossplane-secrets \
  --from-literal=CIVO_TOKEN=$CIVO_TOKEN \
  --from-literal=TF_VAR_civo_token=$CIVO_TOKEN \
  --from-literal=TF_VAR_cloudflare_api_token=$CLOUDFLARE_API_TOKEN \
  --from-literal=TF_VAR_cloudflare_origin_issuer_token=$CLOUDFLARE_ORIGIN_CA_KEY


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