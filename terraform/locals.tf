# sathvik-devsecops/terraform/locals.tf

locals {
  # Standard prefixes adhering strictly to AWS service naming rules
  prefix_underscore = "${var.project_prefix}_"
  prefix_hyphen     = "${var.project_prefix}-"

  # Resource Names - Hyphenated (where underscores are disallowed or restricted)
  s3_forensic_bucket_name = "${local.prefix_hyphen}forensics-${var.aws_account_id}"
  s3_pipeline_bucket_name = "${local.prefix_hyphen}pipeline-${var.aws_account_id}"
  eks_cluster_name        = "${local.prefix_hyphen}cluster"
  eks_node_group_name     = "${local.prefix_hyphen}node-group"
  ecr_repository_name     = "${local.prefix_hyphen}payment-service"
  network_firewall_name   = "${local.prefix_hyphen}netfw"
  codebuild_project_name  = "${local.prefix_hyphen}iac-scan"
  codepipeline_name       = "${local.prefix_hyphen}devsecops-pipeline"

  # Resource Names - Underscored (where underscores are permitted and required)
  vpc_name                   = "${local.prefix_underscore}vpc"
  quarantine_sg_name         = "${local.prefix_underscore}quarantine_sg"
  eks_node_sg_name           = "${local.prefix_underscore}eks_node_sg"
  eks_cluster_sg_name        = "${local.prefix_underscore}eks_cluster_sg"
  secret_name                = "${local.prefix_underscore}payment_db_credentials"
  rotation_lambda_name       = "${local.prefix_underscore}secret_rotation"
  soar_lambda_name           = "${local.prefix_underscore}soar_remediation"
  kms_key_alias              = "alias/${local.prefix_underscore}kms_key"
  ssm_patch_baseline_name    = "${local.prefix_underscore}pci_patch_baseline"
  guardduty_detector_name    = "${local.prefix_underscore}guardduty"
  eventbridge_rule_name      = "${local.prefix_underscore}threat_event_rule"
  eventbridge_test_rule_name = "${local.prefix_underscore}soar_test_rule"
  log_group_soar             = "/aws/lambda/${local.soar_lambda_name}"
  log_group_rotation         = "/aws/lambda/${local.rotation_lambda_name}"
  log_group_vpc_flow         = "/aws/vpc/${local.prefix_underscore}flow_logs"

  common_tags = {
    Project     = "DevSecOpsCybersecurityHackathon"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Sathvik"
    Prefix      = var.project_prefix
  }
}
