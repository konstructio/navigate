
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

### add your `CIVO_TOKEN` for provisioning cloud infrastructure
The `CIVO_TOKEN` will be used by the crossplane terraform provider to allow for provisioning of CIVO cloud infrastructure as well as for external-dns to create and adjust DNS records in your CIVO cloud account.
```sh
kubectl -n crossplane-system create secret generic crossplane-secrets \
  --from-literal=CIVO_TOKEN=$CIVO_TOKEN \
  --from-literal=TF_VAR_civo_token=$CIVO_TOKEN
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
civo k8s config --region nyc1 newyork --save
civo k8s config --region lon1 london --save
```

### what just happened?
we just created to new CIVO kubernetes clusters in multiple regions using Infrastructure as Code. Once the new clusters were ready, we used the Argo CD gitops engine to install a handfull of applications to make them ready to serve application traffic on the internet leveraging your dns zone. 
(working...)

### explore metaphor, your new demo application running in both clusters
```sh
open https://metaphor.com
```

### link the newyork cluster with the london
this command will take the necessary information from each kubeconfig and install a `Link` resource that will allow for traffic switching using the linkerd-smi `TrafficSplit`
```sh
kubectx newyork
linkerd --context=london multicluster link --cluster-name london |
  kubectl --context=newyork apply -f -
```

### traffic splitting between your mirrored services
```sh
cat <<EOF | kubectl apply -f -
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: newyork-metaphor-development-split
  namespace: development
spec:
  service: newyork-metaphor-development
  backends:
  - service: newyork-metaphor-development
    weight: 0
  - service: london-metaphor-development-london
    weight: 100
EOF
```

### link the london cluster with the newyork

this command will take the necessary information from each kubeconfig and install a `Link` resource that will allow for traffic switching using the linkerd-smi `TrafficSplit`
```sh
kubectx london
linkerd --context=newyork multicluster link --cluster-name newyork |
  kubectl --context=london apply -f -
```

### traffic splitting between your mirrored services
```sh
cat <<EOF | kubectl apply -f -
apiVersion: split.smi-spec.io/v1alpha2
kind: TrafficSplit
metadata:
  name: london-metaphor-development-split
  namespace: development
spec:
  service: london-metaphor-development
  backends:
  - service: london-metaphor-development
    weight: 0
  - service: newyork-metaphor-development-newyork
    weight: 100
EOF
```