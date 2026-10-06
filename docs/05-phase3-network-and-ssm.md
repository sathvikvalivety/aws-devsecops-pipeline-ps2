# Phase 3: Network Security Boundaries & SSM Compliance

**AWS Account:** `009160054307` | **Region:** `us-east-1` | **Profile:** `sathvik-dev`

---

## 1. Problem Statement & Objectives
Flat networks and permissive routing allow attackers to move laterally across workloads and access core database backends. Furthermore, unpatched operating systems represent the most common exploitation vector for automated botnets. Phase 3 provisions a multi-tier segregated VPC, deploys stateful egress filtering rules, establishes zero-trust security groups, and enforces PCI-DSS Requirement 6.2 patch automation in AWS Systems Manager.

---

## 2. Multi-Tier VPC Network Infrastructure

- **VPC ID:** `vpc-0eeb82d10ba282c2d` (`sathvik_vpc`)
- **CIDR:** `10.50.0.0/16`
- **DNS Support & Hostnames:** Enabled
- **Internet Gateway:** `igw-0a162baa61a5a0d3d` (`sathvik_igw`)

### Subnet Segmentation Matrix
| Subnet Name | Subnet ID | CIDR Block | AZ | Type & Purpose |
|---|---|---|---|---|
| `sathvik_public_subnet_1a` | `subnet-0f0d8474af60fb652` | `10.50.1.0/24` | us-east-1a | Public Ingress / ALB Tier |
| `sathvik_public_subnet_1b` | `subnet-0406c007bd5dfd28d` | `10.50.2.0/24` | us-east-1b | Public Ingress / ALB Tier |
| `sathvik_private_app_1a` | `subnet-01a095bcfb17bd976` | `10.50.10.0/24` | us-east-1a | Private Workload / Container Tier |
| `sathvik_private_app_1b` | `subnet-05fc07e7192a370af` | `10.50.20.0/24` | us-east-1b | Private Workload / Container Tier |
| `sathvik_private_db_1a` | `subnet-0c7f332b4907333b7` | `10.50.30.0/24` | us-east-1a | Isolated Database Tier |
| `sathvik_firewall_inspection_1a` | `subnet-01f08e86ed0eb9b2e` | `10.50.40.0/24` | us-east-1a | Network Firewall Inspection Tier |

### Route Table Routing Isolation
- **Public Route Table (`rtb-003481d1a82b63b30`):** Routes `0.0.0.0/0` -> `igw-0a162baa61a5a0d3d`.
- **Private Route Table (`rtb-04195209892418791`):** Completely severed from Internet Gateway. Zero direct routes to the Internet.

### Security Group Segmentation
1. `sathvik_app_sg` (`sg-0401849589b4d299e`): Inbound TCP 8000 allowed only from VPC CIDR `10.50.0.0/16`.
2. `sathvik_db_sg` (`sg-06d62de2fcf4dc8b5`): Inbound TCP 5432 allowed only from `sathvik_app_sg`.
3. `sathvik_quarantine_sg` (`sg-0a0a38a865302e6bc`): Strict zero-trust quarantine. **0 ingress rules, 0 egress rules**.

---

## 3. AWS Network Firewall Module
- **Module Location:** `sathvik-devsecops/terraform/modules/network-firewall/`
- **Features:**
  - Stateful domain allowlist: `.amazonaws.com`, `.pci-dss.org`, `api.stripe.com`, `api.paypal.com`.
  - Suricata IPS drop rules: Blocks known malicious RFC 5737 test subnets.
  - Encryption at Rest: Enforces Customer Managed Key (CMK) KMS encryption across rule groups, policy, and firewall.
  - Deletion Protection: Enabled.
  - Checkov static analysis: 6 passed, 0 failed.

---

## 4. AWS Systems Manager (SSM) Patch Compliance
- **Custom Patch Baseline:** `pb-0ff7e6df7ee92f06d` (`sathvik_pci_patch_baseline`)
- **OS:** `AMAZON_LINUX_2023`
- **Compliance Rule:** Auto-approve `CLASSIFICATION=Security` with `SEVERITY=Critical,Important` with **0 days delay**.
- **Compliance Level:** `CRITICAL`
- **Patch Group:** `sathvik-production-nodes`
- **Audit Verification:** `scripts/verify-phase3-compliance.ps1` evaluated 5/5 controls and certified 100% compliance.

---

## 5. Evidence Artifacts
- `evidence/phase3/phase3_01_vpc_topology.png`
- `evidence/phase3/phase3_02_subnets_multizone.png`
- `evidence/phase3/phase3_03_route_tables.png`
- `evidence/phase3/phase3_04_security_groups.png`
- `evidence/phase3/phase3_05_network_firewall_iac.png`
- `evidence/phase3/phase3_06_ssm_patch_baseline.png`
- `evidence/phase3/phase3_07_ssm_patch_group.png`
- `evidence/phase3/phase3_08_pci_compliance_verification.png`
