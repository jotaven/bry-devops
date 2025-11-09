output "vpc_id" {
  description = "O ID da VPC."
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Lista de IDs das subnets públicas."
  value       = [for s in aws_subnet.public : s.id]
}

output "private_subnet_ids" {
  description = "Lista de IDs das subnets privadas."
  value       = [for s in aws_subnet.private : s.id]
}