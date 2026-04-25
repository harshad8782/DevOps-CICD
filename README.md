# 🚀 DevOps CI/CD Pipeline Demo

> A complete end-to-end **DevOps CI/CD pipeline** built with Spring Boot, Docker, GitHub Actions, Terraform, and AWS — demonstrating automated build, containerization, cloud infrastructure provisioning, deployment workflows, production-grade log analysis, code quality gates, security scanning, and email alerting.

---

## 📌 Evolution — From Local to Cloud

This project went through two major architectural phases. Both are documented here to show the real-world progression of a DevOps pipeline.

---

### 🔵 Phase 1 — Original Architecture (Local Jenkins + Docker Hub)

```
Developer → GitHub Push
                ↓
        GitHub Actions (CI)
                ↓
    Maven Build → JUnit Tests → JaCoCo Coverage
                ↓
    SonarCloud Quality Gate → Trivy Security Scan
                ↓
    Docker Build → Push to Docker Hub
                ↓
        Jenkins (CD) — Local / Self-Hosted
                ↓
    Clone Repo → Pull Image from Docker Hub
                ↓
    Run Container → Health Check (retry 5x)
                ↓
    Log Analysis (Bash / PowerShell via isUnix())
                ↓
    ✅ Pass  → Verify & Email Alert + Stats Report
    🔴 Fail  → Auto Rollback + Email Alert + Stats Report
```

**What was used:**

| Tool | Role |
|------|------|
| GitHub Actions | CI only — build, test, quality, push |
| Jenkins (local) | CD only — deploy, health check, log analysis |
| Docker Hub | Image registry |
| Bash / PowerShell | Log analysis with OS detection via `isUnix()` |
| Email (SMTP via Jenkins) | Pipeline alerts with stats report attached |

**Limitations of Phase 1:**
- Jenkins had to be running locally at all times
- No cloud infrastructure — everything was `localhost`
- Docker Hub used instead of a private cloud registry
- Manual Jenkins setup and configuration required
- No infrastructure-as-code — server setup was manual

---

### 🟠 Phase 2 — Current Architecture (GitHub Actions + Terraform + AWS)

```
Developer → GitHub Push to main
                ↓
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
              ci.yml — GitHub Actions CI
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Checkout → Maven Build → JUnit Tests
                ↓
    JaCoCo Coverage Report (uploaded as artifact)
                ↓
    SonarCloud Quality Gate
                ↓
    Configure AWS → Login to ECR
                ↓
    Docker Build → Trivy Security Scan
                ↓
    Push versioned image to Amazon ECR
    (e.g. devops-demo:v1.71.0 + devops-demo:latest)
                ↓
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
         cd.yml — GitHub Actions CD
         (triggers automatically on CI success)
    ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                ↓
    JOB 1 — Terraform Provision Infrastructure
                ↓
    terraform init (S3 remote state backend)
    terraform plan → terraform apply
                ↓
    AWS Resources Created / Updated:
      ├── TLS Key Pair (RSA 4096) → .pem written to disk
      ├── AWS Key Pair registered
      ├── IAM Role + Instance Profile (ECR read access)
      ├── Security Group (ports 22, 80, 8081)
      ├── EC2 Instance (Ubuntu 24.04, userdata installs Docker + AWS CLI)
      └── Elastic IP (stable public IP)
                ↓
    Extract EC2 IP + PEM key from Terraform outputs
    (PEM base64-encoded → passed to deploy job securely)
                ↓
    Wait for EC2 SSH to open (port 22 check)
                ↓
    JOB 2 — Deploy → Health Check → Log Analysis → Email
                ↓
    Write PEM key to runner filesystem
                ↓
    Wait for Docker + AWS CLI ready on EC2
    (polls every 15s, breaks as soon as both respond)
                ↓
    Fetch latest versioned image tag from ECR
                ↓
    SSH into EC2 → ECR login via IAM Role → docker pull
                ↓
    Save current container version → Stop old → Run new
    (auto rollback if docker run fails)
                ↓
    Health Check — curl http://EC2_IP:8081
    (retry 5 times × 10s — rollback on failure)
                ↓
    OS Detection (mirrors Jenkins isUnix() pattern):
      uname = Linux/Darwin → log_analyzer.sh   ← always on GitHub runners
      uname = Windows      → log_analyzer.ps1  ← self-hosted Windows runner
                ↓
    SCP log_analyzer.sh to EC2 → Run remotely
                ↓
    Scans last 500 lines of container logs
      ├── exit 0 → ✅ SUCCESS  → email + stats.txt attached
      ├── exit 2 → 🟡 UNSTABLE → email + stats.txt attached
      └── exit 3 → 🔴 FAILURE  → deployment blocked + email + stats.txt
                ↓
    SCP stats report back to runner → Upload as artifact
                ↓
    Verify Deployment (docker ps + docker logs)
                ↓
    Cleanup PEM key from runner filesystem
```

---

## 🛠️ Technologies Used

| Tool | Purpose |
|------|---------|
| Java 17 | Application language |
| Spring Boot | Web application framework |
| Maven | Build automation |
| JUnit | Unit testing |
| JaCoCo | Code coverage reporting |
| SonarCloud | Code quality gate |
| Trivy | Docker image security scanning |
| Docker | Containerization |
| GitHub Actions | Full CI + CD pipeline (cloud) |
| Terraform | Infrastructure as Code — provisions all AWS resources |
| Amazon ECR | Private Docker image registry |
| Amazon EC2 | Cloud server running the application |
| Amazon S3 | Terraform remote state storage (versioned) |
| AWS IAM | EC2 role with ECR read access |
| Bash Scripting | Log analysis & DevOps automation |
| PowerShell | Log analysis for Windows runners |
| Email (SMTP / Gmail) | Pipeline alert notifications |

---

## 📂 Project Structure

```
DevOps-CICD/
├── src/
│   └── main/java/com/devops/devopsdemo/
│       ├── DevopsdemoApplication.java
│       └── HelloController.java
│   └── test/java/com/devops/devopsdemo/
│       └── DevopsdemoApplicationTests.java
├── terraform/
│   ├── main.tf           ← EC2, IAM, Security Group, EIP, Key Pair
│   ├── variables.tf      ← aws_region, instance_type, app_name
│   ├── outputs.tf        ← ec2_public_ip, ssh_command, app_url
│   └── userdata.sh       ← Installs Docker + AWS CLI on EC2 at boot
├── .github/
│   └── workflows/
│       ├── ci.yml        ← Build, Test, Quality, Security, Push to ECR
│       └── cd.yml        ← Terraform Infra + Deploy + Health Check + Email
├── Dockerfile            ← Multi-stage build (295MB vs 676MB single-stage)
├── log_analyzer.sh       ← Linux/Mac log analysis
├── log_analyzer.ps1      ← Windows log analysis
├── pom.xml
└── README.md
```

---

## ☁️ AWS Infrastructure (Terraform-Managed)

All infrastructure is created and managed by Terraform. No manual AWS console setup required.

```
Amazon S3 (tfstate-bucket-harshad)
    └── devops-demo/terraform.tfstate   ← Remote state, versioned

Amazon ECR (devops-demo)
    ├── devops-demo:latest
    ├── devops-demo:v1.71.0
    ├── devops-demo:v1.70.0
    └── ...versioned history

Amazon EC2 (devops-demo-server)
    ├── AMI: Ubuntu 24.04 (ap-south-1)
    ├── Instance type: t3.micro
    ├── Security Group: ports 22, 80, 8081
    ├── IAM Role: ECR read access (no hardcoded credentials)
    ├── Elastic IP: stable public IP across reboots
    └── userdata.sh: Docker + AWS CLI auto-installed at boot

AWS Key Pair
    └── devops-demo-keypair.pem (generated by Terraform, used by CD workflow)
```

---

## 🔍 Automated Log Analysis

Two versions of the log analyzer are included — `log_analyzer.sh` for Linux/Mac and `log_analyzer.ps1` for Windows. Both do exactly the same job in their respective scripting languages.

The pipeline **automatically detects the OS** at runtime — mirroring the `isUnix()` pattern from Jenkins — and runs the correct script without any manual changes.

**How it works:**

```
Container starts on EC2
        ↓
GitHub Actions runner detects OS:
    [ "$(uname)" = "Linux" ]  →  log_analyzer.sh   ✅ always on cloud runners
    [ "$(uname)" = "Windows" ] → log_analyzer.ps1  ← self-hosted Windows runner
        ↓
SCP script to EC2 → Run remotely → SCP report back
        ↓
Fetches last 500 lines from docker logs
        ↓
Scans for ERROR, FATAL, CRITICAL, EXCEPTION  → threshold: 5
Scans for WARN, WARNING, DEPRECATED          → threshold: 10
        ↓
        ├── All clean      → exit 0 → ✅ SUCCESS  → email + stats.txt
        ├── Warnings only  → exit 2 → 🟡 UNSTABLE → email + stats.txt
        └── Critical found → exit 3 → 🔴 FAILURE  → deployment blocked + email + stats.txt
```

**Pipeline decision table:**

| Result | Exit Code | Status | Action |
|---|---|---|---|
| No issues | 0 | ✅ SUCCESS | Deployment live, email + report sent |
| Warnings > threshold | 2 | 🟡 UNSTABLE | Deploy allowed, team emailed with report |
| Critical errors > threshold | 3 | 🔴 FAILURE | Deployment blocked, team emailed with report |

**Bash vs PowerShell — same logic, different platform:**

| Concept | Bash (`log_analyzer.sh`) | PowerShell (`log_analyzer.ps1`) |
|---|---|---|
| Variable | `VAR="value"` | `$VAR = "value"` |
| Environment var | `${VAR:-default}` | `if ($env:VAR) { $env:VAR }` |
| Pattern match | `grep -i -c "pattern"` | `Select-String -Pattern "pattern"` |
| Write file | `echo "text" >> file` | `"text" \| Out-File -Append` |
| Exit code | `exit 3` | `exit 3` |

**OS detection — Jenkins vs GitHub Actions:**

```groovy
// Jenkins (Groovy)
if (isUnix()) {
    sh './log_analyzer.sh'
} else {
    powershell '.\\log_analyzer.ps1'
}
```

```bash
# GitHub Actions (Bash — equivalent logic)
if [ "$(uname)" = "Linux" ] || [ "$(uname)" = "Darwin" ]; then
    # run log_analyzer.sh
else
    # run log_analyzer.ps1
fi
```

**Sample stats report:**

```
====================================================
  LOG ANALYSIS STATS REPORT
====================================================
Generated     : 2026-04-24 20:20:40
Container     : devops-app
Jenkins Job   : CD — Terraform Infra + Deploy to EC2
Build Number  : #17
Lines Scanned : 500
====================================================

--------------------------------------------------
  CRITICAL ERROR PATTERNS  (threshold: 5)
--------------------------------------------------
  ERROR     : 0 occurrences
  FATAL     : 0 occurrences
  CRITICAL  : 0 occurrences
  EXCEPTION : 0 occurrences

--------------------------------------------------
  WARNING PATTERNS  (threshold: 10)
--------------------------------------------------
  WARN       : 0 occurrences
  WARNING    : 0 occurrences
  DEPRECATED : 0 occurrences

====================================================
  PIPELINE DECISION SUMMARY
====================================================
Status          : PASSED
Action          : All checks passed. Deployment is proceeding.
====================================================
```

---

## ⚙️ CI/CD Pipeline Workflow

### Step 1 — Code Commit & Push

```bash
git add .
git commit -m "Feature update"
git push origin main
```

---

### Step 2 — CI Pipeline Triggers (ci.yml)

On every push to `main`, the full CI pipeline runs automatically in GitHub Actions:

```
Checkout → Maven Build → JUnit Tests → JaCoCo Coverage
    → SonarCloud Quality Gate → ECR Login → Docker Build
    → Trivy Security Scan → Push to ECR
```

**Unit Tests — JUnit:**
```
✅ contextLoads
✅ testHelloEndpoint
```

**Code Coverage — JaCoCo:**
```
Coverage    : 46%
Lines       : 5 total, 3 covered
Methods     : 4 total, 2 covered
Classes     : 2 total, 2 covered
```

**Code Quality — SonarCloud:**
```
Quality Gate    : ✅ Passed
Security        : A
Reliability     : A
Maintainability : A
Coverage        : 60%
Duplications    : 0%
Hotspots        : 100% Reviewed
```

**Security Scan — Trivy:**
```
Target             : devops-demo:latest (ubuntu 24.04)
Vulnerabilities    : 0 ✅
Secrets            : None detected ✅
app.jar            : 0 vulnerabilities ✅
```

**Versioned image pushed to ECR:**
```bash
devops-demo:v1.71.0   ← versioned tag
devops-demo:latest    ← always points to newest
```

---

### Step 3 — CD Pipeline Triggers Automatically (cd.yml)

Triggered by `workflow_run` on CI success — no manual steps needed.

**Job 1 — Terraform Provision Infrastructure:**
- `terraform init` with S3 remote backend (`tfstate-bucket-harshad`)
- Cleans up any stale IAM resources from previous runs
- `terraform plan` → `terraform apply`
- Extracts EC2 public IP + PEM key from outputs
- Waits for SSH port to open

**Job 2 — Deploy → Health Check → Log Analysis → Email:**
- Writes PEM key securely to runner (`chmod 400`)
- Polls EC2 until Docker and AWS CLI are both ready
- Fetches latest versioned image tag from ECR
- SSH into EC2 → ECR login via IAM role → `docker pull`
- Saves current version → stops old container → starts new
- Auto rollback if `docker run` fails
- Health check: `curl http://EC2_IP:8081` — 5 retries × 10s
- Auto rollback if health check fails
- Runs log analysis remotely on EC2 (via SCP + SSH)
- Copies stats report back to runner
- Uploads stats report as GitHub Actions artifact (14 day retention)
- Sends email alert with stats report attached
- Cleans up PEM key from runner

---

### Step 4 — Auto Rollback on Failure

```
Save current container image version
        ↓
Deploy new version
        ↓
Health Check — retry 5 times × 10s
        ├── ✅ Healthy → proceed to log analysis
        └── ❌ Failed  → auto rollback to previous image
                ↓
Log Analysis
        ├── exit 0 → ✅ proceed
        ├── exit 2 → 🟡 proceed with warning email
        └── exit 3 → 🔴 deployment blocked
```

---

### Step 5 — Application Live on EC2

```
http://<EC2_ELASTIC_IP>:8081
```

> ✅ **"DevOps CI/CD Pipeline Working!"**

---

## 🐳 Dockerfile — Multi-Stage Build

```dockerfile
# Stage 1 — Build
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2 — Run
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

```
Single-stage image  →  676 MB
Multi-stage image   →  295 MB
Reduction           →  56% smaller ✅
```

---

## 🔄 CI Pipeline — ci.yml

```yaml
on:
  push:
    branches: [main]

# Steps:
# Checkout → Java 17 → Maven Build → JUnit Tests
# → JaCoCo Report → SonarCloud → AWS Credentials
# → ECR Login → Set Version Tag → Docker Build
# → Trivy Scan → Push to ECR (versioned + latest)
```

Full file: `.github/workflows/ci.yml`

---

## 🏗️ CD Pipeline — cd.yml

```yaml
on:
  workflow_run:
    workflows: ["CI — Build, Test, Quality, Push to ECR"]
    types: [completed]
    branches: [main]
  workflow_dispatch:  # manual trigger also supported

jobs:
  terraform:   # Provision / update AWS infrastructure
  deploy:      # SSH deploy + health check + log analysis + email
```

Full file: `.github/workflows/cd.yml`

---

## 💡 CI vs CD — Why Separated?

| | ci.yml (CI) | cd.yml (CD) |
|---|---|---|
| **Trigger** | Every `git push` to main | After CI succeeds |
| **Responsibility** | Build, test, quality, security, push image | Infra provisioning, deploy, verify, alert |
| **Runs on** | GitHub cloud runners | GitHub cloud runners |
| **Registry** | Pushes to Amazon ECR | Pulls from Amazon ECR |
| **Output** | Verified versioned Docker image | Running container on EC2 + email |

> Separating CI and CD is a real-world best practice — deploy only what has been built, tested, and verified.

---

## 🔐 GitHub Secrets Required

| Secret | Description |
|---|---|
| `AWS_ACCESS_KEY_ID` | IAM user access key |
| `AWS_SECRET_ACCESS_KEY` | IAM user secret key |
| `AWS_REGION` | `ap-south-1` |
| `AWS_ACCOUNT_ID` | 12-digit AWS account ID |
| `ECR_REPOSITORY` | ECR repository name (`devops-demo`) |
| `TF_STATE_BUCKET` | S3 bucket for Terraform state (`tfstate-bucket-harshad`) |
| `SONAR_TOKEN` | SonarCloud project token |
| `SMTP_USERNAME` | Gmail address for sending alerts |
| `SMTP_PASSWORD` | Gmail App Password |
| `ALERT_EMAIL` | Email address to receive pipeline alerts |

---

## 🏭 Production-Grade Pipeline Overview

### CI — Continuous Integration
```
Code Push
    ↓
Build & Compile (Maven)                  ✅
    ↓
Unit Tests (JUnit)                       ✅
    ↓
Code Coverage (JaCoCo)                   ✅
    ↓
Code Quality Gate (SonarCloud)           ✅  ──FAIL──→ ❌ Block
    ↓
Security Scan (Trivy)                    ✅
    ↓
Build Versioned Image → ECR              ✅
    ↓
Release Candidate Ready
```

### CD — Continuous Delivery
```
CI Success
    ↓
Terraform Apply (EC2 + ECR + S3 state)   ✅
    ↓
Wait for EC2 ready (Docker + AWS CLI)    ✅
    ↓
SSH Deploy with Auto Rollback            ✅
    ↓
Health Check (retry 5x)                  ✅  ──FAIL──→ 🔴 Auto Rollback
    ↓
Log Analysis (Bash / PowerShell)         ✅  ──FAIL──→ 🔴 Block + Email
    ↓
Verify Deployment                        ✅
    ↓
Email + Stats Report Attached            ✅
    ↓
✅ Deployment complete
```

---

### 🔁 Deployment Strategies

| Strategy | How it works | Risk | Use Case |
|---|---|---|---|
| **Recreate** | Stop old, start new | High — downtime | Dev/test |
| **Rolling** | Replace instances one by one | Medium | Standard production |
| **Blue/Green** | Two identical envs, switch traffic | Low | High availability |
| **Canary** | Release to small % first, then scale | Very Low | Large user base |
| **Feature Flags** | Code ships, feature toggled per user | Minimal | A/B testing |

> This project uses **Recreate** strategy with auto rollback — appropriate for single-instance demo. Production upgrade path: Canary on ECS/EKS.

---

### 📊 Production Monitoring Stack (Future)

| Tool | Purpose |
|---|---|
| **Prometheus** | Metrics — CPU, memory, request rate, error rate |
| **Grafana** | Dashboard visualisation |
| **ELK Stack** | Centralised log collection and search |
| **AWS CloudWatch** | Cloud-native monitoring for EC2 / containers |
| **PagerDuty / OpsGenie** | On-call alerts to engineers |

---

## 🔮 Feature Progress

- [x] Maven build automation ✅
- [x] Unit testing with JUnit ✅
- [x] Code coverage with JaCoCo ✅
- [x] Code quality gate with SonarCloud ✅
- [x] Security scanning with Trivy ✅
- [x] Versioned Docker image tags ✅
- [x] Multi-stage Dockerfile (56% smaller) ✅
- [x] Private image registry — Amazon ECR ✅
- [x] Infrastructure as Code — Terraform ✅
- [x] Remote Terraform state — S3 + versioning ✅
- [x] EC2 provisioning with Elastic IP ✅
- [x] IAM Role for EC2 → ECR access (no hardcoded keys) ✅
- [x] Auto rollback on deployment failure ✅
- [x] Health check after deployment ✅
- [x] Automated log analysis — Bash + PowerShell ✅
- [x] OS detection (mirrors Jenkins `isUnix()`) ✅
- [x] Stats report auto-generated and attached to email ✅
- [x] Full GitHub Actions CI + CD (Jenkins removed) ✅
- [ ] Monitoring with Prometheus + Grafana
- [ ] Kubernetes deployment with Helm charts
- [ ] Multi-environment (staging → production)

---

## 🧪 Running Locally

```bash
git clone https://github.com/harshad8782/DevOps-CICD.git
cd DevOps-CICD
mvn clean package
docker build -t devopsdemo .
docker run -p 8081:8080 devopsdemo
```

Open: `http://localhost:8081`

---

## 📋 Useful Commands

```bash
# Docker
docker ps                                    # running containers
docker logs devops-app --tail=50            # container logs
docker stop devops-app && docker rm devops-app

# Terraform (from terraform/ directory)
terraform init
terraform plan
terraform apply
terraform destroy                            # tear down all infra

# AWS ECR
aws ecr describe-images \
  --repository-name devops-demo \
  --region ap-south-1                        # list images

# AWS EC2
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=devops-demo-server" \
  --query "Reservations[*].Instances[*].PublicIpAddress"
```

---

## 👨‍💻 Author

**Harshad Raurale**
DevOps / Cloud Enthusiast

[![GitHub](https://img.shields.io/badge/GitHub-harshad8782-181717?style=flat&logo=github)](https://github.com/harshad8782)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Harshad_Raurale-0077B5?style=flat&logo=linkedin)](https://www.linkedin.com/in/harshad-raurale-9a4b4826b/)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=harshad8782_DevOps-CICD&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=harshad8782_DevOps-CICD)
[![Coverage](https://sonarcloud.io/api/project_badges/measure?project=harshad8782_DevOps-CICD&metric=coverage)](https://sonarcloud.io/summary/new_code?id=harshad8782_DevOps-CICD)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=harshad8782_DevOps-CICD&metric=bugs)](https://sonarcloud.io/summary/new_code?id=harshad8782_DevOps-CICD)
[![Security Rating](https://sonarcloud.io/api/project_badges/measure?project=harshad8782_DevOps-CICD&metric=security_rating)](https://sonarcloud.io/summary/new_code?id=harshad8782_DevOps-CICD)

---

> ⭐ If you found this project helpful, please consider giving it a star!