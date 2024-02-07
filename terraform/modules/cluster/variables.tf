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
