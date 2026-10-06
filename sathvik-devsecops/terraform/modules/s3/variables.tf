# sathvik-devsecops/terraform/modules/s3/variables.tf
variable "bucket_name" {
  description = "Name of the S3 bucket (must be hyphenated and globally unique)"
  type        = string
}

variable "kms_key_arn" {
  description = "ARN of KMS key for SSE-KMS server-side encryption"
  type        = string
}

variable "enable_versioning" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "purpose" {
  description = "Purpose tag for the bucket"
  type        = string
  default     = "Security"
}
