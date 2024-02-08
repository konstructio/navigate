# navigate

CIVO Navigate Workshops

```sh
k3d cluster create kubefirst --agents "3" --agents-memory "1024m"

# https://docs.k3s.io/helm#automatically-deploying-manifests-and-helm-charts
# consider creating a kubernetes job at a URL that will bootstrap this through a manifest (wrap it in a helm chart?)
kubectl kustomize https://github.com/kubefirst/navigate/manifests/argocd\?ref\=main | kubectl apply -f -
#! todo manifest
kubectl create ns crossplane-system 
export CIVO_TOKEN
kubectl -n crossplane-system create secret generic crossplane-secrets --from-literal=CIVO_TOKEN=$CIVO_TOKEN --from-literal=TF_VAR_civo_token=$CIVO_TOKEN

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/bootstrap/bootstrap.yaml

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/registry/registry.yaml
```