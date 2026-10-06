# Phase 3 Screenshot Evidence & Verification Catalog

**AWS Account ID:** `009160054307`  
**AWS Region:** `us-east-1`  
**IAM Identity:** `arn:aws:iam::009160054307:user/sathvik-cli`  
**Profile:** `sathvik-dev`  

---

## Screenshot Inventory

| Screenshot ID | Filename | Description | Status / Result | AWS Resource Verified |
|---|---|---|---|---|
| **Phase3-01** | `phase3_01_vpc_topology.png` | Dedicated Multi-Tier VPC provisioned with CIDR `10.50.0.0/16` and DNS hostnames | VERIFIED | `vpc-0eeb82d10ba282c2d` (`sathvik_vpc`) |
| **Phase3-02** | `phase3_02_subnets_multizone.png` | 6 segregated subnets across 2 AZs (Public, App, DB, and Firewall Inspection) | VERIFIED | Subnets: `subnet-0f0d8474af60fb652`, `subnet-0406c007bd5dfd28d`, `subnet-01a095bcfb17bd976`, etc. |
| **Phase3-03** | `phase3_03_route_tables.png` | Segregated route tables enforcing private subnet isolation from direct IGW routes | VERIFIED | `rtb-003481d1a82b63b30` (Public), `rtb-04195209892418791` (Private) |
| **Phase3-04** | `phase3_04_security_groups.png` | Defense-in-depth Security Groups: App SG, DB SG, and Zero-Traffic Quarantine SG | VERIFIED | `sg-0401849589b4d299e` (`sathvik_app_sg`), `sg-06d62de2fcf4dc8b5` (`sathvik_db_sg`), `sg-0a0a38a865302e6bc` (`sathvik_quarantine_sg`) |
| **Phase3-05** | `phase3_05_network_firewall_iac.png` | AWS Network Firewall Terraform module compliance passing 6/6 Checkov security controls | PASSED | CMK KMS encryption at rest, deletion protection, Suricata IPS rules & domain filter |
| **Phase3-06** | `phase3_06_ssm_patch_baseline.png` | AWS Systems Manager Patch Baseline enforcing 0-day auto-approval on Critical/Important CVEs | VERIFIED | `pb-0ff7e6df7ee92f06d` (`sathvik_pci_patch_baseline`) |
| **Phase3-07** | `phase3_07_ssm_patch_group.png` | SSM Patch Group registration linking workloads to automated compliance baseline | VERIFIED | Patch Group: `sathvik-production-nodes` |
| **Phase3-08** | `phase3_08_pci_compliance_verification.png` | Automated PCI-DSS v4.0 Network & Patch Compliance audit verification (100% score) | COMPLIANT | 5/5 controls certified: VPC isolation, zero direct internet route, least privilege SGs, SSM patch baseline |

---

## Network & Compliance Principles Demonstrated
1. **Network Segmentation (PCI-DSS 1.2 & 1.3):** Workloads and databases reside in private subnets with zero direct internet access.
2. **Perimeter Defense-in-Depth:** Stateful egress inspection restricts outbound traffic to authorized financial gateways and AWS endpoints.
3. **Zero-Trust Incident Response Readiness:** A pre-provisioned quarantine security group completely severs all ingress and egress network traffic for compromised hosts.
4. **Vulnerability Timelines (PCI-DSS 6.2):** High-severity and Critical operating system vulnerabilities are patched automatically without manual intervention delay.
