output "vpc_id" {
  description = "O ID da VPC criada."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Lista de IDs das subnets públicas."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Lista de IDs das subnets privadas."
  value       = module.vpc.private_subnet_ids
}

output "nlb_security_group_id" {
  description = "O ID do Security Group para o NLB."
  value       = module.security.nlb_sg_id
}

output "eks_worker_security_group_id" {
  description = "O ID do Security Group para os Workers do EKS."
  value       = module.security.worker_sg_id
}