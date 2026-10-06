# sathvik-devsecops/terraform/modules/kms/outputs.tf
output "key_arn" {
  description = "ARN of the KMS key"
  value       = aws_kms_key.this.arn
}

output "key_id" {
  description = "ID of the KMS key"
  value       = aws_kms_key.this.key_id
}

output "key_alias" {
  description = "Alias name of the KMS key"
  value       = aws_kms_alias.this.name
}
