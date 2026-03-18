#!/bin/bash
# ============================================================
# log_analyzer.sh — DevOps-Integrated Log Analysis
#
# USE CASE:
#   Runs as a Jenkins pipeline stage after application
#   deployment. Analyzes Docker container logs, fails the
#   pipeline if critical errors are found (blocking bad
#   deployments), creates GitHub issues for warnings, and
#   sends email notifications to the DevOps team.
#
#   Integrated with:
#     - Jenkins  : exit codes control pipeline pass/fail
#     - Docker   : pulls logs directly from running container
#     - GitHub   : auto-creates issues for error threshold breaches
#     - Email    : real-time alert notification via sendmail/mail
#
# Usage (standalone):
#   ./log_analyzer.sh
#
# Usage (Jenkins pipeline stage):
#   sh './log_analyzer.sh'
#
# Exit Codes:
#   0 = clean, no issues found     → Jenkins: SUCCESS
#   1 = script/config error        → Jenkins: FAILURE
#   2 = warnings found             → Jenkins: UNSTABLE
#   3 = critical errors found      → Jenkins: FAILURE (blocks deploy)
# ============================================================

set -uo pipefail

# ─────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────

CONTAINER_NAME="${CONTAINER_NAME:-devops-app}"

REPORT_DIR="${REPORT_DIR:-/var/reports}"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="$REPORT_DIR/log_report_${CONTAINER_NAME}_${TIMESTAMP}.txt"
SCRIPT_LOG="$REPORT_DIR/analyzer_${TIMESTAMP}.log"

ERROR_PATTERNS=("ERROR" "FATAL" "CRITICAL" "EXCEPTION")
WARN_PATTERNS=("WARN" "WARNING" "DEPRECATED")
CRITICAL_THRESHOLD=5
WARN_THRESHOLD=10
LOG_LINES=500

BUILD_URL="${BUILD_URL:-local}"
JOB_NAME="${JOB_NAME:-local}"
BUILD_NUMBER="${BUILD_NUMBER:-0}"

ALERT_EMAIL="${ALERT_EMAIL:-devops@company.com}"
FROM_EMAIL="${FROM_EMAIL:-jenkins@company.com}"

GITHUB_TOKEN="${GITHUB_TOKEN:-}"
GITHUB_REPO="${GITHUB_REPO:-harshad8782/DevOps-CICD}"

# ─────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$SCRIPT_LOG"
}

# ─────────────────────────────────────────
# STEP 1 — VALIDATE ENVIRONMENT
# ─────────────────────────────────────────

validate() {
    log "Validating environment..."

    if ! command -v docker &> /dev/null; then
        log "ERROR: Docker not found. Is this running on the Jenkins agent?"
        exit 1
    fi

    if ! command -v mail &> /dev/null; then
        log "WARNING: 'mail' command not found — email alerts will be skipped"
    fi

    if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        log "ERROR: Container '$CONTAINER_NAME' is not running"
        log "Running containers: $(docker ps --format '{{.Names}}' | tr '\n' ' ')"
        exit 1
    fi

    mkdir -p "$REPORT_DIR" || {
        log "ERROR: Cannot create report directory"
        exit 1
    }

    log "Validation passed. Container '$CONTAINER_NAME' is running."
}

# ─────────────────────────────────────────
# STEP 2 — PULL LOGS FROM DOCKER CONTAINER
# ─────────────────────────────────────────

fetch_container_logs() {
    log "Fetching last $LOG_LINES lines from container: $CONTAINER_NAME"

    TEMP_LOG=$(mktemp /tmp/container_log_XXXX.log)
    docker logs "$CONTAINER_NAME" --tail "$LOG_LINES" > "$TEMP_LOG" 2>&1

    local line_count
    line_count=$(wc -l < "$TEMP_LOG")
    log "Fetched $line_count log lines from container"

    echo "$TEMP_LOG"
}

# ─────────────────────────────────────────
# STEP 3 — ANALYZE LOGS
# ─────────────────────────────────────────

analyze_logs() {
    local log_file="$1"
    local critical_found=0
    local warn_found=0
    local total_issues=0

    write_report_header

    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  CRITICAL ERROR ANALYSIS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    } >> "$REPORT_FILE"

    for pattern in "${ERROR_PATTERNS[@]}"; do
        local count
        count=$(grep -i -c "$pattern" "$log_file" 2>/dev/null || echo 0)
        total_issues=$((total_issues + count))

        {
            echo ""
            echo "  Pattern : $pattern | Count : $count | Threshold : $CRITICAL_THRESHOLD"
        } >> "$REPORT_FILE"

        if [ "$count" -gt 0 ]; then
            echo "  Recent occurrences:" >> "$REPORT_FILE"
            grep -i "$pattern" "$log_file" | tail -5 | sed 's/^/    → /' >> "$REPORT_FILE"
        fi

        if [ "$count" -gt "$CRITICAL_THRESHOLD" ]; then
            critical_found=$((critical_found + 1))
            echo "  🔴 CRITICAL THRESHOLD EXCEEDED — pipeline will be blocked" >> "$REPORT_FILE"
            log "CRITICAL: '$pattern' count ($count) exceeds threshold ($CRITICAL_THRESHOLD)"
        fi
    done

    {
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "  WARNING ANALYSIS"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    } >> "$REPORT_FILE"

    for pattern in "${WARN_PATTERNS[@]}"; do
        local count
        count=$(grep -i -c "$pattern" "$log_file" 2>/dev/null || echo 0)

        {
            echo ""
            echo "  Pattern : $pattern | Count : $count | Threshold : $WARN_THRESHOLD"
        } >> "$REPORT_FILE"

        if [ "$count" -gt "$WARN_THRESHOLD" ]; then
            warn_found=$((warn_found + 1))
            echo "  🟡 WARNING THRESHOLD EXCEEDED — pipeline marked unstable" >> "$REPORT_FILE"
            log "WARNING: '$pattern' count ($count) exceeds threshold ($WARN_THRESHOLD)"
        fi
    done

    echo "$critical_found $warn_found $total_issues"
}

# ─────────────────────────────────────────
# STEP 4 — SEND EMAIL NOTIFICATION
# ─────────────────────────────────────────

send_email() {
    local subject="$1"
    local status="$2"
    local critical="$3"
    local warnings="$4"
    local total="$5"

    if ! command -v mail &> /dev/null; then
        log "Skipping email — 'mail' command not available"
        return 0
    fi

    local body
    body=$(cat << EOF
====================================================
  DEVOPS LOG ANALYSIS ALERT
====================================================

Status          : $status
Container       : $CONTAINER_NAME
Jenkins Job     : $JOB_NAME
Build Number    : #$BUILD_NUMBER
Build URL       : $BUILD_URL

----------------------------------------------------
  ANALYSIS SUMMARY
----------------------------------------------------
Critical Issues : $critical pattern(s) exceeded threshold ($CRITICAL_THRESHOLD)
Warnings        : $warnings pattern(s) exceeded threshold ($WARN_THRESHOLD)
Total Issues    : $total

----------------------------------------------------
  PIPELINE DECISION
----------------------------------------------------
$(decision_text "$status")

----------------------------------------------------
  REPORT LOCATION
----------------------------------------------------
Full report saved at : $REPORT_FILE
Analyzer log at      : $SCRIPT_LOG

----------------------------------------------------
  NEXT STEPS
----------------------------------------------------
$(next_steps "$status")

====================================================
Generated : $(date '+%Y-%m-%d %H:%M:%S')
Server    : $(hostname)
This is an automated alert from Jenkins CI/CD Pipeline
====================================================
EOF
)

    echo "$body" | mail \
        -s "$subject" \
        -a "From: Jenkins CI/CD <$FROM_EMAIL>" \
        -A "$REPORT_FILE" \
        "$ALERT_EMAIL"

    log "Email alert sent to $ALERT_EMAIL | Subject: $subject"
}

decision_text() {
    case "$1" in
        "PASSED")   echo "✅ All checks passed. Deployment is proceeding to production." ;;
        "UNSTABLE") echo "🟡 Warnings found. Deployment allowed but review is required." ;;
        "FAILED")   echo "🔴 Critical errors found. Deployment has been BLOCKED." ;;
    esac
}

next_steps() {
    case "$1" in
        "PASSED")
            echo "No action required. Monitor production for any anomalies."
            ;;
        "UNSTABLE")
            echo "1. Review warning patterns in the attached report
2. Investigate root cause before next deployment
3. Consider adding fixes in next sprint"
            ;;
        "FAILED")
            echo "1. Open the attached report and review critical errors
2. Check GitHub — an issue has been auto-created
3. Fix the errors and re-trigger the Jenkins pipeline
4. Do NOT manually deploy — pipeline is blocked for safety"
            ;;
    esac
}

# ─────────────────────────────────────────
# STEP 5 — CREATE GITHUB ISSUE
# ─────────────────────────────────────────

create_github_issue() {
    local title="$1"
    local body="$2"

    [ -z "$GITHUB_TOKEN" ] && {
        log "GITHUB_TOKEN not set — skipping GitHub issue creation"
        return 0
    }

    local response
    response=$(curl -s -X POST \
        -H "Authorization: token $GITHUB_TOKEN" \
        -H "Accept: application/vnd.github.v3+json" \
        "https://api.github.com/repos/${GITHUB_REPO}/issues" \
        -d "{
            \"title\": \"$title\",
            \"body\": \"$body\",
            \"labels\": [\"bug\", \"devops\", \"auto-generated\"]
        }")

    local issue_url
    issue_url=$(echo "$response" | grep -o '"html_url":"[^"]*"' | head -1 | cut -d'"' -f4)
    log "GitHub issue created: $issue_url"
}

# ─────────────────────────────────────────
# REPORT HELPERS
# ─────────────────────────────────────────

write_report_header() {
    cat >> "$REPORT_FILE" << EOF
╔══════════════════════════════════════════════════════════╗
║         DEVOPS LOG ANALYSIS REPORT                      ║
╠══════════════════════════════════════════════════════════╣
  Timestamp   : $(date '+%Y-%m-%d %H:%M:%S')
  Container   : $CONTAINER_NAME
  Jenkins Job : $JOB_NAME #$BUILD_NUMBER
  Build URL   : $BUILD_URL
  Analyzed    : Last $LOG_LINES log lines
  Alert Email : $ALERT_EMAIL
╚══════════════════════════════════════════════════════════╝
EOF
}

write_summary() {
    local status="$1"
    local critical="$2"
    local warnings="$3"
    local total="$4"

    cat >> "$REPORT_FILE" << EOF

╔══════════════════════════════════════════════════════════╗
║                 PIPELINE DECISION                       ║
╠══════════════════════════════════════════════════════════╣
  Status          : $status
  Critical Issues : $critical pattern(s) exceeded threshold
  Warnings        : $warnings pattern(s) exceeded threshold
  Total Issues    : $total
  Action          : $(decision_text "$status")
  Email Sent To   : $ALERT_EMAIL
╚══════════════════════════════════════════════════════════╝
EOF
}

# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────

main() {
    log "============================================"
    log "  Log Analyzer — DevOps CI/CD Integration"
    log "  Container : $CONTAINER_NAME"
    log "  Job       : $JOB_NAME #$BUILD_NUMBER"
    log "  Alerting  : $ALERT_EMAIL"
    log "============================================"

    validate

    TEMP_LOG=$(fetch_container_logs)

    read -r critical_count warn_count total_issues <<< "$(analyze_logs "$TEMP_LOG")"

    rm -f "$TEMP_LOG"

    if [ "$critical_count" -gt 0 ]; then
        STATUS="FAILED"
        write_summary "$STATUS" "$critical_count" "$warn_count" "$total_issues"

        send_email \
            "🔴 [CRITICAL] Deployment BLOCKED — $JOB_NAME #$BUILD_NUMBER" \
            "$STATUS" "$critical_count" "$warn_count" "$total_issues"

        create_github_issue \
            "🔴 Critical log errors in $CONTAINER_NAME — Build #$BUILD_NUMBER" \
            "**Log analysis failed** for container \`$CONTAINER_NAME\` in Jenkins job \`$JOB_NAME\` build #$BUILD_NUMBER.\n\n**Critical patterns exceeded threshold:** $critical_count\n**Total issues found:** $total_issues\n\n**Build URL:** $BUILD_URL\n\n**Alert sent to:** $ALERT_EMAIL\n\n*This issue was auto-generated by log_analyzer.sh*"

        log "Result: FAILED — $critical_count critical issue(s). Deployment blocked."
        exit 3

    elif [ "$warn_count" -gt 0 ]; then
        STATUS="UNSTABLE"
        write_summary "$STATUS" "$critical_count" "$warn_count" "$total_issues"

        send_email \
            "🟡 [WARNING] Deployment Unstable — $JOB_NAME #$BUILD_NUMBER" \
            "$STATUS" "$critical_count" "$warn_count" "$total_issues"

        log "Result: UNSTABLE — $warn_count warning(s). Deployment allowed."
        exit 2

    else
        STATUS="PASSED"
        write_summary "$STATUS" "0" "0" "$total_issues"

        send_email \
            "✅ [SUCCESS] Deployment Clean — $JOB_NAME #$BUILD_NUMBER" \
            "$STATUS" "0" "0" "$total_issues"

        log "Result: PASSED — No issues found. Deployment proceeding."
        exit 0
    fi
}

main "$@"