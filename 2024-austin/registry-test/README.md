# navigate

CIVO Navigate Workshops

```sh
k3d cluster create kubefirst --agents "1" --agents-memory "4096m" \
    --volume $PWD/2024-austin/manifests/bootstrap-k3d.yaml:/var/lib/rancher/k3s/server/manifests/bootstrap-k3d.yaml

export CIVO_TOKEN
kubectl -n crossplane-system create secret generic crossplane-secrets --from-literal=CIVO_TOKEN=$CIVO_TOKEN --from-literal=TF_VAR_civo_token=$CIVO_TOKEN

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/bootstrap/bootstrap.yaml

# get the argocd root password
# visit the argocd ui

kubectl apply -f https://raw.githubusercontent.com/kubefirst/navigate/main/2024-austin/registry-test/registry.yaml

# watch the glory
```



linkerd addition notes:
- need to remove certs from 2024-austin/registry/clusters/cluster-london/linkerd/components/control-plane/control-plane.yaml
- upgrade linkerd
