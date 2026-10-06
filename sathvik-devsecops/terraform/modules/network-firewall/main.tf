# sathvik-devsecops/terraform/modules/network-firewall/main.tf
# Hardened AWS Network Firewall Module with CMK Encryption & Strict Inspection

# 1. Stateful Domain Filtering Rule Group
resource "aws_networkfirewall_rule_group" "domain_filtering" {
  capacity = 100
  name     = "${var.project_prefix}-domain-filter-rg"
  type     = "STATEFUL"

  encryption_configuration {
    key_id = var.kms_key_arn
    type   = "CUSTOMER_KMS"
  }

  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["TLS_SNI", "HTTP_HOST"]
        targets = [
          ".amazonaws.com",
          ".amazon.com",
          "api.stripe.com",
          "api.paypal.com",
          "github.com",
          "registry-1.docker.io",
          "auth.docker.io",
          "production.cloudflare.docker.com"
        ]
      }
    }
    rule_variables {
      port_sets {
        key = "HOME_NET"
        port_set {
          definition = ["443", "80"]
        }
      }
    }
  }

  tags = {
    Name    = "${var.project_prefix}-domain-filter-rg"
    Purpose = "PCI-DSS Allowed Domains Egress Filtering"
  }
}

# 2. Stateful IP Dynamic Drop Rule Group (Suricata compatible)
resource "aws_networkfirewall_rule_group" "ip_drop" {
  capacity = 100
  name     = "${var.project_prefix}-ip-drop-rg"
  type     = "STATEFUL"

  encryption_configuration {
    key_id = var.kms_key_arn
    type   = "CUSTOMER_KMS"
  }

  rule_group {
    rules_source {
      stateful_rule {
        action = "DROP"
        header {
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
          destination      = "198.51.100.0/24" # Controlled TEST malicious IP subnet (RFC 5737 TEST-NET-2)
          destination_port = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1000001"]
        }
      }

      stateful_rule {
        action = "DROP"
        header {
          direction        = "FORWARD"
          protocol         = "TCP"
          source           = "ANY"
          source_port      = "ANY"
          destination      = "203.0.113.0/24" # Controlled TEST malicious IP subnet (RFC 5737 TEST-NET-3)
          destination_port = "ANY"
        }
        rule_option {
          keyword  = "sid"
          settings = ["1000002"]
        }
      }
    }
  }

  tags = {
    Name    = "${var.project_prefix}-ip-drop-rg"
    Purpose = "Malicious IP & Port Egress Drop Rules"
  }
}

# 3. Network Firewall Policy
resource "aws_networkfirewall_firewall_policy" "this" {
  name = "${var.project_prefix}-firewall-policy"

  encryption_configuration {
    key_id = var.kms_key_arn
    type   = "CUSTOMER_KMS"
  }

  firewall_policy {
    stateless_default_actions          = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.domain_filtering.arn
    }

    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.ip_drop.arn
    }
  }

  tags = {
    Name    = "${var.project_prefix}-firewall-policy"
    Purpose = "Perimeter Defense Policy"
  }
}

# 4. AWS Network Firewall
resource "aws_networkfirewall_firewall" "this" {
  name                = "${var.project_prefix}-netfw"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.this.arn
  vpc_id              = var.vpc_id
  delete_protection   = true

  encryption_configuration {
    key_id = var.kms_key_arn
    type   = "CUSTOMER_KMS"
  }

  dynamic "subnet_mapping" {
    for_each = var.firewall_subnet_ids
    content {
      subnet_id = subnet_mapping.value
    }
  }

  tags = {
    Name    = "${var.project_prefix}-netfw"
    Purpose = "Perimeter Inspection Firewall"
  }
}

# 5. Firewall Logging Configuration
resource "aws_networkfirewall_logging_configuration" "this" {
  firewall_arn = aws_networkfirewall_firewall.this.arn

  logging_configuration {
    log_destination_config {
      log_destination = {
        logGroup = var.log_group_name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "ALERT"
    }

    log_destination_config {
      log_destination = {
        logGroup = var.log_group_name
      }
      log_destination_type = "CloudWatchLogs"
      log_type             = "FLOW"
    }
  }
}
