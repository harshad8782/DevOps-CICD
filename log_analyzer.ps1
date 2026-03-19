# ============================================================
# log_analyzer.ps1 — DevOps-Integrated Log Analysis
#
# USE CASE:
#   Runs as a Jenkins pipeline stage after application
#   deployment. Analyzes Docker container logs, fails the
#   pipeline if critical errors are found (blocking bad
#   deployments), creates GitHub issues for warnings, and
#   sends email with attached stats report to the DevOps team.
#
#   Integrated with:
#     - Jenkins  : exit codes control pipeline pass/fail
#     - Docker   : pulls logs directly from running container
#     - GitHub   : auto-creates issues for error threshold breaches
#     - Email    : sends HTML email with .txt stats report attached
#
# Exit Codes:
#   0 = clean        → Jenkins: SUCCESS
#   1 = config error → Jenkins: FAILURE
#   2 = warnings     → Jenkins: UNSTABLE
#   3 = critical     → Jenkins: FAILURE (blocks deploy)
# ============================================================

# ─────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────

$CONTAINER_NAME  = if ($env:CONTAINER_NAME)  { $env:CONTAINER_NAME }  else { "devops-app" }
$ALERT_EMAIL     = if ($env:ALERT_EMAIL)     { $env:ALERT_EMAIL }     else { "devops@company.com" }
$GITHUB_TOKEN    = if ($env:GITHUB_TOKEN)    { $env:GITHUB_TOKEN }    else { "" }
$GITHUB_REPO     = if ($env:GITHUB_REPO)     { $env:GITHUB_REPO }     else { "harshad8782/DevOps-CICD" }
$BUILD_URL       = if ($env:BUILD_URL)       { $env:BUILD_URL }       else { "local" }
$JOB_NAME        = if ($env:JOB_NAME)        { $env:JOB_NAME }        else { "local" }
$BUILD_NUMBER    = if ($env:BUILD_NUMBER)    { $env:BUILD_NUMBER }    else { "0" }
$WORKSPACE       = if ($env:WORKSPACE)       { $env:WORKSPACE }       else { $PSScriptRoot }

$TIMESTAMP       = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$REPORT_DIR      = "$WORKSPACE\reports"
$STATS_FILE      = "$REPORT_DIR\log_stats_${CONTAINER_NAME}_${TIMESTAMP}.txt"

$ERROR_PATTERNS  = @("ERROR", "FATAL", "CRITICAL", "EXCEPTION")
$WARN_PATTERNS   = @("WARN", "WARNING", "DEPRECATED")
$CRITICAL_THRESHOLD = 5
$WARN_THRESHOLD     = 10
$LOG_LINES          = 500

# SMTP Configuration
$SMTP_SERVER     = "smtp.gmail.com"
$SMTP_PORT       = 587
$SMTP_USER       = $ALERT_EMAIL
$SMTP_PASS       = if ($env:SMTP_PASS) { $env:SMTP_PASS } else { "" }

# ─────────────────────────────────────────
# LOGGING
# ─────────────────────────────────────────

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message"
}

# ─────────────────────────────────────────
# STEP 1 — VALIDATE
# ─────────────────────────────────────────

function Invoke-Validate {
    Write-Log "Validating environment..."
    Write-Log "REPORT_DIR  : $REPORT_DIR"
    Write-Log "STATS_FILE  : $STATS_FILE"
    Write-Log "WORKSPACE   : $WORKSPACE"

    # Check Docker is available
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Log "ERROR: Docker not found"
        exit 1
    }

    # Check container is running
    $running = docker ps --format "{{.Names}}" | Where-Object { $_ -eq $CONTAINER_NAME }
    if (-not $running) {
        Write-Log "ERROR: Container '$CONTAINER_NAME' is not running"
        $allContainers = docker ps --format "{{.Names}}" | Out-String
        Write-Log "Running containers: $allContainers"
        exit 1
    }

    # Create report directory
    if (-not (Test-Path $REPORT_DIR)) {
        New-Item -ItemType Directory -Path $REPORT_DIR -Force | Out-Null
        Write-Log "Report directory created: $REPORT_DIR"
    }

    Write-Log "Validation passed. Container '$CONTAINER_NAME' is running."
}

# ─────────────────────────────────────────
# STEP 2 — FETCH DOCKER LOGS
# ─────────────────────────────────────────

function Get-ContainerLogs {
    Write-Log "Fetching last $LOG_LINES lines from container: $CONTAINER_NAME"

    $tempLog = [System.IO.Path]::GetTempFileName()
    docker logs $CONTAINER_NAME --tail $LOG_LINES 2>&1 | Out-File -FilePath $tempLog -Encoding UTF8

    $lineCount = (Get-Content $tempLog).Count
    Write-Log "Fetched $lineCount log lines"

    return $tempLog
}

# ─────────────────────────────────────────
# STEP 3 — ANALYZE + WRITE STATS FILE
# ─────────────────────────────────────────

function Invoke-AnalyzeLogs {
    param([string]$LogFile)

    $criticalFound = 0
    $warnFound     = 0
    $totalIssues   = 0

    $logContent = Get-Content $LogFile

    Write-Log "Writing stats file: $STATS_FILE"

    # Write header
    @"
====================================================
  LOG ANALYSIS STATS REPORT
====================================================
Generated     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Container     : $CONTAINER_NAME
Jenkins Job   : $JOB_NAME
Build Number  : #$BUILD_NUMBER
Build URL     : $BUILD_URL
Lines Scanned : $LOG_LINES
Alert Email   : $ALERT_EMAIL
====================================================

--------------------------------------------------
  CRITICAL ERROR PATTERNS  (threshold: $CRITICAL_THRESHOLD)
--------------------------------------------------
"@ | Out-File -FilePath $STATS_FILE -Encoding UTF8

    # Analyze critical patterns
    foreach ($pattern in $ERROR_PATTERNS) {
        $matches = $logContent | Select-String -Pattern $pattern -AllMatches
        $count   = if ($matches) { $matches.Count } else { 0 }
        $totalIssues += $count

        "  $pattern : $count occurrences" | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8

        if ($count -gt 0) {
            "  Last 3 occurrences:" | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8
            $matches | Select-Object -Last 3 | ForEach-Object {
                "    -> $($_.Line)" | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8
            }
        }

        if ($count -gt $CRITICAL_THRESHOLD) {
            $criticalFound++
            "  !! THRESHOLD EXCEEDED — pipeline will be blocked" | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8
            Write-Log "CRITICAL: '$pattern' count ($count) exceeds threshold ($CRITICAL_THRESHOLD)"
        }

        "" | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8
    }

    # Warning section header
    @"
--------------------------------------------------
  WARNING PATTERNS  (threshold: $WARN_THRESHOLD)
--------------------------------------------------
"@ | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8

    # Analyze warning patterns
    foreach ($pattern in $WARN_PATTERNS) {
        $matches = $logContent | Select-String -Pattern $pattern -AllMatches
        $count   = if ($matches) { $matches.Count } else { 0 }

        "  $pattern : $count occurrences" | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8

        if ($count -gt $WARN_THRESHOLD) {
            $warnFound++
            "  !! THRESHOLD EXCEEDED — pipeline marked unstable" | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8
            Write-Log "WARNING: '$pattern' count ($count) exceeds threshold ($WARN_THRESHOLD)"
        }

        "" | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8
    }

    Write-Log "Stats file written: $STATS_FILE"
    Get-Item $STATS_FILE | Select-Object Name, Length

    return @{
        Critical = $criticalFound
        Warnings = $warnFound
        Total    = $totalIssues
    }
}

# ─────────────────────────────────────────
# STEP 4 — WRITE SUMMARY TO STATS FILE
# ─────────────────────────────────────────

function Write-Summary {
    param(
        [string]$Status,
        [int]$Critical,
        [int]$Warnings,
        [int]$Total
    )

    @"

====================================================
  PIPELINE DECISION SUMMARY
====================================================
Status          : $Status
Critical Issues : $Critical pattern(s) exceeded threshold
Warnings        : $Warnings pattern(s) exceeded threshold
Total Issues    : $Total

Action          : $(Get-DecisionText $Status)

Next Steps      :
$(Get-NextSteps $Status)
====================================================
"@ | Out-File -FilePath $STATS_FILE -Append -Encoding UTF8

    Write-Log "Summary written to stats file"
    Write-Log "Final stats file: $STATS_FILE"
}

function Get-DecisionText {
    param([string]$Status)
    switch ($Status) {
        "PASSED"   { return "All checks passed. Deployment is proceeding." }
        "UNSTABLE" { return "Warnings found. Deployment allowed but review required." }
        "FAILED"   { return "Critical errors found. Deployment has been BLOCKED." }
    }
}

function Get-NextSteps {
    param([string]$Status)
    switch ($Status) {
        "PASSED" {
            return "  No action required. Monitor production for anomalies."
        }
        "UNSTABLE" {
            return "  1. Review warning patterns in the attached stats report
  2. Investigate root cause before next deployment
  3. Consider adding fixes in next sprint"
        }
        "FAILED" {
            return "  1. Review critical errors in the attached stats report
  2. Check GitHub — an issue has been auto-created
  3. Fix the errors and re-trigger the Jenkins pipeline
  4. Do NOT manually deploy — pipeline is blocked for safety"
        }
    }
}

# ─────────────────────────────────────────
# STEP 5 — SEND EMAIL WITH ATTACHMENT
# ─────────────────────────────────────────

function Send-AlertEmail {
    param(
        [string]$Subject,
        [string]$Status,
        [int]$Critical,
        [int]$Warnings,
        [int]$Total
    )

    if (-not $SMTP_PASS) {
        Write-Log "SMTP_PASS not set — skipping email"
        return
    }

    $body = @"
<h2>$Subject</h2>
<table border="1" cellpadding="5">
    <tr><td><b>Job</b></td><td>$JOB_NAME</td></tr>
    <tr><td><b>Build</b></td><td>#$BUILD_NUMBER</td></tr>
    <tr><td><b>Container</b></td><td>$CONTAINER_NAME</td></tr>
    <tr><td><b>Build URL</b></td><td><a href='$BUILD_URL'>$BUILD_URL</a></td></tr>
    <tr><td><b>Status</b></td><td>$Status</td></tr>
    <tr><td><b>Critical Issues</b></td><td>$Critical pattern(s) exceeded threshold</td></tr>
    <tr><td><b>Warnings</b></td><td>$Warnings pattern(s) exceeded threshold</td></tr>
    <tr><td><b>Total Issues</b></td><td>$Total</td></tr>
</table>
<p>$(Get-DecisionText $Status)</p>
<p>See attached stats report for full analysis details.</p>
"@

    try {
        $securePass  = ConvertTo-SecureString $SMTP_PASS -AsPlainText -Force
        $credentials = New-Object System.Management.Automation.PSCredential($SMTP_USER, $securePass)

        Send-MailMessage `
            -To         $ALERT_EMAIL `
            -From       $SMTP_USER `
            -Subject    $Subject `
            -Body       $body `
            -BodyAsHtml `
            -SmtpServer $SMTP_SERVER `
            -Port       $SMTP_PORT `
            -UseSsl `
            -Credential $credentials `
            -Attachments $STATS_FILE

        Write-Log "Email sent to $ALERT_EMAIL | Subject: $Subject"
    }
    catch {
        Write-Log "ERROR sending email: $_"
    }
}

# ─────────────────────────────────────────
# STEP 6 — CREATE GITHUB ISSUE
# ─────────────────────────────────────────

function New-GitHubIssue {
    param(
        [string]$Title,
        [string]$Body
    )

    if (-not $GITHUB_TOKEN) {
        Write-Log "GITHUB_TOKEN not set — skipping GitHub issue creation"
        return
    }

    $headers = @{
        "Authorization" = "token $GITHUB_TOKEN"
        "Accept"        = "application/vnd.github.v3+json"
        "Content-Type"  = "application/json"
    }

    $payload = @{
        title  = $Title
        body   = $Body
        labels = @("bug", "devops", "auto-generated")
    } | ConvertTo-Json

    try {
        $response = Invoke-RestMethod `
            -Uri     "https://api.github.com/repos/$GITHUB_REPO/issues" `
            -Method  POST `
            -Headers $headers `
            -Body    $payload

        Write-Log "GitHub issue created: $($response.html_url)"
    }
    catch {
        Write-Log "ERROR creating GitHub issue: $_"
    }
}

# ─────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────

Write-Log "============================================"
Write-Log "  Log Analyzer — DevOps CI/CD Integration"
Write-Log "  Container : $CONTAINER_NAME"
Write-Log "  Job       : $JOB_NAME #$BUILD_NUMBER"
Write-Log "  Alerting  : $ALERT_EMAIL"
Write-Log "  WORKSPACE : $WORKSPACE"
Write-Log "============================================"

Invoke-Validate

$tempLog = Get-ContainerLogs

$result  = Invoke-AnalyzeLogs -LogFile $tempLog

Remove-Item $tempLog -Force -ErrorAction SilentlyContinue

$criticalCount = $result.Critical
$warnCount     = $result.Warnings
$totalIssues   = $result.Total

if ($criticalCount -gt 0) {

    $STATUS = "FAILED"
    Write-Summary -Status $STATUS -Critical $criticalCount -Warnings $warnCount -Total $totalIssues

    Send-AlertEmail `
        -Subject  "CRITICAL: Deployment BLOCKED — $JOB_NAME #$BUILD_NUMBER" `
        -Status   $STATUS `
        -Critical $criticalCount `
        -Warnings $warnCount `
        -Total    $totalIssues

    New-GitHubIssue `
        -Title "Critical log errors in $CONTAINER_NAME — Build #$BUILD_NUMBER" `
        -Body  "Log analysis failed for container ``$CONTAINER_NAME`` in Jenkins job ``$JOB_NAME`` build #$BUILD_NUMBER.`n`nCritical patterns exceeded threshold: $criticalCount`nTotal issues: $totalIssues`n`nBuild URL: $BUILD_URL`n`n*Auto-generated by log_analyzer.ps1*"

    Write-Log "Result: FAILED — $criticalCount critical issue(s). Deployment blocked."
    exit 3

} elseif ($warnCount -gt 0) {

    $STATUS = "UNSTABLE"
    Write-Summary -Status $STATUS -Critical $criticalCount -Warnings $warnCount -Total $totalIssues

    Send-AlertEmail `
        -Subject  "WARNING: Pipeline Unstable — $JOB_NAME #$BUILD_NUMBER" `
        -Status   $STATUS `
        -Critical $criticalCount `
        -Warnings $warnCount `
        -Total    $totalIssues

    Write-Log "Result: UNSTABLE — $warnCount warning(s). Deployment allowed."
    exit 2

} else {

    $STATUS = "PASSED"
    Write-Summary -Status $STATUS -Critical 0 -Warnings 0 -Total $totalIssues

    Send-AlertEmail `
        -Subject  "SUCCESS: Pipeline Passed — $JOB_NAME #$BUILD_NUMBER" `
        -Status   $STATUS `
        -Critical 0 `
        -Warnings 0 `
        -Total    $totalIssues

    Write-Log "Result: PASSED — No issues found. Deployment proceeding."
    exit 0
}