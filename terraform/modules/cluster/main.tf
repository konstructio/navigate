# ##! uncomment this block to run terraform locally
# terraform {
#   backend "kubernetes" {
#     secret_suffix     = "providerconfig-civo-nyc1"
#     namespace         = "crossplane-system"
#     # in_cluster_config = true
#     config_path       = "~/.navigate-kubeconfig"
#   }
#   required_providers {
#     civo = {
#       source = "civo/civo"
#     }
#     kubernetes = {
#       source = "hashicorp/kubernetes"
#       version = "2.23.0"
#     }
#   }
# }
# provider "civo" {
#   region = "nyc1"
# }
# ##! uncomment this block to run terraform locally


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
    size       = var.node_type
    node_count = tonumber(var.node_count)
  }
}

provider "kubernetes" {} # alias = "in-cluster" 

# provider "kubernetes" {
#   host                   = civo_kubernetes_cluster.cluster.api_endpoint
#   client_certificate     = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).users[0].user.client-certificate-data)
#   client_key             = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).users[0].user.client-key-data)
#   cluster_ca_certificate = base64decode(yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).clusters[0].cluster.certificate-authority-data)
#   alias = "target"
# }

# resource "kubernetes_cluster_role_v1" "argocd_manager" {
#   metadata {
#     name = "argocd-manager-role"
#   }

#   rule {
#     api_groups = ["*"]
#     resources  = ["*"]
#     verbs      = ["*"]
#   }
#   rule {
#     non_resource_urls = ["*"]
#     verbs             = ["*"]
#   }
# }


# resource "kubernetes_cluster_role_binding_v1" "argocd_manager" {
#   metadata {
#     name = "argocd-manager-role-binding"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = kubernetes_cluster_role_v1.argocd_manager.metadata.0.name
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = kubernetes_service_account_v1.argocd_manager.metadata.0.name
#     namespace = "kube-system"
#   }
# }

# resource "kubernetes_service_account_v1" "argocd_manager" {
#   metadata {
#     name      = "argocd-manager"
#     namespace = "kube-system"
#   }
#   secret {
#     name = "argocd-manager-token"
#   }
# }

# resource "kubernetes_secret_v1" "argocd_manager" {
#   metadata {
#     name      = "argocd-manager-token"
#     namespace = "kube-system"
#     annotations = {
#       "kubernetes.io/service-account.name" = "argocd-manager"
#     }
#   }
#   type       = "kubernetes.io/service-account-token"
#   depends_on = [kubernetes_service_account_v1.argocd_manager]
# }

# resource "kubernetes_namespace_v1" "crossplane_system" {
#   metadata {
#     name = "crossplane-system"
#   }
# }

resource "kubernetes_secret_v1" "crossplane_system" {
  metadata {
    name      = "tf--argocd-cluster-secrets"
    namespace = "default"
  }
  data = {
    bearerToken = "any old string"
    token2 = {
      caData = "any old string"
      certData  = "Opaque"
      insecure  = "Opaque"
      keyData  = "Opaque"
    }
  }
  type = "Opaque"
}
