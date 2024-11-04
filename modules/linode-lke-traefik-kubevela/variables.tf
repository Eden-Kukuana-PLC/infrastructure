variable "linode_token" {
  description = "Your Linode API Personal Access Token. (required)"
}

variable "k8s_version" {
  description = "The Kubernetes version to use for this cluster. (required)"
  default     = "1.31"
}

variable "label" {
  description = "The unique label to assign to this cluster. (required)"
  default     = "default-lke-cluster"
}

variable "region" {
  description = "The region where your cluster will be located. (required)"
  default     = "eu-central"
}

variable "tags" {
  description = "Tags to apply to your cluster for organizational purposes. (optional)"
  type = list(string)
  default = ["testing"]
}

variable "pools" {
  description = "The Node Pool specifications for the Kubernetes cluster. (required)"
  type = list(object({
    type  = string
    count = number
  }))
  default = [
    {
      type  = "g6-standard-1"
      count = 1
    }
  ]
}

variable "ghrc_username" {
  description = "The username to use to connect to the Kubernetes API server to ghrc"
  type        = string
}

variable "ghrc_password" {
  description = "The password to use to connect to the Kubernetes API Server to ghrc"
  type        = string
  sensitive   = true
}

variable "ghrc_email" {
  description = "The email to use for ghrc authentication"
  type        = string
}

variable "traefik_version" {
  description = "The version to use for Traefik helm chart"
  type        = string
  default     = "33.0.0"
}

variable "kubevela_core_version" {
  description = "The version to use for Kubevela core helm chart"
  type        = string
  default     = "1.10.0-alpha.1"
}