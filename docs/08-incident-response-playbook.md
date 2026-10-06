# SOAR Incident Response Playbook: Cloud-Native Threat Containment

**Playbook ID:** `IR-PLAYBOOK-SOAR-01`  
**Target:** Payment Processing Infrastructure on AWS  
**Author:** sathvik-devsecops  

---

## 1. Trigger & Classification
- **Triggers:**
  - Amazon GuardDuty high/critical findings (e.g. `Backdoor:EC2/C&CActivity.B!DNS`, `UnauthorizedAccess:EC2/PortScan`, `Trojan:EC2/DNSDataExfiltration`).
  - Synthetic EventBridge threat events from detection engines (`sathvik.security`).
- **Classification Criteria:**
  - **SEV-1 (Critical - Score >= 7.0):** Immediate active intrusion, unauthorized outbound connection, port scan, data exfiltration. Automatic quarantine triggered.
  - **SEV-2 (High / Medium):** Anomalous internal activity. Snapshot and live alert generated.

---

## 2. Automated Execution Steps (The SOAR Engine)

```
[Threat Detected] 
       │
       ▼
[EventBridge Rule: sathvik_threat_detection_rule]
       │
       ▼
[SOAR Lambda: sathvik_soar_remediation]
       │
   ┌───┴─────────────────────────────────────────────┐
   │ 1. SNAPSHOT ORIGINAL SECURITY GROUPS            │
   │    Preserves network configuration for rollback │
   │                                                 │
   │ 2. ATTACH QUARANTINE SECURITY GROUP             │
   │    sg-0a0a38a865302e6bc (Zero Ingress/Egress)   │
   │                                                 │
   │ 3. TAG TARGET INSTANCE                          │
   │    IncidentStatus=QUARANTINED                   │
   │                                                 │
   │ 4. DISPATCH SSM FORENSIC RUN COMMAND            │
   │    sathvik-forensic-collection                  │
   │                                                 │
   │ 5. UPLOAD ARTIFACTS TO ENCRYPTED S3             │
   │    sathvik-forensics-009160054307               │
   │    Encrypted via KMS CMK (alias/sathvik_kms_key)│
   └─────────────────────────────────────────────────┘
```

---

## 3. Human Analyst Verification & Rollback Procedures

1. **Verify Containment:**
   ```bash
   aws ec2 describe-instances --instance-ids <instance-id> --query "Reservations[*].Instances[*].SecurityGroups" --profile sathvik-dev
   ```
   Confirm security group is `sg-0a0a38a865302e6bc`.

2. **Analyze Forensic Bundle:**
   ```bash
   aws s3 ls s3://sathvik-forensics-009160054307/evidence/ --profile sathvik-dev
   ```
   Inspect volatile triage manifest, open sockets, and process hierarchy.

3. **Execute Verified Rollback:**
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\scripts\rollback-quarantine.ps1 -InstanceId <instance-id>
   ```
   Restores `sathvik_app_sg` and marks incident as `RESOLVED`.
