# sathvik-devsecops/terraform/modules/kms/variables.tf
variable "key_alias" {
  description = "KMS Key Alias (e.g. alias/sathvik_kms_key)"
  type        = string
}

variable "description" {
  description = "Description of the KMS key"
  type        = string
  default     = "Customer Managed Key for sathvik DevSecOps encrypted storage"
}

variable "deletion_window_in_days" {
  description = "Duration in days before key deletion after schedule"
  type        = number
  default     = 7
}

variable "aws_account_id" {
  description = "AWS Account ID for key policy"
  type        = string
}
