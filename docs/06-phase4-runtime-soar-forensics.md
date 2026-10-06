# Phase 4: Runtime Threat Remediation & Forensic Acquisition

**AWS Account:** `009160054307` | **Region:** `us-east-1` | **Profile:** `sathvik-dev`

---

## 1. Problem Statement & Objectives
Even with hardened build pipelines and network segmentation, zero-day vulnerabilities or compromised runtime credentials can lead to active intrusions. When an intrusion occurs, security operations cannot rely on slow manual intervention. Phase 4 provides automated runtime threat detection, instantaneous network isolation via Security Group quarantine, live volatile memory and network forensic collection via SSM, and cryptographic evidence preservation in S3.

---

## 2. Detection & Threat Ingestion Infrastructure

### VPC Flow Logs
- **Flow Log ID:** `fl-015a0f8e30012e5f8`
- **Target VPC:** `vpc-0eeb82d10ba282c2d` (`sathvik_vpc`)
- **Traffic Captured:** `ALL` (Accept and Reject)
- **Destination:** CloudWatch Logs Group `/aws/vpc/sathvik_flow_logs`
- **IAM Delivery Role:** `arn:aws:iam::009160054307:role/sathvik_flow_logs_role`

### Amazon EventBridge Threat Routing
- **Rule Name:** `sathvik_threat_detection_rule`
- **Rule ARN:** `arn:aws:events:us-east-1:009160054307:rule/sathvik_threat_detection_rule`
- **Pattern:** Ingests findings from `aws.guardduty` and `sathvik.security` for finding types such as Port Scans, C2 communication, and anomalous execution.
- **Target:** Dispatches directly to `sathvik_soar_remediation` Lambda function.

---

## 3. SOAR Automated Incident Response Protocol

### Lambda Function: `sathvik_soar_remediation`
- **Function ARN:** `arn:aws:lambda:us-east-1:009160054307:function:sathvik_soar_remediation`
- **Runtime:** Python 3.11
- **Execution Role:** `arn:aws:iam::009160054307:role/sathvik_soar_role`

### The 4-Step Remediation Workflow
1. **DETECT:** Ingests finding payload (instance ID, severity score, threat classification, source IP).
2. **DECIDE:** Evaluates severity threshold. Findings with severity >= 7.0 or classified as C2/Backdoor/PortScan trigger immediate isolation.
3. **ENFORCE (Quarantine):**
   - Preserves original security groups in incident metadata.
   - Replaces all network security groups on the host with `sathvik_quarantine_sg` (`sg-0a0a38a865302e6bc`).
   - Tags the target instance: `IncidentStatus=QUARANTINED`, `IncidentId=<id>`, `QuarantineTimestamp=<iso>`.
   - Halts all ingress and egress network traffic instantly without stopping the host (preserving volatile memory).
4. **COLLECT & PRESERVE:**
   - SSM Run Command executes [`ssm/forensic-collection-document.json`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/ssm/forensic-collection-document.json) to dump process tree, active sockets (`netstat`, `ss`), open files (`lsof`), logged-in users, bash history, and temporary file hashes.
   - Packages artifacts into a gzip bundle and hashes it with SHA256.
   - Uploads bundle and forensic manifest directly to dedicated encrypted S3 bucket.

---

## 4. Cryptographic Storage & Forensic Key Management

- **Customer Managed Key (CMK):** `arn:aws:kms:us-east-1:009160054307:key/7905802c-d140-43d8-b64b-396b766b8e73` (`alias/sathvik_kms_key`)
- **Forensic S3 Bucket:** `sathvik-forensics-009160054307`
  - Versioning: Enabled
  - Public Access Block: All 4 controls enabled
  - Encryption: Default SSE-KMS using `alias/sathvik_kms_key`
  - Verified Evidence: `evidence/<incident-id>/forensic-manifest.json` and `incidents/<incident-id>/incident-record.json` stored with zero plaintext tampering possible.

---

## 5. Containment Rollback Capability
- **Script:** [`scripts/rollback-quarantine.ps1`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/scripts/rollback-quarantine.ps1)
- Validates forensic evidence preservation in S3.
- Safely revokes `sathvik_quarantine_sg` and restores original production security groups (`sathvik_app_sg`).
- Marks incident as `RESOLVED`.

---

## 6. Evidence Artifacts
- `evidence/phase4/phase4_01_vpc_flow_logs.png`
- `evidence/phase4/phase4_02_eventbridge_rule.png`
- `evidence/phase4/phase4_03_soar_lambda_function.png`
- `evidence/phase4/phase4_04_kms_cmk_key.png`
- `evidence/phase4/phase4_05_forensic_s3_bucket.png`
- `evidence/phase4/phase4_06_threat_simulation_trigger.png`
- `evidence/phase4/phase4_07_forensic_evidence_in_s3.png`
- `evidence/phase4/phase4_08_rollback_quarantine.png`
