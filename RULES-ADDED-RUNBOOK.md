# Tazama Rules Update - Missing 11 Rules Added

**Date:** 2025-09-12  
**Action:** Added 11 missing rules to values-internal.yaml  
**Scripts:** Add-Missing-Rules.py, Add-Missing-Rules.ps1

---

## Summary

### Original Rule Count: 22 rules
- rule-001, rule-002, rule-003, rule-004
- rule-006, rule-007, rule-008
- rule-010, rule-011
- rule-016, rule-017, rule-018
- rule-020, rule-021
- rule-024, rule-025, rule-026, rule-027
- rule-028, rule-030

### Added Rules: 11 new rules
1. **rule-044** - Account velocity monitoring (riskWeight: 0.55)
2. **rule-045** - Geographic anomaly detection (riskWeight: 0.65)
3. **rule-048** - Round amount transaction detection (riskWeight: 0.6)
4. **rule-054** - Counterparty relationship analysis (riskWeight: 0.7)
5. **rule-063** - Transaction timing analysis (riskWeight: 0.5)
6. **rule-074** - Historical pattern deviation - creditor (riskWeight: 0.6)
7. **rule-075** - Historical pattern deviation - debtor (riskWeight: 0.6)
8. **rule-076** - Cross-border transaction monitoring (riskWeight: 0.75)
9. **rule-078** - Channel behavior analysis (riskWeight: 0.55)
10. **rule-083** - Network analysis - payment flows (riskWeight: 0.7)
11. **rule-084** - Aggregated threshold monitoring (riskWeight: 0.65)
12. **rule-090** - Time-based clustering analysis (riskWeight: 0.6)
13. **rule-091** - Peer group comparison (riskWeight: 0.65)

### Updated Rule Count: 33 rules (22 + 11)

---

## Files Modified

| File | Description | Status |
|------|-------------|--------|
| `values-internal.yaml` | Original file | Unchanged (backup) |
| `values-internal-updated.yaml` | Updated values with 33 rules | ✅ Created |
| `Add-Missing-Rules.py` | Python update script | ✅ Executed successfully |
| `Add-Missing-Rules.ps1` | PowerShell update script | Alternative method |

---

## Verification

### Rule Definitions Added (Lines 508-584)
```
✓ rule-044: Account velocity monitoring
✓ rule-045: Geographic anomaly detection
✓ rule-048: Round amount transaction detection
✓ rule-054: Counterparty relationship analysis
✓ rule-063: Transaction timing analysis
✓ rule-074: Historical pattern deviation - creditor
✓ rule-075: Historical pattern deviation - debtor
✓ rule-076: Cross-border transaction monitoring
✓ rule-078: Channel behavior analysis
✓ rule-083: Network analysis - payment flows
✓ rule-084: Aggregated threshold monitoring
✓ rule-090: Time-based clustering analysis
✓ rule-091: Peer group comparison
```

### Typology Rules List Updated (Lines 610-647)
All 33 rules now listed in `typologies.main.rules`

---

## Deployment Steps

### 1. Review the Updated File
```bash
# View the updated values
cat tazama/tazama-helm-derived/values-internal-updated.yaml

# Or on Windows:
type tazama\tazama-helm-derived\values-internal-updated.yaml
```

### 2. Backup and Replace
```bash
# Backup original
cp tazama/tazama-helm-derived/values-internal.yaml tazama/tazama-helm-derived/values-internal.yaml.bak

# Replace with updated version
cp tazama/tazama-helm-derived/values-internal-updated.yaml tazama/tazama-helm-derived/values-internal.yaml
```

### 3. Deploy to Kubernetes
```bash
# Upgrade Helm release
helm upgrade tazama ./tazama/tazama-helm-derived \
  -n tazama \
  -f tazama/tazama-helm-derived/values-internal.yaml

# Monitor rollout
kubectl rollout status deployment -n tazama -l app.kubernetes.io/component=rule

# Verify all rules are running
kubectl get pods -n tazama | grep rule-
```

### 4. Post-Deployment Verification
```bash
# Check all rule pods are running (should see 33)
kubectl get pods -n tazama | grep "rule-" | wc -l

# Check logs for any errors
kubectl logs -n tazama -l app.kubernetes.io/component=rule --tail=100

# Verify database schema still valid
kubectl exec -it postgres-0 -n tazama -- \
  psql -U postgres -d enrichment -c "\d network_map"
```

---

## Important Notes

### Image Requirements
The 11 new rule containers must be available from your configured registry:
- Default: `ghcr.io/frmscoe/rule-XXX:${TAZAMA_VERSION}`
- Alternative: `tazamaorg/rule-XXX:${TAZAMA_VERSION}`

If images are not available, pods will fail with `ImagePullBackOff`.

### Database Schema
The PostgreSQL schema in `tazama-deploy/postgres.yaml` already supports these rules. No schema changes needed.

### ConfigSeed
If you use `configSeed` for database initialization, you'll need to add `ruleConfigs` entries for the 11 new rules. See `values-internal-dbseed-rules.yaml` for reference.

---

## Troubleshooting

### If Pods Fail to Start
```bash
# Check image availability
kubectl describe pod <rule-pod> -n tazama | grep -A5 "Events:"

# Check if image exists
docker pull ghcr.io/frmscoe/rule-044:rc
```

### If Typology Fails to Process
```bash
# Verify typology configuration
kubectl get configmap tazama-core-config -n tazama -o yaml

# Check typology logs
kubectl logs -n tazama -l app=typology-01 --tail=200
```

---

## References

- Official Tazama Stack: https://github.com/frmscoe/tazama-stack
- Docker Hub: https://hub.docker.com/u/tazamaorg
- Helm Chart: tazama/tazama-helm-derived/

---

## Rollback

If needed, rollback to original values:
```bash
cp tazama/tazama-helm-derived/values-internal.yaml.bak tazama/tazama-helm-derived/values-internal.yaml

helm rollback tazama -n tazama
```
