output "externaldns_role_arn" {
  description = "O ARN do 'crachá' do ExternalDNS."
  value       = aws_iam_role.externaldns.arn
}