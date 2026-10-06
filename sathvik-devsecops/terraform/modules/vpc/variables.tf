# sathvik-devsecops/terraform/modules/vpc/variables.tf

variable "project_prefix" {
  description = "Project prefix (sathvik)"
  type        = string
  default     = "sathvik"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
}

variable "eks_worker_subnet_cidrs" {
  description = "CIDR blocks for EKS worker subnets"
  type        = list(string)
}

variable "firewall_subnet_cidrs" {
  description = "CIDR blocks for firewall inspection subnets"
  type        = list(string)
}

variable "flow_log_destination_arn" {
  description = "CloudWatch Log Group ARN for VPC Flow Logs"
  type        = string
}

variable "flow_log_iam_role_arn" {
  description = "IAM Role ARN for VPC Flow Logs to publish to CloudWatch Logs"
  type        = string
}
