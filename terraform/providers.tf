# sathvik-devsecops/terraform/providers.tf
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "DevSecOpsCybersecurityHackathon"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "Sathvik"
      Prefix      = var.project_prefix
    }
  }
}
