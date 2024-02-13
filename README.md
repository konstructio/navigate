# navigate

CIVO Navigate Workshops

```sh
k3d cluster create kubefirst --agents "1" --agents-memory "4096m"

# https://docs.k3s.io/helm#automatically-deploying-manifests-and-helm-charts
# consider creating a kubernetes job at a URL that will bootstrap this through a manifest (wrap it in a helm chart?)
kubectl kustomize https://github.com/kubefirst/manifests/argocd/demo\?ref\=main | kubectl apply -f -
#! todo manifest

export CIVO_TOKEN
kubectl create ns crossplane-system 
kubectl -n crossplane-system create secret generic crossplane-secrets --from-literal=CIVO_TOKEN=$CIVO_TOKEN --from-literal=TF_VAR_civo_token=$CIVO_TOKEN
kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/bootstrap/bootstrap.yaml

# get the argocd root password
# visit the argocd ui

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/registry/registry.yaml

# watch the glory
```



linkerd addition notes:
- need to remove certs from 2024-austin/registry/clusters/cluster-london/linkerd/components/control-plane/control-plane.yaml
- upgrade linkerd
