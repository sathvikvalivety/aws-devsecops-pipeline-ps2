# Phase 2: Container Security & Vulnerability Gating

**AWS Account:** `009160054307` | **Region:** `us-east-1` | **Profile:** `sathvik-dev`

---

## 1. Problem Statement & Objectives
Containerized workloads frequently bundle outdated base OS packages and third-party libraries vulnerable to remote code execution and denial of service. Phase 2 introduces container hardening, automated vulnerability scanning in Amazon ECR, a strict deployment gate script that blocks High/Critical CVEs, and CIS-hardened Kubernetes / Amazon ECS workload definitions.

---

## 2. Hardened Application & Container Architecture

### Payment Processing Microservice
- Code location: [`application/main.py`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/application/main.py)
- Features: PCI-DSS compliant tokenized transaction processing, health check `/health`, dynamic AWS Secrets Manager credential binding.
- Hardened Dockerfile: [`application/Dockerfile`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/application/Dockerfile)
  - Multi-stage build (`builder` -> `runtime`)
  - Base: Pinned `python:3.11-slim-bookworm`
  - Stripped package managers, build utilities, and caches
  - Dedicated unprivileged user: `appuser` (UID: `10001`, GID: `10001`)
  - Read-only root filesystem compatible
  - Built-in container healthcheck

---

## 3. Vulnerability Gating & Scanning

### Real AWS ECR Repository
- **Repository Name:** `sathvik-payment-service`
- **ARN:** `arn:aws:ecr:us-east-1:009160054307:repository/sathvik-payment-service`
- **Image Scanning:** `scanOnPush = true`
- **Tag Mutability:** `IMMUTABLE` (prevents tag hijacking)
- **Encryption:** `AES256`

### Automated Vulnerability Gate Script
- Script location: [`pipeline/vulnerability-gate.ps1`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/pipeline/vulnerability-gate.ps1)
- Policy: Reject deployment if `CRITICAL > 0` OR `HIGH > 0`.
- Insecure Test Run: Tested against `security-tests/containers/vulnerable/`. Flagged 11 Critical, 42 High CVEs and Dockerfile root misconfiguration `DS-0002`. Script exited with code 1 and blocked deployment.
- Remediated Test Run: Tested against `application/`. Flagged 0 Critical, 0 High CVEs. Script exited with code 0 and authorized deployment to Amazon EKS / ECS.

---

## 4. Workload Orchestration (Amazon ECS & Kubernetes)

### Amazon ECS Cluster
- **Cluster Name:** `sathvik-cluster`
- **Cluster ARN:** `arn:aws:ecs:us-east-1:009160054307:cluster/sathvik-cluster`
- **Container Insights:** `enabled`
- **Task Definition:** `arn:aws:ecs:us-east-1:009160054307:task-definition/sathvik-payment-service:1`
  - Non-root user: `10001`
  - Read-only root filesystem: `true`
  - CloudWatch Logs: `/ecs/sathvik-payment-service`

### Kubernetes Manifests Hardening
- Manifests: `kubernetes/namespace.yaml`, `deployment.yaml`, `service.yaml`, `networkpolicy.yaml`, `serviceaccount.yaml`, `hpa.yaml`.
- Pinned immutable image digest: `@sha256:7b5d259e8751859c25f7789a508b9816560932de07fb2cb0d00f722a9f4c39f1`
- Security Context: `runAsNonRoot: true`, `runAsUser: 10001`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, `capabilities: { drop: ["ALL"] }`.
- Checkov Kubernetes scan: 24 passed, 0 failed.

---

## 5. Evidence Artifacts
- `evidence/phase2/phase2_01_ecr_repository.png`
- `evidence/phase2/phase2_02_ecr_scan_configuration.png`
- `evidence/phase2/phase2_03_trivy_vulnerable_scan.png`
- `evidence/phase2/phase2_04_vulnerability_gate_blocked.png`
- `evidence/phase2/phase2_05_vulnerability_gate_passed.png`
- `evidence/phase2/phase2_06_trivy_secure_scan.png`
- `evidence/phase2/phase2_07_kubernetes_manifests.png`
- `evidence/phase2/phase2_08_eks_deployment_status.png`
