# 🚀 DevOps CI/CD Pipeline Demo

> A complete end-to-end **DevOps CI/CD pipeline** built with Spring Boot, Docker, GitHub Actions, and Jenkins — demonstrating automated build, containerization, and deployment workflows.

---

## 📌 Project Architecture
```
Developer → GitHub Push → GitHub Actions (CI) → Maven Build → Docker Image → Docker Hub
                                                                                    ↓
                                                                            Jenkins (CD)
                                                                                    ↓
                                                                       Pull Image → Run Container
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

---

## 📂 Project Structure
```
devopsdemo/
├── src/
│   └── main/
│       └── java/
├── Dockerfile
├── Jenkinsfile
├── pom.xml
├── README.md
└── .github/
    └── workflows/
        └── ci.yml
```

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

Jenkins pulls the latest verified image from Docker Hub and deploys the container automatically.

**Jenkins Pipeline Stages:**
- ✅ Pull Image from Docker Hub
- ✅ Stop & Remove Old Container
- ✅ Run New Container
- ✅ Verify Deployment

📸 **Jenkins Pipeline:**

![Jenkins Pipeline](screenshots/jenkins.png)

---

### Step 5 — Pull Image from Docker Hub
```bash
docker pull harshad8782/devops-demo:latest
```

📸 **Image Pulled Locally (Docker Desktop):**

![Pull Image](screenshots/pull_image_from_docker_hub.png)

---

### Step 6 — Run the Docker Container
```bash
docker run -p 8081:8080 harshad8782/devops-demo:latest
```

📸 **Container Running (Docker Desktop):**

![Container Running](screenshots/container_running.png)

> Container name: `devops-app` | Port: `8081:8080`

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
        DOCKER_IMAGE = 'harshad8782/devops-demo:latest'
        CONTAINER_NAME = 'devops-app'
        APP_PORT = '8081'
        CONTAINER_PORT = '8080'
    }

    stages {

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
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                sh 'sleep 5'
                sh 'docker ps | grep ${CONTAINER_NAME}'
                sh 'docker logs ${CONTAINER_NAME} --tail=20'
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline succeeded! App running at http://localhost:8081'
        }
        failure {
            echo '❌ Pipeline failed! Check logs above for errors.'
        }
        always {
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
| **Responsibility** | Build, test, package, push | Pull, deploy, verify |
| **Runs on** | GitHub cloud runners | Local/self-hosted server |
| **Output** | Docker image on Docker Hub | Running container |

> Separating CI and CD is a real-world best practice — deploy only what has been built and verified, never build directly on the deployment server.

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

## 📚 Learning Reference — Full Pipeline Using Only One Tool

> This project intentionally separates CI (GitHub Actions) and CD (Jenkins) for learning purposes — to understand the responsibility of each tool clearly. However, the entire pipeline can also be built using either tool alone. Here is how:

---

### 🔵 Full Pipeline Using GitHub Actions Only

If you want a single tool to handle everything — build, push and deploy — GitHub Actions can do it all. This approach is ideal for simplicity, cloud-hosted projects, and small teams.
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

**How it works:**
```
git push
    ↓
GitHub Actions runner spins up
    ↓
Maven build → Docker build → Push to Hub
    ↓
SSH into your server
    ↓
Pull latest image → Run container ✅
```

---

### 🟠 Full Pipeline Using Jenkins Only

If you want full control on your own server without GitHub Actions at all, Jenkins can handle every stage from cloning to deploying. This approach is ideal for enterprises, private networks, and teams needing deep customization.
```groovy
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'harshad8782/devops-demo'
        IMAGE_TAG = 'latest'
        CONTAINER_NAME = 'devops-app'
        APP_PORT = '8081'
        CONTAINER_PORT = '8080'
    }

    stages {

        stage('Clone Repository') {
            steps {
                echo '📥 Cloning from GitHub...'
                git branch: 'main',
                    url: 'https://github.com/harshad8782/DevOps-CICD.git'
            }
        }

        stage('Build Maven') {
            steps {
                echo '⚙️ Building Maven project...'
                sh 'chmod +x mvnw'
                sh './mvnw clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo '🐳 Building Docker image...'
                sh 'docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '📤 Pushing to Docker Hub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh 'echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin'
                    sh 'docker push ${DOCKER_IMAGE}:${IMAGE_TAG}'
                }
            }
        }

        stage('Deploy Container') {
            steps {
                echo '🚀 Deploying container...'
                sh 'docker stop ${CONTAINER_NAME} || true'
                sh 'docker rm ${CONTAINER_NAME} || true'
                sh '''
                    docker run -d \
                        --name ${CONTAINER_NAME} \
                        -p ${APP_PORT}:${CONTAINER_PORT} \
                        --restart unless-stopped \
                        ${DOCKER_IMAGE}:${IMAGE_TAG}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                echo '✅ Verifying deployment...'
                sh 'sleep 5'
                sh 'docker ps | grep ${CONTAINER_NAME}'
                sh 'docker logs ${CONTAINER_NAME} --tail=20'
            }
        }
    }

    post {
        success {
            echo '✅ Full pipeline succeeded! App running at http://localhost:8081'
        }
        failure {
            echo '❌ Pipeline failed! Check logs above for errors.'
        }
        always {
            sh 'docker image prune -f'
        }
    }
}
```

**How it works:**
```
git push → Jenkins webhook triggers
    ↓
Clone repo
    ↓
Maven build → Docker build
    ↓
Push to Docker Hub
    ↓
Run container locally ✅
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

## 👨‍💻 Author

**Harshad Raurale**  
DevOps / Cloud Enthusiast

[![GitHub](https://img.shields.io/badge/GitHub-harshad8782-181717?style=flat&logo=github)](https://github.com/harshad8782)

---

> ⭐ If you found this project helpful, please consider giving it a star!