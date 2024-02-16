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

resource "kubernetes_namespace_v1" "external_dns" {
  metadata {
    name = "external-dns"
  }
}

resource "kubernetes_secret_v1" "external_dns" {
  metadata {
    name      = "external-dns-secrets"
    namespace = kubernetes_namespace_v1.external_dns.metadata.0.name
  }
  data = {
    token = var.cloudflare_api_token
  }
  type = "Opaque"
}

resource "kubernetes_namespace_v1" "development" {
  metadata {
    name = "development"
  }
}

resource "kubernetes_secret_v1" "development" {
  metadata {
    name      = "cloudflare-secrets"
    namespace = kubernetes_namespace_v1.development.metadata.0.name
  }
  data = {
    origin-ca-api-key = var.cloudflare_origin_issuer_token
  }
  type = "Opaque"
}

provider "kubernetes" {
  alias = "local"
}

resource "kubernetes_secret_v1" "argocd_cluster_secret" {
  provider = kubernetes.local
  metadata {
    name      = var.cluster_name
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }
  data = {
    name = var.cluster_name
    server = civo_kubernetes_cluster.cluster.api_endpoint
    clusterResources = "true"
    config = jsonencode({ 
      "bearerToken" = kubernetes_secret_v1.argocd_manager.data.token
      "tlsClientConfig" = {
        "insecure" = false
        "caData"   = yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).clusters[0].cluster.certificate-authority-data
        "certData" = yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).users[0].user.client-certificate-data
        "keyData"  = yamldecode(civo_kubernetes_cluster.cluster.kubeconfig).users[0].user.client-key-data
      }
    })
  }
  type = "Opaque"
}

resource "kubernetes_secret_v1" "cluster_secret" {
  provider = kubernetes.local
  metadata {
    name      = "${var.cluster_name}-kubeconfig"
    namespace = "argocd"
  }
  data = {
    kubeconfig = civo_kubernetes_cluster.cluster.kubeconfig
  }
  type = "Opaque"
}
