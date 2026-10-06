output "firewall_arn" {
  description = "The ARN of the AWS Network Firewall"
  value       = aws_networkfirewall_firewall.this.arn
}

output "firewall_id" {
  description = "The ID of the AWS Network Firewall"
  value       = aws_networkfirewall_firewall.this.id
}

output "firewall_status" {
  description = "The status of the AWS Network Firewall"
  value       = aws_networkfirewall_firewall.this.firewall_status
}

output "policy_arn" {
  description = "The ARN of the firewall policy"
  value       = aws_networkfirewall_firewall_policy.this.arn
}
