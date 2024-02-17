
variable "civo_token" {
  type = string
}

variable "cloudflare_api_token" {
  type = string
  default = "na"
}

variable "cloudflare_origin_issuer_token" {
  type = string
  default = "na"
}

variable "cluster_name" {
  type    = string
}

variable "node_count" {
  type    = string
}

variable "node_type" {
  type    = string
  default = "g4s.kube.medium"
}
