# 🚀 DevOps CI/CD Pipeline Demo

> A complete end-to-end **DevOps CI/CD pipeline** built with Spring Boot, Docker, GitHub Actions, and Jenkins — demonstrating automated build, containerization, deployment workflows, and production-grade log analysis with email alerting.

---

## 📌 Project Architecture
```
Developer → GitHub Push → GitHub Actions (CI) → Maven Build → Docker Image → Docker Hub
                                                                                    ↓
                                                                            Jenkins (CD)
                                                                                    ↓
                                                     Clone → Pull Image → Run Container
                                                                                    ↓
                                                                          Log Analysis
                                                                                    ↓
                                                               ✅ Pass → Verify & Alert Email
                                                               🔴 Fail → Block + Email + GitHub Issue
```

---

## 🛠️ Technologies Used

| Tool | Purpose |
|------|---------|
| Java 17 | Application language |
| Spring Boot | Web application framework |
| Maven | Build automation |
| Docker | Containerization |
| GitHub Actions | CI pipeline (cloud) |
| Jenkins | CD pipeline (local/self-hosted) |
| Docker Hub | Image registry |
| Git | Version control |
| Bash Scripting | Log analysis & DevOps automation |
| Email (SMTP) | Pipeline alert notifications |

---

## 📂 Project Structure
```
DevOps-CICD/
├── src/
│   └── main/
│       └── java/
│           └── com/devops/devopsdemo/
│               ├── DevopsdemoApplication.java
│               └── HelloController.java
├── Dockerfile
├── Jenkinsfile
├── log_analyzer.sh
├── pom.xml
├── mvnw
├── mvnw.cmd
├── README.md
└── .github/
    └── workflows/
        └── ci.yml
```

---

## 🔍 Automated Log Analysis

`log_analyzer.sh` runs as a dedicated Jenkins pipeline stage after every deployment. It pulls logs directly from the running Docker container, analyzes them against configurable thresholds, writes a `.txt` stats report, and controls the pipeline outcome automatically.

**Integrated with:**

| Tool | Integration |
|---|---|
| **Docker** | Pulls logs directly from running container via `docker logs` |
| **Jenkins** | Exit codes control pipeline pass / unstable / fail |
| **GitHub** | Auto-creates labeled issues when critical errors found |
| **Email** | Sends HTML alert with `.txt` stats report attached |

**How it works:**
```
Container starts
      ↓
log_analyzer.sh fetches last 500 lines from docker logs
      ↓
Scans for ERROR, FATAL, CRITICAL, EXCEPTION  → threshold: 5
Scans for WARN, WARNING, DEPRECATED          → threshold: 10
      ↓
      ├── All clean      → exit 0 → ✅ Jenkins SUCCESS  → email + stats.txt attached
      ├── Warnings only  → exit 2 → 🟡 Jenkins UNSTABLE → email + stats.txt attached
      └── Critical found → exit 3 → 🔴 Jenkins FAILURE  → deployment blocked
                                                         → email + stats.txt attached
                                                         → GitHub issue auto-created
```

**Pipeline decision table:**

| Result | Exit Code | Jenkins Status | Action Taken |
|---|---|---|---|
| No issues found | 0 | ✅ SUCCESS | Deployment proceeds, email + report sent |
| Warnings > threshold | 2 | 🟡 UNSTABLE | Deploy allowed, team emailed with report |
| Critical errors > threshold | 3 | 🔴 FAILURE | Deployment blocked, GitHub issue created |

📸 **Email Received:**

![mail](screenshots/mail.png)

📸 **Stats Report Attached to Email:**

![Stats Report](screenshots/attachment.png)

📸 **Critical Failure Email — Deployment Blocked:**

![Fail Email](screenshots/fail_mail.png)

---

## ⚙️ CI/CD Pipeline Workflow

### Step 1 — Code Commit & Push

Developer commits and pushes code to the `main` branch on GitHub:
```bash
git add .
git commit -m "Automated Docker Pipeline"
git push
```

📸 **Git Commit & Push:**

![Git Commit](screenshots/git_commit.png)

---

### Step 2 — GitHub Actions CI Triggers Automatically

On every push to `main`, the **GitHub Actions CI Pipeline** triggers automatically — builds the Maven project, creates a Docker image and pushes it to Docker Hub ✅

📸 **GitHub Actions Pipeline:**

![GitHub Actions](screenshots/github_actions.png)

Pipeline configuration file: `.github/workflows/ci.yml`

---

### Step 3 — Docker Image Pushed to Docker Hub

After the build succeeds, the Docker image is automatically pushed to **Docker Hub** under `harshad8782/devops-demo`.

📸 **Docker Hub Repository:**

![Docker Hub](screenshots/docker_hub_repo.png)

---

### Step 4 — Jenkins CD Pipeline Triggered

Jenkins clones the repository, pulls the latest verified image from Docker Hub, deploys the container, runs log analysis, and sends an email notification with the stats report attached.

**Jenkins Pipeline Stages:**
- ✅ Clone Repository
- ✅ Pull Image from Docker Hub
- ✅ Run Container
- ✅ Log Analysis
- ✅ Verify Deployment
- ✅ Email Notification with Stats Report Attached

📸 **Jenkins Pipeline — All Stages Green:**

![Jenkins Pipeline](screenshots/jenkins.png)

---

### Step 5 — Log Analysis Runs Automatically

After the container starts, `log_analyzer.sh` pulls logs directly from the running Docker container, analyzes them, writes a timestamped `.txt` stats report, and exits with a code that controls the pipeline outcome.

**Sample stats report contents:**
```
====================================================
  LOG ANALYSIS STATS REPORT
====================================================
Generated     : 2026-03-18 11:03:17
Container     : devops-app
Jenkins Job   : DevOps-CD
Build Number  : #21
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
Critical Issues : 0 pattern(s) exceeded threshold
Warnings        : 0 pattern(s) exceeded threshold
Action          : All checks passed. Deployment is proceeding.
====================================================
```

---

### Step 6 — Email Notification with Stats Report

On every pipeline run, an email is automatically sent to the DevOps team with the result, build details, and the full `.txt` stats report attached.

📸 **Success Email with Stats Attachment:**

![Email Alert](screenshots/mail.png)

📸 **Critical Failure Email — Deployment Blocked:**

![Fail Email](screenshots/fail_mail.png)

---

### Step 7 — Application Live in Browser

Access the running application at:
```
http://localhost:8081
```

📸 **Application Live:**

![Browser Output](screenshots/browser_output.png)

> ✅ **"DevOps CI/CD Pipeline Working!"**

---

## 🐳 Dockerfile
```dockerfile
FROM eclipse-temurin:17
COPY target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "/app.jar"]
```

---

## 🔄 GitHub Actions CI Pipeline
```yaml
# .github/workflows/ci.yml
name: DevOps CI Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build with Maven
        run: mvn clean package

      - name: Build Docker Image
        run: docker build -t harshad8782/devops-demo .

      - name: Push to Docker Hub
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          docker push harshad8782/devops-demo:latest
```

---

## 🏗️ Jenkins CD Pipeline
```groovy
pipeline {
    agent any

    environment {
        DOCKER_IMAGE   = 'harshad8782/devops-demo:latest'
        CONTAINER_NAME = 'devops-app'
        APP_PORT       = '8081'
        CONTAINER_PORT = '8080'
        ALERT_EMAIL    = 'harshadraurale29@gmail.com'
        GITHUB_TOKEN   = credentials('github-token')
        GITHUB_REPO    = 'harshad8782/DevOps-CICD'
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo '📥 Cloning repository...'
                git branch: 'main',
                    url: 'https://github.com/harshad8782/DevOps-CICD.git'
            }
        }

        stage('Pull Image') {
            steps {
                echo '📥 Pulling latest image from Docker Hub...'
                sh 'docker pull ${DOCKER_IMAGE}'
            }
        }

        stage('Run Container') {
            steps {
                echo '🚀 Deploying container...'
                sh 'docker stop ${CONTAINER_NAME} || true'
                sh 'docker rm ${CONTAINER_NAME} || true'
                sh '''
                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        -p ${APP_PORT}:${CONTAINER_PORT} \
                        --restart unless-stopped \
                        ${DOCKER_IMAGE}
                '''
                sh 'sleep 10'
            }
        }

        stage('Log Analysis') {
            steps {
                echo '🔍 Running log analysis on container...'
                sh 'chmod +x log_analyzer.sh'
                sh """
                    export CONTAINER_NAME=${CONTAINER_NAME}
                    export ALERT_EMAIL=${ALERT_EMAIL}
                    export GITHUB_TOKEN=${GITHUB_TOKEN}
                    export GITHUB_REPO=${GITHUB_REPO}
                    export WORKSPACE=${WORKSPACE}
                    export BUILD_URL=${BUILD_URL}
                    export JOB_NAME=${JOB_NAME}
                    export BUILD_NUMBER=${BUILD_NUMBER}
                    ./log_analyzer.sh
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                sh 'sleep 5'
                sh 'docker ps | grep ${CONTAINER_NAME}'
                sh 'docker logs ${CONTAINER_NAME} --tail=20'
                sh 'ls -lh ${WORKSPACE}/reports/ || echo "No reports directory found"'
            }
        }
    }

    post {
        success {
            echo '''
            ✅ ================================
               PIPELINE SUCCEEDED!
               App running at: http://localhost:8081
            ================================
            '''
            emailext(
                subject: "✅ [SUCCESS] Pipeline Passed — ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
                    <h2>✅ Pipeline Succeeded</h2>
                    <table>
                        <tr><td><b>Job</b></td><td>${JOB_NAME}</td></tr>
                        <tr><td><b>Build</b></td><td>#${BUILD_NUMBER}</td></tr>
                        <tr><td><b>Container</b></td><td>${CONTAINER_NAME}</td></tr>
                        <tr><td><b>App URL</b></td><td>http://localhost:${APP_PORT}</td></tr>
                        <tr><td><b>Build URL</b></td><td><a href="${BUILD_URL}">${BUILD_URL}</a></td></tr>
                    </table>
                    <p>✅ Log analysis passed. Deployment is live.</p>
                    <p>See attached stats report for full analysis details.</p>
                """,
                to: "${ALERT_EMAIL}",
                mimeType: 'text/html',
                attachmentsPattern: '**/reports/log_stats_*.txt'
            )
        }

        unstable {
            echo '''
            🟡 ================================
               PIPELINE UNSTABLE!
               Warnings found — check email.
            ================================
            '''
            emailext(
                subject: "🟡 [WARNING] Pipeline Unstable — ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
                    <h2>🟡 Pipeline Unstable — Warnings Found</h2>
                    <table>
                        <tr><td><b>Job</b></td><td>${JOB_NAME}</td></tr>
                        <tr><td><b>Build</b></td><td>#${BUILD_NUMBER}</td></tr>
                        <tr><td><b>Container</b></td><td>${CONTAINER_NAME}</td></tr>
                        <tr><td><b>Build URL</b></td><td><a href="${BUILD_URL}">${BUILD_URL}</a></td></tr>
                    </table>
                    <p>🟡 Warning patterns exceeded threshold. Deployment allowed but review needed.</p>
                    <p>See attached stats report for full details.</p>
                """,
                to: "${ALERT_EMAIL}",
                mimeType: 'text/html',
                attachmentsPattern: '**/reports/log_stats_*.txt'
            )
        }

        failure {
            echo '''
            ❌ ================================
               PIPELINE FAILED!
               Check logs above for errors.
            ================================
            '''
            emailext(
                subject: "🔴 [CRITICAL] Pipeline FAILED — ${JOB_NAME} #${BUILD_NUMBER}",
                body: """
                    <h2>🔴 Pipeline Failed — Deployment Blocked</h2>
                    <table>
                        <tr><td><b>Job</b></td><td>${JOB_NAME}</td></tr>
                        <tr><td><b>Build</b></td><td>#${BUILD_NUMBER}</td></tr>
                        <tr><td><b>Container</b></td><td>${CONTAINER_NAME}</td></tr>
                        <tr><td><b>Build URL</b></td><td><a href="${BUILD_URL}">${BUILD_URL}</a></td></tr>
                    </table>
                    <p>🔴 Critical errors found. Deployment has been blocked.</p>
                    <p>A GitHub issue has been auto-created. Fix errors and re-trigger pipeline.</p>
                    <p>See attached stats report for full details.</p>
                """,
                to: "${ALERT_EMAIL}",
                mimeType: 'text/html',
                attachmentsPattern: '**/reports/log_stats_*.txt'
            )
        }

        always {
            echo '🧹 Cleaning up unused Docker images...'
            sh 'docker image prune -f'
        }
    }
}
```

---

## 💡 CI vs CD — Why Separated?

| | GitHub Actions (CI) | Jenkins (CD) |
|---|---|---|
| **Trigger** | Every git push | After image pushed to Hub |
| **Responsibility** | Build, test, package, push | Clone, pull, deploy, analyze, verify |
| **Runs on** | GitHub cloud runners | Local/self-hosted server |
| **Output** | Docker image on Docker Hub | Running container + email alert |

> Separating CI and CD is a real-world best practice — deploy only what has been built and verified, never build directly on the deployment server.

---

## 🏭 Production-Grade CI/CD Pipeline

> This project demonstrates a foundational CI/CD pipeline. In a real production environment, both the CI and CD stages are significantly more detailed, with quality gates, security checks, versioned releases, controlled rollouts, and automatic rollback. Below is what a production pipeline looks like and how it differs from this demo.

---

### 🔵 Production CI — Continuous Integration

In production, CI is not just about building and pushing. Every commit goes through multiple quality gates before it is allowed to become a release candidate.
```
Code Push
    ↓
Build & Compile
    ↓
Unit Tests          → JUnit, TestNG
    ↓
Code Quality        → SonarQube (code smells, coverage, duplication)
    ↓
Security Scan       → OWASP Dependency Check, Trivy (Docker image scan)
    ↓
Integration Tests   → Test API contracts, DB connections
    ↓
Performance Tests   → JMeter, Gatling (load testing)
    ↓
Build Versioned Image → harshad8782/devops-demo:v1.4.2
    ↓
Push to Registry    → Docker Hub / AWS ECR
    ↓
Release Candidate Ready ✅
```

**Key difference from this project:**
- Every image is **versioned** (`v1.4.2`) not just `latest`
- Build is **rejected** automatically if tests fail, coverage drops, or vulnerabilities are found
- No human intervention needed — the pipeline decides if the build is release-worthy

---

### 🟠 Production CD — Continuous Delivery with Canary Deployment

In production, you never release directly to all users. A **Canary Deployment** strategy is used — the new version is released to a small percentage of users first, monitored, and then gradually rolled out to everyone only if it is stable.
```
Release Candidate (v1.4.2) approved by CI
    ↓
Deploy to Staging Environment
    ↓
Smoke Tests on Staging          → is the app even starting correctly?
    ↓
Canary Release — 5% of users get v1.4.2
    ↓
Monitor for 15–30 minutes
    ├── Error rate normal?
    ├── Response time normal?
    └── No crashes or exceptions?
         ↓ YES                        ↓ NO
    Roll out to 25% users        🔴 Automatic Rollback to v1.4.1
         ↓
    Roll out to 50% users
         ↓
    Roll out to 100% users ✅
         ↓
    Monitor production continuously
```

**Why this matters:**
- If `v1.4.2` has a critical bug, only **5% of users are affected**, not everyone
- The system **automatically detects** the issue via monitoring and rolls back
- The previous stable version (`v1.4.1`) is always kept running until the new version is fully verified

---

### 🔁 Deployment Strategies Compared

| Strategy | How it works | Risk | Use Case |
|---|---|---|---|
| **Recreate** | Stop old, start new | High — downtime | Dev/test environments |
| **Rolling** | Replace instances one by one | Medium | Standard production |
| **Blue/Green** | Run two identical envs, switch traffic | Low — instant rollback | High availability apps |
| **Canary** | Release to small % first, then scale | Very Low | Large user base, critical apps |
| **Feature Flags** | Code ships but feature is toggled on/off per user | Minimal | A/B testing, gradual feature launches |

---

### 🔴 Rollback Strategy

In production, every deployment must have a rollback plan. Versioned Docker images make this straightforward:
```bash
# Roll back to last stable version instantly
docker stop devops-app
docker rm devops-app
docker run -d \
    --name devops-app \
    -p 8080:8080 \
    harshad8782/devops-demo:v1.4.1
```

---

### 📊 Production Monitoring Stack

| Tool | Purpose |
|---|---|
| **Prometheus** | Collects metrics — CPU, memory, request rate, error rate |
| **Grafana** | Visualizes metrics in dashboards |
| **ELK Stack** | Centralized log collection and search |
| **AWS CloudWatch** | Cloud-native monitoring for EC2, containers, Lambda |
| **PagerDuty / OpsGenie** | Sends alerts to on-call engineers |

---

### 🏭 Full Production Pipeline at a Glance
```
Developer pushes code
        ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━  CI  ━━━━━━━━━━━━━━━━━━━━━━━━━━
        ↓
    Compile & Build
        ↓
    Unit Tests (JUnit)
        ↓
    Code Quality Gate (SonarQube) ──FAIL──→ ❌ Block merge
        ↓
    Security Scan (Trivy / OWASP) ──FAIL──→ ❌ Block merge
        ↓
    Integration Tests
        ↓
    Build versioned image → v1.4.2
        ↓
    Push to Docker Hub / ECR
        ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━  CD  ━━━━━━━━━━━━━━━━━━━━━━━━━━
        ↓
    Clone Repository
        ↓
    Deploy to Staging
        ↓
    Smoke Tests ──FAIL──→ ❌ Stop deployment
        ↓
    Log Analysis ──FAIL──→ 🔴 Block + Email + GitHub Issue
        ↓
    Canary → 5% users get v1.4.2
        ↓
    Monitor 15 min (Prometheus + Grafana)
        ├── ERROR ──→ 🔴 Auto Rollback to v1.4.1
        └── OK ──→ Scale to 25% → 50% → 100%
        ↓
    ✅ Full rollout complete
        ↓
    Continuous monitoring in production
```

---

## 📚 Learning Reference — Full Pipeline Using Only One Tool

---

### 🔵 Full Pipeline Using GitHub Actions Only
```yaml
name: Full CI/CD Pipeline - GitHub Actions Only

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          java-version: '17'
          distribution: 'temurin'

      - name: Build with Maven
        run: mvn clean package

      - name: Build Docker Image
        run: docker build -t harshad8782/devops-demo:latest .

      - name: Push to Docker Hub
        run: |
          echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin
          docker push harshad8782/devops-demo:latest

      - name: Deploy to Server via SSH
        uses: appleboy/ssh-action@v0.1.6
        with:
          host: ${{ secrets.SERVER_IP }}
          username: ubuntu
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            docker stop devops-app || true
            docker rm devops-app || true
            docker pull harshad8782/devops-demo:latest
            docker run -d \
              --name devops-app \
              -p 8080:8080 \
              --restart unless-stopped \
              harshad8782/devops-demo:latest
```

---

### 🔁 Comparison — Which Approach To Use?

| | GitHub Actions Only | Jenkins Only | Actions (CI) + Jenkins (CD) |
|---|---|---|---|
| **Setup effort** | Minimal | High | Medium |
| **Infrastructure** | None needed | Requires server | Requires Jenkins server |
| **Best for** | Cloud, open source | Enterprise, private | Learning, real-world pattern |
| **Customization** | Limited | Full control | Best of both worlds |
| **Cost** | Free for public repos | Free software | Free software |
| **This project uses** | ✅ CI only | ✅ CD only | ✅ Separated by design |

---

## 🧪 Running Locally

### 1. Clone the repository
```bash
git clone https://github.com/harshad8782/DevOps-CICD.git
cd DevOps-CICD
```

### 2. Build the Spring Boot application
```bash
mvn clean package
```

### 3. Build Docker image
```bash
docker build -t devopsdemo .
```

### 4. Run the container
```bash
docker run -p 8081:8080 devopsdemo
```

### 5. Open in browser
```
http://localhost:8081
```

---

## 📋 Useful Docker Commands
```bash
# List all running containers
docker ps

# List all images
docker images

# Stop a container
docker stop <container_id>

# Remove a container
docker rm <container_id>

# Pull from Docker Hub
docker pull harshad8782/devops-demo:latest
```

---

## 👨‍💻 Author

**Harshad Raurale**
DevOps / Cloud Enthusiast

[![GitHub](https://img.shields.io/badge/GitHub-harshad8782-181717?style=flat&logo=github)](https://github.com/harshad8782)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Harshad_Raurale-0077B5?style=flat&logo=linkedin)](https://www.linkedin.com/in/harshad-raurale-9a4b4826b/)

---

> ⭐ If you found this project helpful, please consider giving it a star!