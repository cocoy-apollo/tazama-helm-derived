# Add-Missing-Rules.ps1
# PowerShell script to inject 11 missing rules into values-internal.yaml
# Run from: tazama/tazama-helm-derived directory

$valuesFile = "values-internal.yaml"

# Read the file
$content = Get-Content $valuesFile -Raw

# Define the 11 missing rules
$missingRules = @"

  # Additional classification rules
  rule-044:
    name: "Account velocity monitoring"
    description: "Monitors the velocity of account activity patterns"
    enabled: true
    riskWeight: 0.55

  rule-045:
    name: "Geographic anomaly detection"
    description: "Identifies geographic anomalies in transaction patterns"
    enabled: true
    riskWeight: 0.65

  # Additional pattern detection rules
  rule-048:
    name: "Round amount transaction detection"
    description: "Detects patterns of suspiciously round transaction amounts"
    enabled: true
    riskWeight: 0.6

  rule-054:
    name: "Counterparty relationship analysis"
    description: "Analyzes counterparty relationship patterns for risk"
    enabled: true
    riskWeight: 0.7

  # Behavioral analysis rules
  rule-063:
    name: "Transaction timing analysis"
    description: "Analyzes transaction timing patterns for anomalies"
    enabled: true
    riskWeight: 0.5

  rule-074:
    name: "Historical pattern deviation - creditor"
    description: "Detects deviations from historical patterns for creditor accounts"
    enabled: true
    riskWeight: 0.6

  rule-075:
    name: "Historical pattern deviation - debtor"
    description: "Detects deviations from historical patterns for debtor accounts"
    enabled: true
    riskWeight: 0.6

  rule-076:
    name: "Cross-border transaction monitoring"
    description: "Monitors cross-border transaction patterns for risk"
    enabled: true
    riskWeight: 0.75

  rule-078:
    name: "Channel behavior analysis"
    description: "Analyzes transaction patterns across different channels"
    enabled: true
    riskWeight: 0.55

  # Advanced detection rules
  rule-083:
    name: "Network analysis - payment flows"
    description: "Performs network analysis on payment flow patterns"
    enabled: true
    riskWeight: 0.7

  rule-084:
    name: "Aggregated threshold monitoring"
    description: "Monitors aggregated amounts against configurable thresholds"
    enabled: true
    riskWeight: 0.65

  # Additional monitoring rules  
  rule-090:
    name: "Time-based clustering analysis"
    description: "Detects time-based clustering of transactions"
    enabled: true
    riskWeight: 0.6

  rule-091:
    name: "Peer group comparison"
    description: "Compares account behavior against peer group baselines"
    enabled: true
    riskWeight: 0.65

"@

# Insert the rules after rule-030
$content = $content -replace '(rule-030:.*?riskWeight: 0\.65)', "`$1$missingRules"

Write-Host "Step 1: Adding rule definitions..." -ForegroundColor Cyan

# Save the modified content
$content | Set-Content "$valuesFile.new" -Encoding UTF8

Write-Host "Created values-internal.yaml.new" -ForegroundColor Green

# Now update the typology rules list
Write-Host "`nStep 2: Updating typology rules list..." -ForegroundColor Cyan

$newRulesList = @"
    rules:
      # Account-based rules
      - rule-001
      - rule-002
      - rule-003
      - rule-004
      # Transaction similarity rules
      - rule-006
      - rule-007
      - rule-008
      # Activity pattern rules
      - rule-010
      - rule-011
      # Additional classification rules
      - rule-044
      - rule-045
      # Convergence/divergence rules
      - rule-016
      - rule-017
      # Large transaction rules
      - rule-018
      - rule-020
      - rule-021
      # Mirroring rules
      - rule-024
      - rule-025
      - rule-026
      - rule-027
      # Additional pattern detection rules
      - rule-048
      - rule-054
      # Classification rules
      - rule-028
      # Behavioral analysis rules
      - rule-063
      - rule-074
      - rule-075
      - rule-076
      - rule-078
      # Unfamiliar account rules
      - rule-030
      # Advanced detection rules
      - rule-083
      - rule-084
      - rule-090
      - rule-091
"@

# Read the new file
$content = Get-Content "$valuesFile.new" -Raw

# Find and replace the main typology rules section
# Match from "rules:" under main typology to "alertThreshold"
$pattern = '(?s)(typologies:\s+main:.*?rules:)(.*?)(\s+alertThreshold:)'
$content = $content -replace $pattern, "`$1$newRulesList`n`$3"

# Save final version
$content | Set-Content "$valuesFile.final" -Encoding UTF8

Write-Host "Created values-internal.yaml.final" -ForegroundColor Green

Write-Host "`n" + "="*70 -ForegroundColor Cyan
Write-Host "NEXT STEPS:" -ForegroundColor Yellow
Write-Host "1. Review: values-internal.yaml.final" -ForegroundColor White
Write-Host "2. If satisfied, replace original:" -ForegroundColor White
Write-Host "   Copy-Item values-internal.yaml.final values-internal.yaml -Force" -ForegroundColor Gray
Write-Host "3. Deploy with Helm:" -ForegroundColor White
Write-Host "   helm upgrade tazama . -n tazama -f values-internal.yaml" -ForegroundColor Gray
Write-Host "="*70 -ForegroundColor Cyan
