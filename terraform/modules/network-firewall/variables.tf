variable "project_prefix" {
  description = "Project naming prefix"
  type        = string
  default     = "sathvik"
}

variable "vpc_id" {
  description = "Target VPC ID"
  type        = string
}

variable "firewall_subnet_ids" {
  description = "List of firewall inspection subnet IDs"
  type        = list(string)
}

variable "log_group_name" {
  description = "CloudWatch log group name for firewall logs"
  type        = string
  default     = "/aws/network-firewall/sathvik"
}

variable "kms_key_arn" {
  description = "KMS Customer Managed Key ARN for encryption at rest"
  type        = string
  default     = "arn:aws:kms:us-east-1:009160054307:key/sathvik-cmk"
}
