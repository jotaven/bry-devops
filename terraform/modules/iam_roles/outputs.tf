output "externaldns_role_arn" {
  description = "O ARN do 'crachá' do ExternalDNS."
  value       = aws_iam_role.externaldns.arn
}

output "github_actions_infra_role_arn" {
  description = "IAM Role ARN para o GitHub Actions assumir o Deploy da infraestrutura."
  value       = aws_iam_role.github_actions_infra.arn
}