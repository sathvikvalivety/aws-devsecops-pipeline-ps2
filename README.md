# Automated DevSecOps Pipeline & Infrastructure Security Compliance for Cloud-Native Payment Workloads
### Lab Exam Problem Statement 2 (PS-2) | PCI-DSS v4.0 & SOC 2 Type II Compliance Framework

![AWS](https://img.shields.io/badge/AWS-100%25_Cloud--Native-FF9900?logo=amazon-aws&logoColor=white)
![Compliance](https://img.shields.io/badge/Compliance-PCI--DSS_v4.0_%7C_SOC_2_Type_II-0ea5e9)
![IaC](https://img.shields.io/badge/IaC-Terraform_1.5+-623CE4?logo=terraform&logoColor=white)
![Security Gate](https://img.shields.io/badge/Gates-Checkov_%7C_Inspector_%7C_detect--secrets-10b981)
![SOAR](https://img.shields.io/badge/SOAR-Automated_Quarantine_%3C2s-ef4444)

---

### Candidate & Project Verification
* **Candidate Name**: **Valivety Sathvik**
* **Roll Number / Registration ID**: **CH.SC.U4CYS23050**
* **Role**: Lead Cloud Security & DevSecOps Engineer (`sathvikvalivety`)
* **AWS Target Account**: `009160054307` | **Region**: `us-east-1` (N. Virginia)
* **Live S3 Command Center**: [http://sathvik-devsecops-dashboard-009160054307.s3-website-us-east-1.amazonaws.com](http://sathvik-devsecops-dashboard-009160054307.s3-website-us-east-1.amazonaws.com)
* **Cloud API Gateway Endpoint**: `https://gq4mp9mxwc.execute-api.us-east-1.amazonaws.com`
* **Audit Documentation**:
  * Word Report: [`DevSecOps_Security_Audit_and_SOAR_Report.docx`](DevSecOps_Security_Audit_and_SOAR_Report.docx) (8.3 MB)
  * PDF Report: [`DevSecOps_Security_Audit_and_SOAR_Report.pdf`](DevSecOps_Security_Audit_and_SOAR_Report.pdf) (9.0 MB, 25 Pages)

---

## 1. Executive Summary & Problem Statement (PS-2)

A fintech enterprise is engineering an API-driven payment processing platform on Amazon Web Services (AWS). Prior to handling cardholder data in production, the infrastructure and software supply chain must strictly comply with **PCI-DSS v4.0** (Requirements 1, 2, 3, 6, 8, 10, 12) and **SOC 2 Type II** (Security, Availability) criteria.

Historically, rapid DevOps release cycles led to unvetted Terraform deployments containing severe security regressions—including publicly accessible S3 storage buckets, unrestricted security group ingress, hardcoded database credentials, unvetted container dependencies with critical Common Vulnerabilities and Exposures (CVEs), and delayed incident remediation.

This project delivers an end-to-end **Automated Security Pipeline and Runtime Threat Detection Framework** operated entirely within AWS. The control plane operates 100% independently of local developer machines: the dashboard is served from Amazon S3, APIs execute via Amazon API Gateway, and serverless logic runs in AWS Lambda with zero client-side AWS credential exposure.

---

## 2. Master Architecture Blueprint

![Master Architecture Blueprint](evidence/service%20images/ps2_architecture_diagram.jpg)

### Lifecycle Architecture Overview

```
                         ┌────────────────────────────────────────────────────────┐
                         │                     YOUR BROWSER                       │
                         │             Cyber Command Center Dashboard             │
                         └───────────────────────────┬────────────────────────────┘
                                                     │ HTTPS (Zero Credentials)
                                                     ▼
                         ┌────────────────────────────────────────────────────────┐
                         │                     AWS CLOUD                          │
                         │              Dashboard Frontend (S3)                   │
                         │     sathvik-devsecops-dashboard-009160054307           │
                         └───────────────────────────┬────────────────────────────┘
                                                     │
                                                     ▼
                         ┌────────────────────────────────────────────────────────┐
                         │               API GATEWAY HTTP API v2                  │
                         │       sathvik-devsecops-api (ID: gq4mp9mxwc)           │
                         └───────────────────────────┬────────────────────────────┘
                                                     │
                                                     ▼
                         ┌────────────────────────────────────────────────────────┐
                         │                 AWS LAMBDA BACKEND                     │
                         │              sathvik_dashboard_backend                 │
                         │          (IAM Role: Zero Browser Secrets)              │
                         └───────────────────────────┬────────────────────────────┘
                                                     │
                 ┌───────────────────────────────────┼───────────────────────────────────┐
                 ▼                                   ▼                                   ▼
          ┌─────────────┐                     ┌─────────────┐                     ┌─────────────┐
          │ EventBridge │                     │ Systems Mgr │                     │  AWS APIs   │
          │ Threat Bus  │                     │ SSM / Patch │                     │ Boto3 SDK   │
          └──────┬──────┘                     └──────┬──────┘                     └──────┬──────┘
                 │                                   │                                   │
                 ▼                                   ▼                                   ▼
  ┌─────────────────────────────────────────────────────────────────────────────────────────────┐
  │                                    AWS SECURITY SERVICES                                    │
  │   GuardDuty | Inspector | ECR | Secrets Manager | Network Firewall | CloudTrail             │
  │   CloudWatch Logs | VPC Flow Logs | S3 Forensics | KMS CMK | EC2 Hypervisor Quarantine      │
  └─────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## 3. The 4 DevSecOps Implementation Phases

### Phase 1: Shift-Left IaC Security & Secret Governance
* **Pre-Deployment Static Analysis**: AWS CodePipeline stage with AWS CodeBuild scanning dynamic Terraform configurations using **Checkov** against CIS AWS Foundations benchmarks.
* **Secret Governance & Hardcoded Token Gates**: Builds fail if passwords, AWS tokens, or high-entropy secrets are detected via **detect-secrets**.
* **30-Day Automated Secret Rotation**: Production database credentials (`sathvik_payment_db_credentials`) managed natively in **AWS Secrets Manager**, envelope-encrypted with **AWS KMS CMK**, and rotated every 30 days via a 4-step AWS Lambda (`createSecret`, `setSecret`, `testSecret`, `finishSecret`).

### Phase 2: Container Security & Vulnerability Scanning
* **ECR Image Security**: Private container registry `sathvik-payment-service` configured with `IMMUTABLE` image tags to prevent image tampering and automated scan-on-push.
* **Automated Admission Guardrail**: AWS Lambda build gate evaluating **Amazon Inspector** findings. Automatically blocks deployments containing $\ge 1$ CRITICAL or HIGH CVEs.
* **Runtime Hardening**: Amazon ECS / EKS task definitions configured with non-root runtime (UID 10001), read-only root filesystems, and `awsvpc` network isolation.

### Phase 3: Network Security Boundaries & Systems Manager Compliance
* **Perimeter Defense & Inspection**: Dedicated inspection subnet in `sathvik_vpc` hosting **AWS Network Firewall** endpoints with stateful Suricata domain filtering and dynamic IP drop rules.
* **Multi-Tier Subnet Segregation**: 6 multi-AZ subnets partitioning public ingress, private workloads, database tier, and firewall inspection.
* **Patch Compliance Baseline**: **AWS Systems Manager (SSM) Patch Manager** baseline (`sathvik_pci_patch_baseline`) enforcing 0-day auto-approval on Critical and Security OS patches for Amazon Linux 2023.
* **100% Traffic Observability**: **Amazon CloudWatch Logs & VPC Flow Logs** capturing all ACCEPT and REJECT packet records.

### Phase 4: Runtime Threat Remediation & Automated SOAR
* **Threat Trigger Simulation**: Simulates an active microservice compromise (unauthorized outbound communication / port scanning).
* **Decoupled Threat Ingestion**: **Amazon GuardDuty** and **VPC Flow Logs** detect the anomaly; **Amazon EventBridge** matches pattern `{"source": ["aws.guardduty", "sathvik.security"]}`.
* **Automated Containment (< 2 Seconds)**: EventBridge fires **SOAR Lambda** (`sathvik_soar_remediation`), which:
  1. Replaces the workload's security group with `sathvik_quarantine_sg` (**0 Inbound / 0 Outbound rules**) at the AWS hypervisor level.
  2. Executes an **SSM Run Command** on the live instance to dump volatile process trees, open sockets, and system memory.
  3. Archives the forensic snapshot into `s3://sathvik-forensics-009160054307` encrypted under KMS Key `7905802c-d140-43d8-b64b-396b766b8e73` with SHA256 integrity hashes.
* **Controlled Rollback**: One-click recovery restores the production security group (`sathvik_app_sg`) and marks the incident as `RESOLVED`.

---

## 4. AWS Services Inventory (20 Services)

| # | AWS Service | Component Identifier | Purpose & Role in Architecture | Compliance Standard |
| :-: | :--- | :--- | :--- | :--- |
| **1** | **AWS CodePipeline** | `sathvik-devsecops-pipeline` | Multi-stage continuous delivery pipeline orchestrating builds and scans | PCI 6.4 / SOC 2 CC8.1 |
| **2** | **AWS CodeBuild** | `sathvik-iac-scan` | Containerized build runner executing Checkov and detect-secrets | PCI 6.4 / SOC 2 CC7.1 |
| **3** | **AWS Secrets Manager** | `sathvik_payment_db_credentials`| Vault storing DB credentials with 30-day automated rotation | PCI 8.2 / SOC 2 CC6.1 |
| **4** | **AWS Lambda (Rotation)** | `sathvik_secret_rotation` | 4-step rotation engine (`createSecret`, `setSecret`, `testSecret`, `finishSecret`)| PCI 8.2 / SOC 2 CC6.1 |
| **5** | **AWS Lambda (SOAR)** | `sathvik_soar_remediation` | Incident response engine severing host network and dumping forensics | PCI 12.10 / SOC 2 CC7.3 |
| **6** | **AWS Lambda (Backend)** | `sathvik_dashboard_backend` | Cloud control plane API handling status queries, demos, and quarantine | SOC 2 CC6.6 |
| **7** | **AWS KMS** | `alias/sathvik_kms_key` | Customer Managed Key (CMK) envelope encryption for S3 & Secrets Manager | PCI 3.4 / SOC 2 CC6.1 |
| **8** | **Amazon ECR** | `sathvik-payment-service` | Private Docker registry with immutable tags and automated CVE scanning | PCI 6.2 / SOC 2 CC7.1 |
| **9** | **Amazon Inspector** | Enhanced Container Scanning | Continuous CVE scanner evaluating container OS packages and language libs | PCI 6.2 / SOC 2 CC7.1 |
| **10** | **Amazon ECS / EKS** | `sathvik-payment-service:1` | Microservice container runtime configured with non-root (UID 10001) | PCI 2.2 / SOC 2 CC6.1 |
| **11** | **Amazon VPC** | `sathvik_vpc` (`10.50.0.0/16`)| Multi-tier segmented VPC (public, private workload, database, firewall) | PCI 1.1 / SOC 2 CC6.6 |
| **12** | **AWS Network Firewall** | `sathvik_firewall_subnet` | Stateful Suricata deep packet inspection and outbound domain filtering | PCI 1.2 / SOC 2 CC6.6 |
| **13** | **AWS SSM Patch Manager**| `sathvik_pci_patch_baseline` | Operating system patch compliance with 0-day auto-approval on Critical CVEs | PCI 6.2 / SOC 2 CC7.1 |
| **14** | **AWS SSM Run Command** | `AWS-RunShellScript` / Forensics | Remote forensic collection without opening SSH or bastion host ports | PCI 12.10 / SOC 2 CC7.3 |
| **15** | **Amazon GuardDuty** | Threat Detection Engine | ML-driven detection identifying anomalous outbound egress & port scans | PCI 10.2 / SOC 2 CC7.2 |
| **16** | **Amazon CloudWatch Logs**| `/aws/vpc/sathvik_flow_logs` | Real-time log groups streaming 100% of packet ACCEPT and REJECT telemetry | PCI 10.2 / SOC 2 CC7.2 |
| **17** | **Amazon EventBridge** | `sathvik_threat_detection_rule`| Serverless event bus routing threat findings to SOAR Lambda | PCI 12.10 / SOC 2 CC7.3 |
| **18** | **Amazon EC2** | `i-002cd1c4695a9efb2` | Workload node running Amazon Linux 2023 with mandatory IMDSv2 tokens | PCI 2.2 / SOC 2 CC6.1 |
| **19** | **AWS Security Groups** | `sg-0401849589b4d299e` / Quarantine | Hypervisor firewall; quarantine SG enforces 0 inbound and 0 outbound rules | PCI 1.2 / SOC 2 CC6.7 |
| **20** | **Amazon S3** | `sathvik-forensics-009160054307` | Cryptographically sealed forensic bucket & Static Website Hosting | PCI 3.4 / SOC 2 CC6.1 |

---

## 5. How Anyone Can Clone & Run the Whole Process

Follow these instructions to clone, deploy, and verify the entire DevSecOps architecture on any AWS account:

### Step 1: Prerequisites
Ensure your system has the following tools installed:
* **Git**: `git --version` (2.30+)
* **AWS CLI v2**: `aws --version` (Configured with credentials having administrator/security permissions)
* **Terraform**: `terraform --version` (v1.5.0+)
* **Python**: `python --version` (3.10+ with `boto3`, `python-docx`, `pypdf`, `requests`)

Verify AWS access:
```bash
aws sts get-caller-identity
```

### Step 2: Clone the Repository
```bash
git clone https://github.com/sathvikvalivety/aws-devsecops-pipeline-ps2.git
cd aws-devsecops-pipeline-ps2
```

### Step 3: Deploy Infrastructure via Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
cd ..
```
*Outputs generated:*
* VPC, Subnets, Route Tables, NAT Gateways
* EC2 Payment Node with IMDSv2 enforced
* ECR Private Repository with Immutable tags
* Secrets Manager Secret with 30-day rotation Lambda
* EventBridge Rule & SOAR Lambda
* S3 Forensics Bucket with KMS CMK Encryption
* S3 Dashboard Bucket & API Gateway HTTP API v2

### Step 4: Access the Live Cyber Command Center
You can use the system in two ways:

#### Option A: Direct Cloud Access (No Laptop Required)
Open your browser and navigate to:
```
http://sathvik-devsecops-dashboard-009160054307.s3-website-us-east-1.amazonaws.com
```

#### Option B: Local Command Center (Proxies to AWS Cloud API)
```bash
python dashboard/server.py
```
Open [http://localhost:8080](http://localhost:8080) in your browser. All button clicks and telemetry queries execute live against API Gateway `https://gq4mp9mxwc.execute-api.us-east-1.amazonaws.com`.

---

### Step 5: Run Demos via Cloud API Gateway

All 15 demos run natively in AWS via API Gateway:

```bash
# Run all 15 cloud demos end-to-end
curl -X POST https://gq4mp9mxwc.execute-api.us-east-1.amazonaws.com/api/run-demo \
     -H "Content-Type: application/json" \
     -d '{"demo_id": "all"}'

# Run individual Phase demos (e.g., Demo 01 Checkov IaC Scan)
curl -X POST https://gq4mp9mxwc.execute-api.us-east-1.amazonaws.com/api/run-demo \
     -H "Content-Type: application/json" \
     -d '{"demo_id": "01"}'

# Run Demo 06 Container Vulnerability Gate
curl -X POST https://gq4mp9mxwc.execute-api.us-east-1.amazonaws.com/api/run-demo \
     -H "Content-Type: application/json" \
     -d '{"demo_id": "06"}'
```

---

### Step 6: Execute Phase 4 Threat Simulation & SOAR Quarantine

Simulate an active attack on the payment workload node and observe immediate AWS hypervisor containment:

```bash
# 1. Trigger Attack & Automated Quarantine (< 2 seconds)
curl -X POST https://gq4mp9mxwc.execute-api.us-east-1.amazonaws.com/api/quarantine

# 2. Verify Hypervisor-Level Isolation in AWS (Shows 0 Inbound & 0 Outbound Rules)
aws ec2 describe-security-groups \
    --group-ids sg-0a0a38a865302e6bc \
    --region us-east-1

# 3. Verify KMS-Encrypted Forensic Evidence in Amazon S3
aws s3 ls s3://sathvik-forensics-009160054307/evidence/ --region us-east-1

# 4. Trigger Controlled Rollback to Production In-Service
curl -X POST https://gq4mp9mxwc.execute-api.us-east-1.amazonaws.com/api/rollback
```

---

### Step 7: Regenerate Word & PDF Audit Reports

To recompile the official 25-page audit report with fresh AWS telemetry:
```bash
python scripts/generate_docx_report.py
```
The script automatically builds `DevSecOps_Security_Audit_and_SOAR_Report.docx` and exports `DevSecOps_Security_Audit_and_SOAR_Report.pdf` with all 26 figures embedded.

---

## 6. PCI-DSS v4.0 & SOC 2 Compliance Matrix

| PCI-DSS v4.0 Requirement | SOC 2 Trust Criteria | Implemented Control | Verified Evidence Figure |
| :--- | :--- | :--- | :--- |
| **Req 1.1, 1.2: Network Boundaries** | **CC6.6, CC6.7: Boundary Defense** | Multi-tier VPC segmentation, isolated route tables, Network Firewall subnets | **Figures 13 & 14** (VPC Subnets & Route Tables) |
| **Req 2.2: System Hardening** | **CC6.1: Hardening** | IMDSv2 required on EC2, non-root user (UID 10001), read-only root filesystems | **Figures 12 & 17** (ECS Task & EC2 IMDSv2) |
| **Req 3.4, 3.5: Cryptographic Protection** | **CC6.1, CC6.3: Data at Rest** | KMS CMK (`alias/sathvik_kms_key`) encrypting S3 forensics and Secrets Manager | **Figures 6 & 24** (KMS CMK & Secrets Manager) |
| **Req 6.2: Vulnerability Management** | **CC7.1: Patch Management** | SSM Patch Manager (`sathvik_pci_patch_baseline`) enforcing 0-day auto-approval | **Figure 15** (SSM Patch Baseline) |
| **Req 6.4: Pre-Deployment Security** | **CC7.1, CC8.1: Change Mgmt** | Shift-left Checkov IaC scans & detect-secrets in AWS CodePipeline | **Figures 8 & 9** (CodeBuild & CodePipeline) |
| **Req 8.2: Credential Governance** | **CC6.1: Access Credentials** | 30-day automated rotation via Lambda & Secrets Manager; zero hardcoded secrets | **Figures 6 & 7** (Secrets Manager & CloudWatch) |
| **Req 10.2: Logging & Surveillance** | **CC7.2: Continuous Monitoring**| VPC Flow Logs streaming 100% of network packets to CloudWatch Logs | **Figure 16** (VPC Flow Logs) |
| **Req 12.10: Incident Response** | **CC7.3: Incident Response** | Automated SOAR quarantine via EventBridge/Lambda; memory dump to encrypted S3 | **Figures 18, 20, 21 & 23** (SOAR & S3 Forensics) |

---

## 7. Repository Structure

```
.
├── DevSecOps_Security_Audit_and_SOAR_Report.docx  # Official 25-page Word Audit Report (8.3 MB)
├── DevSecOps_Security_Audit_and_SOAR_Report.pdf   # Official PDF Audit Report (9.0 MB)
├── ps2.pdf                                       # Official Problem Statement Specification
├── README.md                                     # Complete Project Documentation & Execution Guide
├── .gitignore                                    # Excludes terraform binaries and local state
│
├── application/                                  # Fintech payment microservice sample code
├── architecture/                                 # Architecture diagrams and specifications
├── attack-simulation/                            # Microservice attack payload generators
├── build/                                        # CodeBuild buildspec files (Checkov, detect-secrets)
├── dashboard/                                    # Command Center frontend (index.html) & local proxy
│   ├── index.html                                # S3-hosted single page application
│   └── server.py                                 # Proxy forwarding requests to API Gateway
├── demos/                                        # Cloud demonstration runners (Demos 01 - 15)
├── docs/                                         # Project documentation archive & report copies
├── evidence/                                     # Raw forensic evidence and screenshot captures
│   └── service images/                           # All 25 live AWS console screenshots + ps2 diagram
├── kubernetes/                                   # Hardened Kubernetes / EKS manifests
├── lambda/                                       # AWS Lambda source code
│   ├── dashboard_backend/                        # API Gateway Python backend (Boto3)
│   ├── secret_rotation/                          # 4-step automated 30-day credential rotation
│   └── soar_remediation/                         # Event-driven SOAR incident containment
├── pipeline/                                     # AWS CodePipeline & CodeBuild definitions
├── scripts/                                      # Automation scripts & docx report generator
│   └── generate_docx_report.py                   # Automated Word & PDF generator
├── security-tests/                               # Static analysis benchmarks (Checkov, Trivy)
├── ssm/                                          # AWS Systems Manager run command & patch baselines
└── terraform/                                    # Terraform Infrastructure as Code (IaC) modules
    ├── dashboard.tf                              # S3 website & API Gateway infrastructure
    ├── main.tf                                   # Core provider & VPC definitions
    └── ...
```

---

## 8. Verification & Auditor Sign-Off

* **Candidate / Lead Engineer**: **Valivety Sathvik** (`sathvikvalivety`)
* **Registration / Roll Number**: **CH.SC.U4CYS23050**
* **Target Environment**: AWS Account ID `009160054307` | Region `us-east-1`
* **Status**: **VERIFIED & AUDITED (100% Cloud-Native Execution)**
* **License**: MIT
