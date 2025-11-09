output "nlb_sg_id" {
  description = "ID do Security Group do NLB."
  value       = aws_security_group.nlb.id
}

output "worker_sg_id" {
  description = "ID do Security Group dos EKS Workers."
  value       = aws_security_group.eks_workers.id
}