variable "vpc_cidr" {
  description = "O bloco CIDR da VPC"
  type        = string
}

variable "public_subnets" {
  description = "Lista de CIDRs para as subnets públicas"
  type        = list(string)
}

variable "private_subnets" {
  description = "Lista de CIDRs para as subnets privadas"
  type        = list(string)
}

variable "availability_zones" {
  description = "Lista de AZs para construir"
  type        = list(string)
}