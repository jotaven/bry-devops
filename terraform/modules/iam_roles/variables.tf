variable "oidc_provider_arn" {
  description = "O ARN do provedor OIDC do EKS."
  type        = string
}

variable "oidc_provider_url" {
  description = "A URL do provedor OIDC do EKS "
  type        = string
}

variable "account_id" {
  description = "O ID da conta AWS para construir os ARNs do OIDC."
  type        = string
}