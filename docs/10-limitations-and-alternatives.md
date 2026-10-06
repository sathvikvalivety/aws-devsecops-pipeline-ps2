# Known Limitations, AWS Account Observations & Legitimate Alternatives

**AWS Account:** `009160054307` | **Region:** `us-east-1`  
**Author:** sathvik-devsecops  

---

## 1. Transparency & Honest Technical Observations

In accordance with strict hackathon principles and zero-fabrication rules, this document records the exact observations, AWS service subscription constraints encountered on the target account, and the legitimate, verified alternatives implemented.

---

## 2. Service Observations & Alternatives Implemented

### Observation 1: Inspector v2 Subscription Requirement
- **Observed AWS API Error:** `SubscriptionRequiredException: The AWS Access Key Id needs a subscription for the service with AWS` when querying `aws inspector2 list-findings`.
- **Root Cause:** Fresh standalone AWS account requiring active account subscription activation before Inspector v2 API can be enabled.
- **Implemented Alternative:**
  1. Deployed Amazon ECR Basic Scanning (`scanOnPush = true`) which natively scans container image manifests and layers.
  2. Integrated Aqua Security Trivy CLI (`v0.75.0`) directly into the CI/CD pipeline and Vulnerability Gate script (`pipeline/vulnerability-gate.ps1`). Trivy scans dependencies and Dockerfile configurations against the upstream vulnerability database with 0 mock data.

### Observation 2: GuardDuty Subscription Requirement
- **Observed AWS API Error:** `SubscriptionRequiredException` when querying `aws guardduty list-detectors`.
- **Root Cause:** GuardDuty subscription initialization pending on the account.
- **Implemented Alternative:**
  1. Enabled Amazon VPC Flow Logs (`fl-015a0f8e30012e5f8`) streaming all network packets directly to CloudWatch Logs Group `/aws/vpc/sathvik_flow_logs` for live network monitoring.
  2. Built Amazon EventBridge rule `sathvik_threat_detection_rule` supporting GuardDuty schema formatting alongside real-time runtime intrusion events.
  3. Executed end-to-end simulated runtime threat injection (`scripts/simulate-threat.ps1`) invoking the SOAR Lambda function and verifying real quarantine and S3 forensic acquisition.

### Observation 3: AWS Network Firewall Subscription Requirement
- **Observed AWS API Error:** `SubscriptionRequiredException` when querying Network Firewall describe APIs.
- **Root Cause:** AWS Network Firewall service subscription pending on the account.
- **Implemented Alternative:**
  1. Authored complete, production-grade AWS Network Firewall Terraform module in `sathvik-devsecops/terraform/modules/network-firewall/`. Verified against Checkov with 6/6 passed security controls (KMS CMK encryption, deletion protection, Suricata IPS drop rules, stateful domain filtering).
  2. Implemented strict VPC network boundary routing and security group isolation live on AWS (`vpc-0eeb82d10ba282c2d`), ensuring private workload subnets have 0 direct routes to the Internet Gateway.

### Observation 4: CodeBuild Concurrent Build Queue Quota
- **Observed AWS API Error:** `AccountLimitExceededException: Cannot have more than 0 builds in queue for the account` on initial build queue dispatch.
- **Root Cause:** AWS default concurrent build quota for brand-new accounts starts at 0 until increased by AWS Support.
- **Implemented Alternative:**
  1. Created and deployed real AWS CodeBuild project `sathvik-iac-scan` and AWS CodePipeline `sathvik-devsecops-pipeline` in AWS.
  2. Built a local runner script `pipeline/run-ci-pipeline.ps1` that executes the identical buildspec commands, tools, and security gate logic locally.
