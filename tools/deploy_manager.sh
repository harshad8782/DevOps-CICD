#!/bin/bash
# ============================================================
# deploy_manager.sh — Internal DevOps Automation Tool
#
# USE CASE:
#   Internal tool for DevOps team to manage deployments,
#   rollbacks, health checks, and system integration
#   across multiple environments without manual steps.
#
# Usage:
#   ./deploy_manager.sh deploy   <version>  <environment>
#   ./deploy_manager.sh rollback <version>  <environment>
#   ./deploy_manager.sh status   <environment>
#   ./deploy_manager.sh health   <environment>
#   ./deploy_manager.sh logs     <environment> <lines>
# ============================================================

set -uo pipefail

IMAGE="harshad8782/devops-demo"
CONTAINER="devops-app"
ALERT_EMAIL="${ALERT_EMAIL:-harshadraurale29@gmail.com}"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$1] $2"
}

# ─────────────────────────────────────────
# DEPLOY
# ─────────────────────────────────────────

deploy() {
    local version="${1:-latest}"
    local env="${2:-production}"

    log "INFO" "Starting deployment of $IMAGE:$version to $env"

    # Pull latest image
    log "INFO" "Pulling image $IMAGE:$version"
    docker pull "$IMAGE:$version"

    # Save current version for rollback
    local current
    current=$(docker inspect $CONTAINER --format='{{.Config.Image}}' 2>/dev/null || echo "none")
    log "INFO" "Current version: $current"

    # Deploy
    docker stop $CONTAINER 2>/dev/null || true
    docker rm $CONTAINER 2>/dev/null || true
    docker run -d \
        --name $CONTAINER \
        -p 8080:8080 \
        --restart unless-stopped \
        --label "version=$version" \
        --label "environment=$env" \
        --label "deployed=$(date '+%Y-%m-%d %H:%M:%S')" \
        "$IMAGE:$version"

    log "INFO" "Container started. Running health check..."
    sleep 5
    health "$env"
}

# ─────────────────────────────────────────
# ROLLBACK
# ─────────────────────────────────────────

rollback() {
    local version="${1:-latest}"
    local env="${2:-production}"

    log "WARN" "Rolling back to $IMAGE:$version in $env"

    docker stop $CONTAINER 2>/dev/null || true
    docker rm $CONTAINER 2>/dev/null || true
    docker run -d \
        --name $CONTAINER \
        -p 8080:8080 \
        --restart unless-stopped \
        "$IMAGE:$version"

    log "INFO" "Rollback complete. Verifying..."
    sleep 5
    health "$env"
}

# ─────────────────────────────────────────
# HEALTH CHECK
# ─────────────────────────────────────────

health() {
    local env="${1:-production}"
    local max_retries=5
    local count=0
    local healthy=false

    # Get container IP
    local ip
    ip=$(docker inspect $CONTAINER --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 2>/dev/null)

    while [ $count -lt $max_retries ] && [ "$healthy" = false ]; do
        if curl -sf "http://$ip:8080" > /dev/null 2>&1; then
            healthy=true
            log "INFO" "✅ Health check PASSED — App is healthy at http://$ip:8080"
        else
            count=$((count + 1))
            log "WARN" "Health check attempt $count/$max_retries failed. Retrying in 5s..."
            sleep 5
        fi
    done

    if [ "$healthy" = false ]; then
        log "ERROR" "❌ Health check FAILED after $max_retries attempts"
        exit 1
    fi
}

# ─────────────────────────────────────────
# STATUS
# ─────────────────────────────────────────

status() {
    local env="${1:-production}"
    log "INFO" "Checking status in $env"

    echo ""
    echo "════════════════════════════════════════"
    echo "  Container Status"
    echo "════════════════════════════════════════"
    docker ps --filter name=$CONTAINER --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"

    echo ""
    echo "════════════════════════════════════════"
    echo "  Available Images"
    echo "════════════════════════════════════════"
    docker images "$IMAGE" --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"
}

# ─────────────────────────────────────────
# LOGS
# ─────────────────────────────────────────

logs() {
    local env="${1:-production}"
    local lines="${2:-50}"
    log "INFO" "Fetching last $lines lines from $env"
    docker logs $CONTAINER --tail "$lines" 2>&1
}

# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────

case "${1:-help}" in
    deploy)   deploy   "${2:-latest}" "${3:-production}" ;;
    rollback) rollback "${2:-latest}" "${3:-production}" ;;
    health)   health   "${2:-production}" ;;
    status)   status   "${2:-production}" ;;
    logs)     logs     "${2:-production}" "${3:-50}" ;;
    *)
        echo ""
        echo "DevOps Deploy Manager — Internal Automation Tool"
        echo "================================================="
        echo ""
        echo "Usage:"
        echo "  ./deploy_manager.sh deploy   <version> <env>   Deploy a version"
        echo "  ./deploy_manager.sh rollback <version> <env>   Rollback to version"
        echo "  ./deploy_manager.sh health   <env>             Run health check"
        echo "  ./deploy_manager.sh status   <env>             Show container status"
        echo "  ./deploy_manager.sh logs     <env> <lines>     View container logs"
        echo ""
        echo "Examples:"
        echo "  ./deploy_manager.sh deploy   v1.42.0 production"
        echo "  ./deploy_manager.sh rollback v1.41.0 production"
        echo "  ./deploy_manager.sh health   production"
        echo "  ./deploy_manager.sh status   production"
        echo "  ./deploy_manager.sh logs     production 100"
        echo ""
        ;;
esac