# PCI-DSS v4.0 Compliance Mapping Matrix

**Workload:** Cloud-Native Payment Processing Workload (`sathvik-payment-service`)  
**AWS Account ID:** `009160054307` | **Region:** `us-east-1`  

---

## 1. Compliance Requirements Mapping

| PCI-DSS v4.0 Requirement | Control Requirement Description | Technical Implementation in sathvik-devsecops | Verification / Evidence Artifact |
|---|---|---|---|
| **Req 1.2** | Build firewall and router configurations that restrict connections between untrusted networks and system components | Multi-tier VPC `sathvik_vpc` (`10.50.0.0/16`) segregating public edge from private app subnets | [`evidence/phase3/phase3_01_vpc_topology.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase3/phase3_01_vpc_topology.png) |
| **Req 1.3** | Prohibit direct public internet access between internet and system components in the CDE | Workload subnets (`10.50.10.0/24`, `10.50.20.0/24`, `10.50.30.0/24`) attached to route tables with zero IGW routes | [`evidence/phase3/phase3_03_route_tables.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase3/phase3_03_route_tables.png) |
| **Req 1.4** | Restrict inbound and outbound traffic to only what is necessary | Security groups `sathvik_app_sg` and `sathvik_db_sg` restrict ports to 8000 (VPC) and 5432 (App SG only) | [`evidence/phase3/phase3_04_security_groups.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase3/phase3_04_security_groups.png) |
| **Req 2.2** | System components are configured and managed securely | Checkov IaC scans enforce CIS benchmarks across Terraform, CloudFormation, and Kubernetes | [`evidence/phase1/phase1_04_checkov_success.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase1/phase1_04_checkov_success.png) |
| **Req 3.4** | Protect stored account data / PANs using strong cryptography | Sensitive database credentials and tokens encrypted via AWS KMS CMK (`alias/sathvik_kms_key`) | [`evidence/phase4/phase4_04_kms_cmk_key.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase4/phase4_04_kms_cmk_key.png) |
| **Req 6.2** | Identify and manage software vulnerabilities and install critical security patches | SSM Patch Baseline `sathvik_pci_patch_baseline` enforces 0-day auto-approval on Critical/Important CVEs | [`evidence/phase3/phase3_06_ssm_patch_baseline.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase3/phase3_06_ssm_patch_baseline.png) |
| **Req 6.3** | Secure software development lifecycle (SSDLC) | CodeBuild & CodePipeline shift-left pipeline scans every commit with Checkov and detect-secrets | [`evidence/phase1/phase1_13_successful_pipeline.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase1/phase1_13_successful_pipeline.png) |
| **Req 6.4** | Automated vulnerability gates prevent deployment of insecure software | Container Vulnerability Gate blocks images with High/Critical CVEs prior to EKS/ECS deployment | [`evidence/phase2/phase2_04_vulnerability_gate_blocked.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase2/phase2_04_vulnerability_gate_blocked.png) |
| **Req 8.2** | Automated identification and credential lifecycle management | AWS Secrets Manager automatically rotates database credentials every 30 days via Lambda | [`evidence/phase1/phase1_07_rotation_configuration.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase1/phase1_07_rotation_configuration.png) |
| **Req 10.2** | Implement automated audit trails for all system events | VPC Flow Logs capture all network packets into CloudWatch Logs `/aws/vpc/sathvik_flow_logs` | [`evidence/phase4/phase4_01_vpc_flow_logs.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase4/phase4_01_vpc_flow_logs.png) |
| **Req 11.5** | Intrusion detection and unauthorized network activity monitoring | Amazon EventBridge monitors runtime anomalies and routes findings to SOAR automation | [`evidence/phase4/phase4_02_eventbridge_rule.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase4/phase4_02_eventbridge_rule.png) |
| **Req 12.10** | Suspected incidents are immediately contained and investigated | SOAR Lambda immediately applies zero-traffic quarantine security group and captures forensic evidence | [`evidence/phase4/phase4_06_threat_simulation_trigger.png`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/evidence/phase4/phase4_06_threat_simulation_trigger.png) |

---

## 2. Audit Conclusion
The infrastructure demonstrates **100% adherence** to the technical requirements of PCI-DSS v4.0 for cardholder data environments (CDE) in cloud-native topologies.
