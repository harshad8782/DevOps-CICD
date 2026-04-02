# 🚀 DevOps CI/CD Pipeline Demo

> A complete end-to-end **DevOps CI/CD pipeline** built with Spring Boot, Docker, GitHub Actions, and Jenkins — demonstrating automated build, containerization, deployment workflows, production-grade log analysis, code quality gates, security scanning, and email alerting.

---

## 📌 Project Architecture
```
Developer → GitHub Push → GitHub Actions (CI) → Maven Build → Test → Quality Gate → Security Scan → Docker Image → Docker Hub
                                                                                                                         ↓
                                                                                                                 Jenkins (CD)
                                                                                                                         ↓
                                                                              Clone → Pull Image → Run Container → Health Check
                                                                                                                         ↓
                                                                                                               Log Analysis
                                                                                                                         ↓
                                                                                          ✅ Pass → Verify & Alert Email
                                                                                          🔴 Fail → Rollback + Email + Stats Report
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
| GitHub Actions | CI pipeline (cloud) |
| Jenkins | CD pipeline (local/self-hosted) |
| Docker Hub | Image registry |
| Git | Version control |
| Bash Scripting | Log analysis & DevOps automation (Linux) |
| PowerShell | Log analysis & DevOps automation (Windows) |
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
│   └── test/
│       └── java/
│           └── com/devops/devopsdemo/
│               └── DevopsdemoApplicationTests.java
├── Dockerfile
├── Jenkinsfile
├── log_analyzer.sh          ← Linux/Mac agent
├── log_analyzer.ps1         ← Windows agent
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

Two versions of the log analyzer are included — `log_analyzer.sh` for Linux/Mac Jenkins agents and `log_analyzer.ps1` for Windows Jenkins agents. Both scripts do exactly the same job, just written in their respective scripting languages. The Jenkins pipeline **automatically detects the OS** using `isUnix()` and runs the correct script without any manual changes.

**Integrated with:**

| Tool | Integration |
|---|---|
| **Docker** | Pulls logs directly from running container via `docker logs` |
| **Jenkins** | `isUnix()` detects OS and runs `.sh` or `.ps1` automatically |
| **Email** | Sends HTML alert with `.txt` stats report attached |

**How it works:**
```
Container starts
      ↓
Jenkins detects OS using isUnix()
      ├── Linux/Mac → log_analyzer.sh
      └── Windows   → log_analyzer.ps1
      ↓
Fetches last 500 lines from docker logs
      ↓
Scans for ERROR, FATAL, CRITICAL, EXCEPTION  → threshold: 5
Scans for WARN, WARNING, DEPRECATED          → threshold: 10
      ↓
      ├── All clean      → exit 0 → ✅ Jenkins SUCCESS  → email + stats.txt attached
      ├── Warnings only  → exit 2 → 🟡 Jenkins UNSTABLE → email + stats.txt attached
      └── Critical found → exit 3 → 🔴 Jenkins FAILURE  → deployment blocked
                                                         → email + stats.txt attached
```

**Pipeline decision table:**

| Result | Exit Code | Jenkins Status | Action Taken |
|---|---|---|---|
| No issues found | 0 | ✅ SUCCESS | Deployment proceeds, email + report sent |
| Warnings > threshold | 2 | 🟡 UNSTABLE | Deploy allowed, team emailed with report |
| Critical errors > threshold | 3 | 🔴 FAILURE | Deployment blocked, team emailed with report |

**Bash vs PowerShell — same logic, different platform:**

| Concept | Bash (`log_analyzer.sh`) | PowerShell (`log_analyzer.ps1`) |
|---|---|---|
| Variable | `VAR="value"` | `$VAR = "value"` |
| Environment var | `${VAR:-default}` | `if ($env:VAR) { $env:VAR }` |
| Function | `myFunc() { }` | `function My-Func { }` |
| Pattern match | `grep -i -c "pattern"` | `Select-String -Pattern "pattern"` |
| Write file | `echo "text" >> file` | `"text" \| Out-File -Append` |
| Send email | `mail -s "subject"` | `Send-MailMessage` |
| HTTP request | `curl -X POST` | `Invoke-RestMethod -Method POST` |
| Exit code | `exit 3` | `exit 3` |

**Jenkins auto-selects the script at runtime:**
```groovy
script {
    if (isUnix()) {
        sh './log_analyzer.sh'
    } else {
        powershell '.\\log_analyzer.ps1'
    }
}
```

📸 **Success Email Received:**

![Email Alert](screenshots/mail.png)

📸 **Stats Report Attached to Email:**

![Stats Report](screenshots/attachment.png)

📸 **Critical Failure Email — Deployment Blocked:**

![Fail Email](screenshots/fail_mail.png)

---

## ⚙️ CI/CD Pipeline Workflow

### Step 1 — Code Commit & Push
```bash
git add .
git commit -m "Automated Docker Pipeline"
git push
```

📸 **Git Commit & Push:**

![Git Commit](screenshots/git_commit.png)

---

### Step 2 — GitHub Actions CI Triggers Automatically

On every push to `main`, the full CI pipeline runs automatically:
```
Checkout → Build → Unit Tests → Code Coverage → SonarCloud → Docker Build → Trivy Scan → Push to Docker Hub
```

📸 **GitHub Actions Pipeline:**

![GitHub Actions](screenshots/github_actions.png)

---

### Step 3 — Unit Tests — JUnit

Every push runs all JUnit tests automatically. Build is blocked if any test fails.
```
✅ contextLoads
✅ testHelloEndpoint
```

---

### Step 4 — Code Coverage — JaCoCo

JaCoCo generates a full coverage report after tests run. Report is uploaded as a GitHub Actions artifact.

📸 **JaCoCo Coverage Report:**

![JaCoCo](screenshots/jacoco.png)
```
Coverage    : 46%
Lines       : 5 total, 3 covered
Methods     : 4 total, 2 covered
Classes     : 2 total, 2 covered
```

---

### Step 5 — Code Quality Gate — SonarCloud

Every push is automatically scanned by SonarCloud for bugs, vulnerabilities, code smells, and coverage.

📸 **SonarCloud Dashboard:**

![SonarCloud](screenshots/sonarqube.png)
```
Quality Gate    : ✅ Passed
Security        : A
Reliability     : A
Maintainability : A
Coverage        : 60%
Duplications    : 0%
Hotspots        : 100% Reviewed
```

---

### Step 6 — Security Scan — Trivy

Docker image is scanned for CRITICAL and HIGH vulnerabilities before pushing to Docker Hub.

📸 **Trivy Security Report:**

![Trivy](screenshots/trivy_report.png)
```
Target             : harshad8782/devops-demo:latest (ubuntu 24.04)
Vulnerabilities    : 0 ✅
Secrets            : None detected ✅
app.jar            : 0 vulnerabilities ✅
```

---

### Step 7 — Versioned Docker Image Pushed to Docker Hub

Every build pushes two tags — versioned and latest:
```bash
docker push harshad8782/devops-demo:v1.42.0
docker push harshad8782/devops-demo:latest
```

📸 **Docker Hub Repository:**

![Docker Hub](screenshots/docker_hub_repo.png)

---

### Step 8 — Jenkins CD Pipeline Triggered

Jenkins clones the repository, pulls the latest verified image from Docker Hub, deploys the container with auto rollback, runs a health check, runs log analysis, and sends an email notification.

**Jenkins Pipeline Stages:**
- ✅ Clone Repository
- ✅ Pull Image from Docker Hub
- ✅ Run Container with Auto Rollback
- ✅ Health Check
- ✅ Log Analysis (Bash or PowerShell)
- ✅ Verify Deployment
- ✅ Email Notification with Stats Report Attached

📸 **Jenkins Pipeline — All Stages Green:**

![Jenkins Pipeline](screenshots/jenkins.png)

---

### Step 9 — Auto Rollback on Failure

Before deploying, Jenkins saves the current running image version. If deployment fails or health check fails after 5 retries, Jenkins automatically restarts the previous version.
```
Save current version
      ↓
Deploy new version
      ↓
Health Check — retry 5 times
      ├── ✅ Healthy → proceed
      └── ❌ Failed  → auto rollback to previous version
```

---

### Step 10 — Log Analysis Runs Automatically

After the container passes health check, the log analyzer runs, writes a timestamped `.txt` stats report, and controls the pipeline outcome via exit codes.

**Sample stats report:**
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
Action          : All checks passed. Deployment is proceeding.
====================================================
```

---

### Step 11 — Application Live in Browser
```
http://localhost:8081
```

📸 **Application Live:**

![Browser Output](screenshots/browser_output.png)

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
Old single-stage image   →  676MB
New multi-stage image    →  295MB
Reduction                →  56% smaller ✅
```

---

## 🔄 GitHub Actions CI Pipeline
```yaml
name: DevOps CI Pipeline

on:
  push:
    branches:
      - main

jobs:
  build:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      checks: write
      pull-requests: write

    steps:

      - name: Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'

      - name: Build Maven Project
        run: mvn clean package -DskipTests

      - name: Run Unit Tests
        run: mvn test

      - name: Generate Coverage Report
        run: mvn jacoco:report

      - name: Check Coverage Threshold
        run: mvn jacoco:check
        continue-on-error: true

      - name: Upload Coverage Report
        uses: actions/upload-artifact@v4
        with:
          name: jacoco-coverage-report
          path: target/site/jacoco/
          retention-days: 7

      - name: SonarCloud Scan
        run: mvn sonar:sonar -Dsonar.token=${{ secrets.SONAR_TOKEN }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

      - name: Publish Test Results
        uses: dorny/test-reporter@v1
        if: success() || failure()
        with:
          name: JUnit Test Results
          path: target/surefire-reports/*.xml
          reporter: java-junit
          fail-on-error: false

      - name: Login to DockerHub
        run: echo "${{ secrets.DOCKER_PASSWORD }}" | docker login -u "${{ secrets.DOCKER_USERNAME }}" --password-stdin

      - name: Set Version Tag
        run: echo "VERSION=v1.${{ github.run_number }}.0" >> $GITHUB_ENV

      - name: Build Docker Image
        run: |
          docker build -t ${{ secrets.DOCKER_USERNAME }}/devops-demo:${{ env.VERSION }} .
          docker build -t ${{ secrets.DOCKER_USERNAME }}/devops-demo:latest .

      - name: Trivy Security Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: ${{ secrets.DOCKER_USERNAME }}/devops-demo:latest
          format: table
          exit-code: 0
          severity: CRITICAL,HIGH
          output: trivy-report.txt

      - name: Upload Trivy Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: trivy-security-report
          path: trivy-report.txt
          retention-days: 7

      - name: Push Docker Image
        run: |
          docker push ${{ secrets.DOCKER_USERNAME }}/devops-demo:${{ env.VERSION }}
          docker push ${{ secrets.DOCKER_USERNAME }}/devops-demo:latest

      - name: Print Version Info
        run: |
          echo "✅ Image pushed successfully"
          echo "📦 Version  : ${{ env.VERSION }}"
          echo "📦 Latest   : ${{ secrets.DOCKER_USERNAME }}/devops-demo:latest"
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
                script {
                    def currentVersion = sh(
                        script: "docker inspect ${CONTAINER_NAME} --format='{{.Config.Image}}' 2>/dev/null || echo 'none'",
                        returnStdout: true
                    ).trim()

                    echo "Current running version: ${currentVersion}"

                    try {
                        sh 'docker stop ${CONTAINER_NAME} || true'
                        sh 'docker rm ${CONTAINER_NAME} || true'
                        sh """
                            docker run -d \
                                --name ${CONTAINER_NAME} \
                                -p ${APP_PORT}:${CONTAINER_PORT} \
                                --restart unless-stopped \
                                ${DOCKER_IMAGE}
                        """
                        echo "✅ New container started successfully"
                    } catch (Exception e) {
                        echo "❌ Deployment failed — rolling back to ${currentVersion}"
                        sh "docker stop ${CONTAINER_NAME} || true"
                        sh "docker rm ${CONTAINER_NAME} || true"
                        if (currentVersion != 'none') {
                            sh """
                                docker run -d \
                                    --name ${CONTAINER_NAME} \
                                    -p ${APP_PORT}:${CONTAINER_PORT} \
                                    --restart unless-stopped \
                                    ${currentVersion}
                            """
                            echo "✅ Rolled back to ${currentVersion}"
                        }
                        error "Deployment failed and rolled back to ${currentVersion}"
                    }
                }
                sh 'sleep 10'
            }
        }

        stage('Health Check') {
            steps {
                echo '🏥 Running health check...'
                script {
                    def containerIP = sh(
                        script: "docker inspect ${CONTAINER_NAME} --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}'",
                        returnStdout: true
                    ).trim()

                    echo "Container IP: ${containerIP}"

                    def maxRetries = 5
                    def count = 0
                    def healthy = false

                    while (count < maxRetries && !healthy) {
                        try {
                            sh "curl -sf http://${containerIP}:${CONTAINER_PORT} > /dev/null"
                            healthy = true
                            echo "✅ App is healthy at http://${containerIP}:${CONTAINER_PORT}"
                        } catch (Exception e) {
                            count++
                            echo "⏳ Waiting for app... attempt ${count}/${maxRetries}"
                            sleep 5
                        }
                    }

                    if (!healthy) {
                        echo "❌ Health check failed — rolling back..."
                        sh 'docker stop ${CONTAINER_NAME} || true'
                        sh 'docker rm ${CONTAINER_NAME} || true'
                        error "Health check failed — deployment rolled back"
                    }
                }
            }
        }

        stage('Log Analysis') {
            steps {
                echo '🔍 Running log analysis on container...'
                script {
                    if (isUnix()) {
                        echo '🐧 Linux agent — running log_analyzer.sh'
                        sh 'chmod +x log_analyzer.sh'
                        sh """
                            export CONTAINER_NAME=${CONTAINER_NAME}
                            export ALERT_EMAIL=${ALERT_EMAIL}
                            export WORKSPACE=${WORKSPACE}
                            export BUILD_URL=${BUILD_URL}
                            export JOB_NAME=${JOB_NAME}
                            export BUILD_NUMBER=${BUILD_NUMBER}
                            ./log_analyzer.sh
                        """
                    } else {
                        echo '🪟 Windows agent — running log_analyzer.ps1'
                        powershell """
                            \$env:CONTAINER_NAME  = '${CONTAINER_NAME}'
                            \$env:ALERT_EMAIL     = '${ALERT_EMAIL}'
                            \$env:WORKSPACE       = '${WORKSPACE}'
                            \$env:BUILD_URL       = '${BUILD_URL}'
                            \$env:JOB_NAME        = '${JOB_NAME}'
                            \$env:BUILD_NUMBER    = '${BUILD_NUMBER}'
                            .\\log_analyzer.ps1
                        """
                    }
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                script {
                    if (isUnix()) {
                        sh 'docker ps | grep ${CONTAINER_NAME}'
                        sh 'docker logs ${CONTAINER_NAME} --tail=20'
                        sh 'ls -lh ${WORKSPACE}/reports/ || echo "No reports directory found"'
                    } else {
                        powershell 'docker ps | Select-String "${env:CONTAINER_NAME}"'
                        powershell 'docker logs ${env:CONTAINER_NAME} --tail 20'
                        powershell 'Get-ChildItem "${env:WORKSPACE}\\reports" -ErrorAction SilentlyContinue | Format-List'
                    }
                }
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
                    <p>✅ Health check passed. Log analysis passed. Deployment is live.</p>
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
                    <p>🔴 Pipeline failed. Automatic rollback triggered.</p>
                    <p>Fix errors and re-trigger the pipeline.</p>
                    <p>See attached stats report for full details.</p>
                """,
                to: "${ALERT_EMAIL}",
                mimeType: 'text/html',
                attachmentsPattern: '**/reports/log_stats_*.txt'
            )
        }

        always {
            script {
                if (isUnix()) {
                    sh 'docker image prune -f'
                } else {
                    powershell 'docker image prune -f'
                }
            }
        }
    }
}
```

> **Cross-Platform Support** — The pipeline uses `isUnix()` to automatically detect the Jenkins agent OS at runtime.
> ```
> Linux / Mac agent  →  isUnix() = true  →  runs log_analyzer.sh
> Windows agent      →  isUnix() = false →  runs log_analyzer.ps1
> ```

---

## 💡 CI vs CD — Why Separated?

| | GitHub Actions (CI) | Jenkins (CD) |
|---|---|---|
| **Trigger** | Every git push | After image pushed to Hub |
| **Responsibility** | Build, test, quality, security, push | Clone, pull, deploy, health check, analyze, verify |
| **Runs on** | GitHub cloud runners | Local/self-hosted server |
| **Output** | Verified Docker image on Docker Hub | Running container + email alert |

> Separating CI and CD is a real-world best practice — deploy only what has been built, tested, and verified.

---

## 🏭 Production-Grade CI/CD Pipeline

---

### 🔵 Production CI — Continuous Integration
```
Code Push
    ↓
Build & Compile
    ↓
Unit Tests          → JUnit ✅ (implemented)
    ↓
Code Coverage       → JaCoCo ✅ (implemented)
    ↓
Code Quality        → SonarCloud ✅ (implemented)
    ↓
Security Scan       → Trivy ✅ (implemented)
    ↓
Integration Tests   → Test API contracts, DB connections
    ↓
Performance Tests   → JMeter, Gatling (load testing)
    ↓
Build Versioned Image → harshad8782/devops-demo:v1.42.0 ✅ (implemented)
    ↓
Push to Registry    → Docker Hub ✅ (implemented)
    ↓
Release Candidate Ready ✅
```

---

### 🟠 Production CD — Continuous Delivery with Canary Deployment
```
Release Candidate approved by CI
    ↓
Deploy to Staging
    ↓
Health Check ✅ (implemented)
    ↓
Canary Release — 5% of users
    ↓
Monitor for 15–30 minutes
    ├── OK  ──→ Roll out to 25% → 50% → 100% ✅
    └── ERR ──→ 🔴 Auto Rollback ✅ (implemented)
```

---

### 🔁 Deployment Strategies Compared

| Strategy | How it works | Risk | Use Case |
|---|---|---|---|
| **Recreate** | Stop old, start new | High — downtime | Dev/test environments |
| **Rolling** | Replace instances one by one | Medium | Standard production |
| **Blue/Green** | Run two identical envs, switch traffic | Low — instant rollback | High availability apps |
| **Canary** | Release to small % first, then scale | Very Low | Large user base, critical apps |
| **Feature Flags** | Code ships but feature toggled on/off per user | Minimal | A/B testing, gradual feature launches |

---

### 🔴 Rollback Strategy
```bash
docker stop devops-app
docker rm devops-app
docker run -d \
    --name devops-app \
    -p 8080:8080 \
    harshad8782/devops-demo:v1.41.0
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
━━━━━━━━━━━━━━━━━━━━━━━━━━  CI — GitHub Actions  ━━━━━━━━━━━━━━━━━━━━━━━━━━
    Build → Unit Tests (JUnit) ✅
        ↓
    Code Coverage (JaCoCo) ✅
        ↓
    Code Quality Gate (SonarCloud) ──FAIL──→ ❌ Block
        ↓
    Security Scan (Trivy) ✅
        ↓
    Build versioned image → v1.42.0 ✅
        ↓
    Push to Docker Hub ✅
        ↓
━━━━━━━━━━━━━━━━━━━━━━━━━━  CD — Jenkins  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    Clone → Pull versioned image
        ↓
    Deploy with Auto Rollback ✅
        ↓
    Health Check (retry 5x) ✅ ──FAIL──→ 🔴 Auto Rollback
        ↓
    Log Analysis (Bash/PowerShell) ✅ ──FAIL──→ 🔴 Block + Email
        ↓
    Verify Deployment ✅
        ↓
    Email + Stats Report ✅
        ↓
    ✅ Deployment complete
```

---

## 🔮 Future Enhancements

- [x] Jenkins CI/CD pipeline integration ✅
- [x] Unit testing with JUnit ✅
- [x] Code coverage with JaCoCo ✅
- [x] Code quality gate with SonarCloud ✅
- [x] Security scanning with Trivy ✅
- [x] Versioned Docker image tags ✅
- [x] Multi-stage Dockerfile (56% smaller image) ✅
- [x] Auto rollback on deployment failure ✅
- [x] Health check after deployment ✅
- [x] Automated log analysis — Bash + PowerShell ✅
- [x] Stats report auto-generated and attached to email ✅
- [ ] Deploy to AWS EC2 via GitHub Actions SSH
- [ ] Canary deployment strategy
- [ ] Monitoring with Prometheus + Grafana
- [ ] Kubernetes deployment with Helm charts
- [ ] Infrastructure as Code with Terraform

---

## 🧪 Running Locally
```bash
git clone https://github.com/harshad8782/DevOps-CICD.git
cd DevOps-CICD
mvn clean package
docker build -t devopsdemo .
docker run -p 8081:8080 devopsdemo
```

Open in browser: `http://localhost:8081`

---

## 📋 Useful Docker Commands
```bash
docker ps                                        # running containers
docker images                                    # list images
docker stop <container_id>                       # stop container
docker rm <container_id>                         # remove container
docker pull harshad8782/devops-demo:latest       # pull from Hub
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