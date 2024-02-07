variable "instance_size" {
  type    = string
  default = "g4s.kube.medium"
}

variable "node_count" {
  type    = string
}

variable "cluster_name" {
  type    = string
}

resource "civo_network" "cluster" {
  label = var.cluster_name
}

resource "civo_firewall" "cluster" {
  name                 = var.cluster_name
  network_id           = civo_network.cluster.id
  create_default_rules = true
}

resource "civo_kubernetes_cluster" "cluster" {
  name        = var.cluster_name
  network_id  = civo_network.cluster.id
  firewall_id = civo_firewall.cluster.id
  pools {
    label      = var.cluster_name
    size       = var.instance_size
    node_count = tonumber(var.node_count)
  }
}

resource "vault_generic_secret" "clusters" {
  path = "secret/clusters/${var.cluster_name}"

  data_json = jsonencode(
    {
      kubeconfig              = civo_kubernetes_cluster.cluster.kubeconfig
      client_certificate      = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).users[0].user.client-certificate-data)
      client_key              = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).users[0].user.client-key-data)
      cluster_ca_certificate  = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
      host                    = civo_kubernetes_cluster.cluster.api_endpoint
      cluster_name            = var.cluster_name
      argocd_manager_sa_token = kubernetes_secret_v1.argocd_manager.data.token
    }
  )
}

provider "kubernetes" {
  host                   = civo_kubernetes_cluster.cluster.api_endpoint
  client_certificate     = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).users[0].user.client-certificate-data)
  client_key             = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).users[0].user.client-key-data)
  cluster_ca_certificate = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
}

resource "kubernetes_cluster_role_v1" "argocd_manager" {
  metadata {
    name = "argocd-manager-role"
  }

  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["*"]
  }
  rule {
    non_resource_urls = ["*"]
    verbs             = ["*"]
  }
}


resource "kubernetes_cluster_role_binding_v1" "argocd_manager" {
  metadata {
    name = "argocd-manager-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd_manager.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.argocd_manager.metadata.0.name
    namespace = "kube-system"
  }
}

resource "kubernetes_service_account_v1" "argocd_manager" {
  metadata {
    name      = "argocd-manager"
    namespace = "kube-system"
  }
  secret {
    name = "argocd-manager-token"
  }
}

resource "kubernetes_secret_v1" "argocd_manager" {
  metadata {
    name      = "argocd-manager-token"
    namespace = "kube-system"
    annotations = {
      "kubernetes.io/service-account.name" = "argocd-manager"
    }
  }
  type       = "kubernetes.io/service-account-token"
  depends_on = [kubernetes_service_account_v1.argocd_manager]
}

resource "kubernetes_namespace_v1" "crossplane_system" {
  metadata {
    name = "crossplane-system"
  }
}

# resource "kubernetes_secret_v1" "crossplane_system" {
#   metadata {
#     name      = "external-dns-secrets"
#     namespace = kubernetes_namespace_v1.crossplane_system.metadata.0.name
#   }
#   data = {
#     token = #! data here needs to come from in cluster
#   }
#   type = "Opaque"
# }
