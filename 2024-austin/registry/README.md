# navigate

CIVO Navigate Workshops

```sh
k3d cluster create kubefirst --agents "1" --agents-memory "4096m" \
    --volume $PWD/2024-austin/manifests/bootstrap-k3d.yaml:/var/lib/rancher/k3s/server/manifests/bootstrap-k3d.yaml

kubectl -n crossplane-system create secret generic crossplane-secrets \
  --from-literal=CIVO_TOKEN=$CIVO_TOKEN \
  --from-literal=TF_VAR_civo_token=$CIVO_TOKEN \
  --from-literal=TF_VAR_cloudflare_api_token=$CLOUDFLARE_API_TOKEN \
  --from-literal=TF_VAR_cloudflare_origin_issuer_token=$CLOUDFLARE_ORIGIN_CA_KEY


# wait for argocd pods in k3d to be healthy
watch kubectl get pods -A

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/bootstrap/bootstrap.yaml

# get the argocd root password
# visit the argocd ui

2m16s61

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/cloudflare/2024-austin/registry/registry.yaml

helm install -n cert-manager --name origin-ca-issuer oci://ghcr.io/cloudflare/origin-ca-issuer-charts/origin-ca-issuer --version 0.5.2


# watch the registry in argocd ui

civo k8s config --region nyc1 dublin --save
civo k8s config --region lon1 south --save

kubectx dublin
linkerd --context=south multicluster link --cluster-name south |
  kubectl --context=dublin apply -f -

#! dublin cluster 
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: dublin-metaphor-development-split
  namespace: development
spec:
  service: dublin-metaphor-development
  backends:
  - service: dublin-metaphor-development
    weight: 20
  - service: south-metaphor-development-south
    weight: 80

---------

kubectx south
linkerd --context=dublin multicluster link --cluster-name dublin |
  kubectl --context=south apply -f -

#! south cluster 
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: south-metaphor-development-split
  namespace: development
spec:
  service: south-metaphor-development
  backends:
  - service: south-metaphor-development
    weight: 50
  - service: dublin-metaphor-development-dublin
    weight: 50





```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: origin-ca-issuer-repository
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
type: Opaque
stringData:
  url: ghcr.io/cloudflare/origin-ca-issuer-charts/origin-ca-issuer
  name: origin-ca-issuer
  type: helm
  enableOCI: "true"
---
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

```