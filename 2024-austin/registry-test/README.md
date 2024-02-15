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

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/registry-test/registry.yaml
# watch the registry in argocd ui

civo k8s config --region nyc1 north --save
civo k8s config --region lon1 south --save

kubectx north
linkerd --context=south multicluster link --cluster-name south |
  kubectl --context=north apply -f -
---
#! experimental 
#! enabled ingress in south 
kubectx south
linkerd --context=north multicluster link --cluster-name north |
  kubectl --context=south apply -f -
---
#! north cluster 
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: north-metaphor-development-split
  namespace: development
spec:
  service: north-metaphor-development
  backends:
  - service: north-metaphor-development
    weight: 50
  - service: south-metaphor-development-south
    weight: 50

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
    weight: 0
  - service: north-metaphor-development-north
    weight: 100



```
3:28
