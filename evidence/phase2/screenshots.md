# Phase 2 Screenshot Evidence & Verification Catalog

**AWS Account ID:** `009160054307`  
**AWS Region:** `us-east-1`  
**IAM Identity:** `arn:aws:iam::009160054307:user/sathvik-cli`  
**Profile:** `sathvik-dev`  

---

## Screenshot Inventory

| Screenshot ID | Filename | Description | Status / Result | AWS Resource Verified |
|---|---|---|---|---|
| **Phase2-01** | `phase2_01_ecr_repository.png` | AWS ECR repository creation with AES-256 encryption, tag immutability, and scan on push | VERIFIED | `arn:aws:ecr:us-east-1:009160054307:repository/sathvik-payment-service` |
| **Phase2-02** | `phase2_02_ecr_scan_configuration.png` | ECR Registry automated scanning rules and continuous vulnerability discovery | VERIFIED | `CONTINUOUS_SCAN` & `BASIC` scan rules on push |
| **Phase2-03** | `phase2_03_trivy_vulnerable_scan.png` | Trivy vulnerability scan of unpatched dependencies and insecure Dockerfile | FAILED (Expected) | 11 CRITICAL, 42 HIGH CVEs flagged + Root execution misconfiguration `DS-0002` |
| **Phase2-04** | `phase2_04_vulnerability_gate_blocked.png` | Container Vulnerability Gate script blocking deployment of insecure image | BLOCKED (Expected) | Pipeline gate enforces immediate deployment rejection on CRITICAL/HIGH findings |
| **Phase2-05** | `phase2_05_vulnerability_gate_passed.png` | Container Vulnerability Gate script authorizing deployment of remediated image | PASSED | 0 CRITICAL, 0 HIGH CVEs detected; workload certified |
| **Phase2-06** | `phase2_06_trivy_secure_scan.png` | Deep Trivy vulnerability scan showing clean state on remediated container | PASSED | Zero CVEs in dependencies and zero Dockerfile misconfigurations |
| **Phase2-07** | `phase2_07_kubernetes_manifests.png` | Checkov static analysis pass on hardened Kubernetes manifests | PASSED | 24 security checks passed (non-root UID 10001, drop ALL caps, read-only root, probes, limits) |
| **Phase2-08** | `phase2_08_eks_deployment_status.png` | AWS ECS Cluster & hardened Task Definition registered in AWS | VERIFIED | `arn:aws:ecs:us-east-1:009160054307:cluster/sathvik-cluster` & `task-definition/sathvik-payment-service:1` |

---

## Container Security Principles Demonstrated
1. **Automated Vulnerability Gating:** High/Critical CVEs immediately halt CI/CD progression before deployment.
2. **Minimal Attack Surface:** Multi-stage Docker builds strip compiler tools, package managers, and root access.
3. **Pod Security Standards (Restricted):** Workloads execute with non-root user `10001`, dropped Linux capabilities, and immutable root filesystems.
4. **Registry Hardening:** ECR repository enforces immutable tags and automated vulnerability scanning on push.
