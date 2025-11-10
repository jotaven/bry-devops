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

output "eks_cluster_name" {
  description = "O nome do cluster EKS."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "O 'endereço' (endpoint) do cérebro EKS."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_certificate_authority_data" {
  description = "A 'chave de acesso' (CA) do cérebro EKS."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true 
}

output "eks_oidc_provider_arn" {
  description = "O ARN do 'posto de segurança' (OIDC) do EKS."
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider_url" {
  description = "A URL do 'posto de segurança' (OIDC) do EKS."
  value       = module.eks.cluster_oidc_issuer_url
}

output "externaldns_iam_role_arn" {
  description = "O 'crachá' que o ExternalDNS usará."
  value       = module.iam_roles.externaldns_role_arn
  sensitive   = true
}

output "github_actions_infra_role_arn" {
  description = "IAM Role ARN para o GitHub Actions assumir o Deploy da infraestrutura."
  value       = module.iam_roles.github_actions_infra_role_arn
}