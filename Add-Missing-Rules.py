#!/usr/bin/env python3
"""
Add-Missing-Rules.py
Inject 11 missing Tazama rules into values-internal.yaml
Run from: tazama/tazama-helm-derived directory
"""

import re
from pathlib import Path

values_file = Path("values-internal.yaml")

# Read the file
content = values_file.read_text(encoding='utf-8')

# Define the 11 missing rules
missing_rules = """
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
"""

print("=" * 70)
print("TAZAMA VALUES UPDATE - Adding 11 Missing Rules")
print("=" * 70)

# Step 1: Insert rule definitions after rule-030
print("\n[STEP 1] Adding rule definitions...")
pattern = r'(rule-030:.*?riskWeight: 0\.65)'
if re.search(pattern, content, re.DOTALL):
    content = re.sub(pattern, r'\1' + missing_rules, content, count=1, flags=re.DOTALL)
    print("[OK] Added 11 rule definitions")
else:
    print("[ERROR] Could not find insertion point (rule-030)")
    exit(1)

# Step 2: Update the main typology rules list
print("\n[STEP 2] Updating typology rules list...")

new_rules_list = """    rules:
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
      - rule-091"""

# Find and replace the main typology rules section
pattern = r'(typologies:\s+main:.*?rules:)(.*?)(\s+alertThreshold:)'
match = re.search(pattern, content, re.DOTALL)
if match:
    content = re.sub(pattern, r'\1\n' + new_rules_list + r'\n\3', content, flags=re.DOTALL)
    print("[OK] Updated main typology rules list (33 total rules)")
else:
    print("[ERROR] Could not find typology section")
    exit(1)

# Save to new file
output_file = Path("values-internal-updated.yaml")
output_file.write_text(content, encoding='utf-8')

print("\n" + "=" * 70)
print("[SUCCESS]")
print("=" * 70)
print(f"\nCreated: {output_file.absolute()}")
print("\nNEXT STEPS:")
print("1. Review the updated file:")
print(f"   type {output_file}")
print("\n2. If satisfied, replace original:")
print(f"   copy {output_file} {values_file}")
print("\n3. Deploy with Helm:")
print("   helm upgrade tazama . -n tazama -f values-internal-updated.yaml")
print("=" * 70)
