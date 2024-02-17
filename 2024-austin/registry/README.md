# navigate

CIVO Navigate Workshops

```sh
k3d cluster create kubefirst --agents "1" --agents-memory "4096m" \
    --volume $PWD/2024-austin/manifests/bootstrap-k3d.yaml:/var/lib/rancher/k3s/server/manifests/bootstrap-k3d.yaml

kubectl -n crossplane-system create secret generic crossplane-secrets --from-literal=CIVO_TOKEN=$CIVO_TOKEN --from-literal=TF_VAR_civo_token=$CIVO_TOKEN

# wait for argocd pods in k3d to be healthy
watch kubectl get pods -A

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/bootstrap/bootstrap.yaml

# get the argocd root password
# visit the argocd ui

2m16s61

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/registry/registry.yaml

# watch the registry in argocd ui

civo k8s config --region nyc1 north --save
civo k8s config --region lon1 south --save

#! north cluster 
kubectx north
linkerd --context=south multicluster link --cluster-name south |
  kubectl --context=north apply -f -

apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: north-metaphor-development-split
  namespace: development
spec:
  service: north-metaphor-development
  backends:
  - service: north-metaphor-development
    weight: 20
  - service: south-metaphor-development-south
    weight: 80

---------

#! south cluster 
kubectx south
linkerd --context=north multicluster link --cluster-name north |
  kubectl --context=south apply -f -

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
  - service: north-metaphor-development-north
    weight: 50



```
