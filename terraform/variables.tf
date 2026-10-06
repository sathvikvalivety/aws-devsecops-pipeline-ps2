# sathvik-devsecops/terraform/variables.tf

variable "aws_region" {
  description = "Target AWS Region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "Target AWS Account ID"
  type        = string
  default     = "009160054307"
}

variable "project_prefix" {
  description = "Centralized prefix for all resources. Use sathvik_ or sathvik- based on service rules"
  type        = string
  default     = "sathvik"
}

variable "environment" {
  description = "Deployment environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for the dedicated VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability Zones to use for multi-AZ subnet distribution"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_app_subnet_cidrs" {
  description = "CIDR blocks for private application subnets"
  type        = list(string)
  default     = ["10.0.11.0/24", "10.0.12.0/24"]
}

variable "eks_worker_subnet_cidrs" {
  description = "CIDR blocks for EKS worker node subnets"
  type        = list(string)
  default     = ["10.0.21.0/24", "10.0.22.0/24"]
}

variable "firewall_subnet_cidrs" {
  description = "CIDR blocks for AWS Network Firewall inspection subnets"
  type        = list(string)
  default     = ["10.0.31.0/24", "10.0.32.0/24"]
}

variable "eks_cluster_version" {
  description = "Kubernetes control plane version for Amazon EKS"
  type        = string
  default     = "1.30"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "use_existing_lab_role" {
  description = "Whether to use pre-existing LabRole (required for VocLabs assumed-role environments)"
  type        = bool
  default     = true
}

variable "existing_lab_role_arn" {
  description = "ARN of pre-existing LabRole in VocLabs"
  type        = string
  default     = "arn:aws:iam::913786626696:role/LabRole"
}

variable "existing_lab_instance_profile_arn" {
  description = "ARN of pre-existing LabInstanceProfile in VocLabs"
  type        = string
  default     = "arn:aws:iam::913786626696:instance-profile/LabInstanceProfile"
}

variable "enable_network_firewall" {
  description = "Enable AWS Network Firewall deployment (set to true in enterprise accounts with permission)"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days (cost optimized)"
  type        = number
  default     = 1
}
