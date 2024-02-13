```sh
k3d cluster create kubefirst --agents "1" --agents-memory "4096m"

# todo  https://docs.k3s.io/helm#automatically-deploying-manifests-and-helm-charts
# consider creating a kubernetes job at a URL that will bootstrap this through a manifest (wrap it in a helm chart?)
kubectl kustomize https://github.com/kubefirst/navigate/2024-austin/manifests/argocd\?ref\=main | kubectl apply -f -

export CIVO_TOKEN=$CIVO_TOKEN
kubectl create ns crossplane-system 
kubectl -n crossplane-system create secret generic crossplane-secrets --from-literal=CIVO_TOKEN=$CIVO_TOKEN --from-literal=TF_VAR_civo_token=$CIVO_TOKEN
kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/sync-waves/bootstrap/bootstrap.yaml

# get the argocd root password
# visit the argocd ui

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/sync-waves/registry/registry.yaml

# watch the glory