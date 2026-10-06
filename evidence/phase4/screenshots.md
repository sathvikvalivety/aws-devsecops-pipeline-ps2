# Phase 4 Screenshot Evidence & Verification Catalog

**AWS Account ID:** `009160054307`  
**AWS Region:** `us-east-1`  
**IAM Identity:** `arn:aws:iam::009160054307:user/sathvik-cli`  
**Profile:** `sathvik-dev`  

---

## Screenshot Inventory

| Screenshot ID | Filename | Description | Status / Result | AWS Resource Verified |
|---|---|---|---|---|
| **Phase4-01** | `phase4_01_vpc_flow_logs.png` | AWS VPC Flow Logs capturing ALL traffic and streaming to CloudWatch Logs | VERIFIED | `fl-015a0f8e30012e5f8` on `vpc-0eeb82d10ba282c2d` -> `/aws/vpc/sathvik_flow_logs` |
| **Phase4-02** | `phase4_02_eventbridge_rule.png` | Amazon EventBridge Rule filtering GuardDuty findings and runtime incident alerts | VERIFIED | `arn:aws:events:us-east-1:009160054307:rule/sathvik_threat_detection_rule` |
| **Phase4-03** | `phase4_03_soar_lambda_function.png` | SOAR automated incident response Lambda function configuration | VERIFIED | `arn:aws:lambda:us-east-1:009160054307:function:sathvik_soar_remediation` |
| **Phase4-04** | `phase4_04_kms_cmk_key.png` | AWS KMS Customer Managed Key (CMK) for cryptographic envelope protection | VERIFIED | `arn:aws:kms:us-east-1:009160054307:key/7905802c-d140-43d8-b64b-396b766b8e73` (`alias/sathvik_kms_key`) |
| **Phase4-05** | `phase4_05_forensic_s3_bucket.png` | Dedicated encrypted S3 bucket enforcing SSE-KMS with Customer Managed Key | VERIFIED | `arn:aws:s3:::sathvik-forensics-009160054307` |
| **Phase4-06** | `phase4_06_threat_simulation_trigger.png` | Runtime threat simulation triggering EventBridge and invoking SOAR Lambda | SUCCESS (200 OK) | Detected port scanning & C2 activity, enforced quarantine isolation |
| **Phase4-07** | `phase4_07_forensic_evidence_in_s3.png` | Immutable forensic triage manifests and incident audit records stored in S3 | VERIFIED | Encrypted manifests in `s3://sathvik-forensics-009160054307/evidence/` |
| **Phase4-08** | `phase4_08_rollback_quarantine.png` | Automated containment rollback script verifying restoration of production traffic | SUCCESS | Safely revoked quarantine SG and restored production baseline with audit trace |

---

## Runtime Threat & SOAR Principles Demonstrated
1. **DETECT:** Full network packet inspection via VPC Flow Logs and near-real-time threat event capture via EventBridge.
2. **DECIDE:** Rule-driven severity matrix dynamically evaluates whether to alert, isolate, or execute live host forensics.
3. **ENFORCE (Quarantine):** Instantaneous network containment replaces production security groups with a zero-ingress, zero-egress Security Group, halting lateral movement without powering down the target host.
4. **FORENSIC COLLECTION & ACQUISITION:** Host memory, network connections, process trees, and audit trails are gathered via SSM and preserved in an S3 bucket encrypted with a Customer Managed Key.
5. **OPERATIONAL RESILIENCE (Rollback):** Original network configurations are preserved prior to isolation, enabling instant, verified rollback once threats are neutralized.
